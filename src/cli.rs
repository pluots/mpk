// This module contains the CLI arg parser. It needs to be in a separate
// file so clap_mangen and clap_complete can use it
use clap::Parser;

// Define CLI arguments
/// Command line utility to convert between `MessagePack` and JSON
///
/// If not specified, type will be inferred from input file arguments
#[derive(Parser, Debug)]
#[command(version, about)]
#[allow(clippy::struct_excessive_bools)]
pub struct Args {
    /// Specify the input file to read from. If not given, stdin will be used
    pub input_file: Option<String>,

    /// Specify the output file to write. If not specified, stdout will be used
    #[arg(short, long = "output")]
    pub output_file: Option<String>,

    /// Specify input via text. (can't use with 'INPUT_FILE')
    #[arg(short, long)]
    pub input: Option<String>,

    /// Convert from MessagePack to JSON. (can't use with '--to-json')
    #[arg(short = 'j', long)]
    pub to_json: bool,

    /// Convert from JSON to MessagePack. (can't use with '--to-msgpack')
    #[arg(short = 'm', long)]
    pub to_msgpack: bool,

    /// Use messagepack with hexadecimal strings instead of binary. Implied with '-i <input> -j'
    #[arg(long)]
    pub hex: bool,

    /// Enable pretty output (formatted JSON, spacing for MessagePack when used with `--hex`)
    #[arg(short, long)]
    pub pretty: bool,

    /// Turn verbose mode on
    #[arg(short, long)]
    pub verbose: bool,
}
