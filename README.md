# MessagePack CLI

This is a simple CLI for converting between MessagePack and JSON. Jump to
[Installing](#installing) for installation instructions.

```sh
$ # Basic usage: convert a file either direction
$ msgpack in.json -o out.msgpack
$ msgpack out.msgpack
{"name":"messagepack","age":20,"source":"github"}

$ # Pretty formatting
$ msgpack out.msgpack --pretty
{
  "name": "messagepack",
  "age": 20,
  "source": "github"
}

$ # Use stdin input and stdout output. You need to specify the destination type with
$ # `--to-msgpack` or `--to-json` (`-m` or `-j`)
$ cat in.json | msgpack --to-msgpack | xxd
00000000: 83a4 6e61 6d65 ab6d 6573 7361 6765 7061  ..name.messagepa
00000010: 636b a361 6765 14a6 736f 7572 6365 a667  ck.age..source.g
00000020: 6974 6875 62                             ithub

$ # Use a hex string as input or output
$ msgpack --hex -i "82 a7 63 6f 6d 70 61 63 74 c3 a6 73 63 68 65 6d 61 00" --to-json
{"compact":true,"schema":0}
$ msgpack --hex -i '{"compact":true,"schema":0}' --to-msgpack
82a7636f6d70616374c3a6736368656d6100

$ # And with pretty print:
$ msgpack in.json --hex --pretty
83a4 6e61 6d65 ab6d 6573 7361 6765 7061
636b a361 6765 14a6 736f 7572 6365 a667
6974 6875 62
```

## Installing

The easiest way to install is to go the [releases] page and download a version.
Alternatively, you can install with Cargo via `cargo install msgpack-cli`, or
build the source yourself with `cargo build --release`.

In either of these cases, you will want to make sure that the executables are in
the right path. You can use the provided makefile with `make install` to set
this up automatically, copy the binary to your preferred location (the manpage
and autocomplete scripts are also included).

[releases]: https://github.com/pluots/msgpack-cli/releases

## Usage

See above for usage examples. The command line options are as follows:

```
Usage: msgpack [OPTIONS] [INPUT_FILE]

Arguments:
  [INPUT_FILE]  Specify the input file to read from. If not given, stdin will be used

Options:
  -o, --output <OUTPUT_FILE>  Specify the output file to write. If not specified, stdout will be used
  -i, --input <INPUT>         Specify input via text. (can't use with 'INPUT_FILE')
  -j, --to-json               Convert from MessagePack to JSON. (can't use with '--to-json')
  -m, --to-msgpack            Convert from JSON to MessagePack. (can't use with '--to-msgpack')
      --hex                   Use messagepack with hexadecimal strings instead of binary
  -p, --pretty                Enable pretty output (formatted JSON, spacing for MessagePack when
                              used with `--hex`)
  -v, --verbose               Turn verbose mode on
  -h, --help                  Print help information (use `--help` for more detail)
  -V, --version               Print version information
```
