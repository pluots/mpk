# MessagePack CLI

This is an experimental CLI for converting between MessagePack and JSON.

## Usage

```
  -i, --input-file <INPUT_FILE>    Specify the input file to read from. If not specified, stdin will be used
  -o, --output-file <OUTPUT_FILE>  Specify the output file to write. If not specified, stdout will be used
  -t, --text <TEXT>                Specify input via text
  -j, --to-json                    Convert from MessagePack to JSON
  -m, --to-msgpack                 Convert from JSON to MessagePack
  -v, --verbose                    Turn verbose mode on
  -h, --help                       Print help information (use `--help` for more detail)
  -V, --version                    Print version information
```

Examples:

```bash

# Use 
msgpack --hex -t "82 a7 63 6f 6d 70 61 63 74 c3 a6 73 63 68 65 6d 61 00" --to-json

```
