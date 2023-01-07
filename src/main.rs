use clap::Parser;
use std::fmt;
use std::fs;
use std::io;
use std::io::{Read, Write};
use std::process::ExitCode;
use std::sync::atomic::{AtomicBool, Ordering};

/// Store our verbosity level
static VERBOSITY: AtomicBool = AtomicBool::new(false);

/// Print to stderr if verbose mode is on
macro_rules! printvb {
    ($tt:tt) => {{
        if VERBOSITY.load(Ordering::Relaxed) {
            eprint!("[info]: ");
            eprintln!($tt);
        }
    }};
}

// Define CLI arguments
/// Command line utility to convert between MessagePack and JSON
///
/// If not specified, type will be inferred from input file arguments
#[derive(Parser, Debug)]
#[command(version, about)]
struct Args {
    /// Specify the input file to read from. If not given, stdin will be used
    input_file: Option<String>,

    /// Specify the output file to write. If not specified, stdout will be used
    #[arg(short, long = "output")]
    output_file: Option<String>,

    /// Specify input via text. (can't use with 'INPUT_FILE')
    #[arg(short, long)]
    text: Option<String>,

    /// Convert from MessagePack to JSON. (can't use with '--to-json')
    #[arg(short = 'j', long)]
    to_json: bool,

    /// Convert from JSON to MessagePack. (can't use with '--to-msgpack')
    #[arg(short = 'm', long)]
    to_msgpack: bool,

    /// Use messagepack with hexadecimal strings instead of binary
    #[arg(long)]
    hex: bool,
    
    /// Turn verbose mode on
    #[arg(short, long)]
    verbose: bool,

}

/// Representation of our exit codes
#[repr(u8)]
#[derive(Debug)]
#[allow(dead_code)]
enum Error {
    ArgConflict(String, String),
    NoDirection,
    NoInput,
    Hex(hex::FromHexError),
    // The string holds, the file name, io error is the error
    File(String, io::Error),
    Io(io::Error),
    MessagePak(rmp_serde::encode::Error),
    Json(serde_json::Error),
    // Generic error
    Other(String),
}

impl fmt::Display for Error {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Error::ArgConflict(a1, a2) => write!(
                f, "Both {a1} and {a2} given, but only one is allowed at a time"
            ),
            Error::NoDirection => write!(
                f,
                "Could not determine conversion direction. Specify '--to-json' or '--to-msgpack'."
            ),
            Error::MessagePak(e) => write!(f, "Unable to parse MessagePack input, {e}"),
            Error::Json(e) => write!(f, "Unable to parse JSON input, {e}"),
            Error::Hex(e) => write!(f, "Invalid hex: {e}"),
            Error::NoInput => write!(f, "No input is present"),
            Error::File(n, e) => write!(f, "Error reading '{n}': {e}"),
            Error::Io(e) => write!(f, "IO error: {e}"),
            Error::Other(e) => write!(f, "{e}"),
        }
    }
}

/// Allow converting an Error to a ExitCode type
impl From<Error> for ExitCode {
    fn from(value: Error) -> Self {
        let tmp: u8 = match value {
            // Arg errors < 20
            Error::ArgConflict(_, _) => 4,
            Error::NoDirection => 6,
            // Parse/IO errors > 20
            Error::NoInput => 20,
            Error::Io(_) => 30,
            Error::File(_, _) => 31,
            Error::MessagePak(_) => 40,
            Error::Json(_) => 41,
            Error::Hex(_) => 42,
            Error::Other(_) => 90,
        };
        ExitCode::from(tmp)
    }
}

enum FType {
    Json,
    MessagePack,
    None,
}

/// Returns whether a file name ends with a messagepack extension or a JSON
/// extension (in that order)
fn get_fname_maps<S: AsRef<str>>(fname: S) -> FType {
    let fname = fname.as_ref();
    if fname.ends_with(".json") {
        FType::Json
    } else if fname.ends_with(".msgpack") || fname.ends_with(".mpk") {
        FType::MessagePack
    } else {
        FType::None
    }
}

