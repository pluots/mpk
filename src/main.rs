use clap::Parser;
use std::fmt;
use std::fs;
use std::io;
use std::io::{Read, Write};
use std::process::ExitCode;
use std::sync::atomic::{AtomicBool, Ordering};
use serde_json::Value;

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
    /// Specify the input file to read from. If not specified, stdin will be used
    #[arg(short, long)]
    input_file: Option<String>,

    /// Specify the output file to write. If not specified, stdout will be used
    #[arg(short, long)]
    output_file: Option<String>,

    /// Specify input via text
    #[arg(short, long)]
    text: Option<String>,

    /// Convert from MessagePack to JSON
    #[arg(short = 'j', long)]
    to_json: bool,

    /// Convert from JSON to MessagePack
    #[arg(short = 'm', long)]
    to_msgpack: bool,

    /// Turn verbose mode on
    #[arg(short, long)]
    verbose: bool,
}

/// Representation of our exit codes
#[repr(u8)]
#[derive(Debug)]
#[allow(dead_code)]
enum Error {
    DuplicateArgument,
    NoDirection,
    InputParse,
    NoInput,
    // The string holds, the file name, io error is the error
    IoError(String, io::Error),
    // Generic error
    Other(String),
}

impl fmt::Display for Error {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Error::DuplicateArgument => write!(
                f,
                "Both '--to-json' and '--to-msgpack' specified, \
                but only one is allowed at a time"
            ),
            Error::NoDirection => write!(
                f,
                "Could not determine conversion direction. \
                Specify '--to-json' or '--to-msgpack'."
            ),
            Error::InputParse => write!(f, "Unable to parse input"),
            Error::NoInput => write!(f, "No input is present"),
            Error::IoError(n, e) => write!(f, "Error reading '{n}': {e}"),
            Error::Other(e) => write!(f, "{e}"),
        }
    }
}

/// Allow converting an Error to a ExitCode type
impl From<Error> for ExitCode {
    fn from(value: Error) -> Self {
        let tmp: u8 = match value {
            // Arg errors < 20
            Error::DuplicateArgument => 4,
            Error::NoDirection => 5,
            // Parse/IO errors > 20
            Error::NoInput => 20,
            Error::IoError(_, _) => 40,
            Error::InputParse => 50,
            Error::Other(_) => 90,
        };
        ExitCode::from(tmp)
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
            return Err(Error::DuplicateArgument);
        }

        // Attempt to infer the input and output types
        if !self.to_json && !self.to_msgpack {
            if self
                .input_file
                .as_ref()
                .map_or(false, |fname| fname.ends_with(".json"))
                || self.output_file.as_ref().map_or(false, |fname| {
                    fname.ends_with(".msgpack") || fname.ends_with(".mpk")
                })
            {
                printvb!("inferring output type to be messagepack based on extension");
                self.to_msgpack = true
            } else if self.input_file.as_ref().map_or(false, |fname| {
                fname.ends_with(".msgpack") || fname.ends_with(".mpk")
            }) || self
                .output_file
                .as_ref()
                .map_or(false, |fname| fname.ends_with(".json"))
            {
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
    fn get_input(&self) -> Result<String, Error> {
        if let Some(file) = self.input_file.as_ref() {
            printvb!("attempting to load input from file");
            fs::read_to_string(file).map_err(|e| Error::IoError(file.to_owned(), e))
        } else {
            printvb!("attempting to load input from stdin");
            let mut buf = String::new();
            io::stdin().read_to_string(&mut buf).unwrap();
            Ok(buf)
        }
    }

    /// Get the output location
    fn write_output<T: AsRef<[u8]>>(&self, output: T) {
        todo!()
    }
}

fn main_runner() -> Result<(), Error> {
    let mut args = Args::parse();

    // Validate arguments, return an error if applicable
    args.validate_update()?;
    let input = args.get_input()?;

    // let value: rmpv::Value = rmp_serde::from_slice(bytes)?
    // fixme: error
    let v: Value = serde_json::from_str(&input).unwrap();
    let out =  rmp_serde::to_vec(&v).unwrap();
    dbg!(&v); 
    dbg!(&out);
    io::stdout().write(&out).unwrap();

    Ok(())
}

fn main() -> ExitCode {
    let res = main_runner();

    if let Err(e) = res {
        eprintln!("{e}");
        eprintln!("Conversion failed, exiting");
        e.into()
    } else {
        ExitCode::SUCCESS
    }
}
