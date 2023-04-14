# Changelog

<!-- next-header -->

## [Unreleased] - ReleaseDate

- Rename binary from `msgpack` to `mpk` at suggestion of the protocol's creator.
  Name on Crates.io will rename `msgpack-cli`. Repository URL updated to
  <https://github.com/pluots/mpk>.

## [0.1.4] - 2023-01-08

- Change dpkg compression from zstd to xz so we can install on Debian

## [0.1.3] - 2023-01-08

- Correct makefile autocompletions install targets
- Added `.deb` output

## [0.1.2] - 2023-01-08

- Added `aarch64-unknown-linux-gnu`, `aarch64-apple-darwin`, and
  `x86_64-pc-windows-gnu` targets


## [0.1.1] - 2023-01-07

- Added pretty printing for hex and JSON output
- CLI now defaults to hex input when specifying `-i -j`
- Added makefile for easier installing
- [test] added integration tests


## [0.1.0] - 2023-01-07

Initial release supporting:

- Bidirectional JSON <-> MessagePack conversions
- File input and output
- `stdin` input and `stdout` output
- Hex string input and output


<!-- next-url -->
[Unreleased]: https://github.com/pluots/mpk/compare/v0.1.4...HEAD
[0.1.4]: https://github.com/pluots/mpk/compare/v0.1.3...v0.1.4
[0.1.3]: https://github.com/pluots/mpk/compare/v0.1.2...v0.1.3
[0.1.2]: https://github.com/pluots/mpk/compare/v0.1.1...v0.1.2
[0.1.1]: https://github.com/pluots/mpk/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/pluots/mpk/compare/3fb7ec2a...v0.1.0