impl Args {
    /// Validate there are no redundant arguments. If so, print a message and return a code
    /// to exit.
    ///
    /// Also set to_json/to_msgpack based on file names if needed
    fn validate_update(&mut self) -> Result<(), Error> {
        VERBOSITY.store(self.verbose, Ordering::Relaxed);

        if self.to_json && self.to_msgpack {
            return Err(Error::ArgConflict("--to-json".to_owned(), "--to-msgpack".to_owned()));
        }

        if self.input_file.is_some() && self.text.is_some() {
            return Err(Error::ArgConflict("INPUT_FILE".to_owned(), "--text".to_owned()));
        }

        // Attempt to infer the input and output types
        if !self.to_json && !self.to_msgpack {
            let in_ty: FType = self.input_file.as_ref().map_or(FType::None, get_fname_maps);
            let out_ty: FType = self
                .output_file
                .as_ref()
                .map_or(FType::None, get_fname_maps);
            let output_mp = matches!(in_ty, FType::Json) || matches!(out_ty, FType::MessagePack);
            let output_json = matches!(in_ty, FType::MessagePack) || matches!(out_ty, FType::Json);

            if output_mp {
                printvb!("inferring output type to be messagepack based on extension");
                self.to_msgpack = true
            } else if output_json {
                printvb!("inferring output type to be json based on extension");
                self.to_json = true
            } else {
                printvb!("file extensions not provided or do not match known types");
                return Err(Error::NoDirection);
            }
        }

        Ok(())
    }

    /// Get input from stdin or a file, as a string
    fn get_input<'a>(&'a self) -> Result<Box<dyn Read + 'a>, Error> {
        if let Some(fname) = self.input_file.as_ref() {
            printvb!("attempting to set input from file");
            let file = fs::File::open(fname).map_err(|e| Error::File(fname.to_owned(), e))?;
            Ok(Box::new(file))
        } else if let Some(txt) = self.text.as_ref() {
            Ok(Box::new(io::Cursor::new(txt)))
        } else {
            printvb!("getting input from stdin");
            Ok(Box::new(io::stdin()))
        }
    }

    /// Get the output location
    fn get_output(&self) -> Result<Box<dyn Write>, Error> {
        if let Some(fname) = self.output_file.as_ref() {
            printvb!("attempting to set output from file");

            let file = fs::File::create(fname).map_err(|e| Error::File(fname.to_owned(), e))?;
            Ok(Box::new(file))
        } else {
            printvb!("setting output to sdtout");

            Ok(Box::new(io::stdout()))
        }
    }
}

fn main_runner() -> Result<(), Error> {
    let mut args = Args::parse();

    // Validate arguments, return an error if applicable
    args.validate_update()?;
    let mut input = args.get_input()?;
    let output = args.get_output()?;

    if args.to_json {
        printvb!("transcoding from MessagePack to JSON");

        let mut inbuf = String::new();
        input.read_to_string(&mut inbuf).map_err(Error::Io)?;

        let hex_buf: Vec<u8>;

        // If we are requested to decode the hex input, do so
        let bytes_buf = if args.hex {
            printvb!("decoding hex string input");
            inbuf.retain(|c| !c.is_ascii_whitespace());
            hex_buf = hex::decode(inbuf).map_err(Error::Hex)?; 
            &hex_buf
        } else {
            inbuf.as_bytes()
        };

        let mut deserializer = rmp_serde::Deserializer::new(bytes_buf);
        let mut serializer = serde_json::Serializer::new(output);
        serde_transcode::transcode(&mut deserializer, &mut serializer).map_err(Error::Json)?;
    } else {
        printvb!("transcoding from JSON to MessagePack");

        let mut deserializer = serde_json::Deserializer::from_reader(input);
        let mut serializer = rmp_serde::Serializer::new(output);
        serde_transcode::transcode(&mut deserializer, &mut serializer)
            .map_err(Error::MessagePak)?;
    }

    Ok(())
}

fn main() -> ExitCode {
    let res = main_runner();

    if let Err(e) = res {
        eprintln!("{e}");
        eprintln!("Command failed, exiting");
        e.into()
    } else {
        ExitCode::SUCCESS
    }
}
