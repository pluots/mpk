use std::io::{Read, Write};
use std::process::Command;
use std::str;

use assert_cmd::prelude::*;
use predicates::str as pred_str;
use tempfile::NamedTempFile;

const JSON: &str =
    r#"{"name":"messagepack","age":20,"source":"github","arr":[1,2,"buckle my shoe"]}"#;
const BYTES: [u8; 59] = [
    0x84, 0xa4, 0x6e, 0x61, 0x6d, 0x65, 0xab, 0x6d, 0x65, 0x73, 0x73, 0x61, 0x67, 0x65, 0x70, 0x61,
    0x63, 0x6b, 0xa3, 0x61, 0x67, 0x65, 0x14, 0xa6, 0x73, 0x6f, 0x75, 0x72, 0x63, 0x65, 0xa6, 0x67,
    0x69, 0x74, 0x68, 0x75, 0x62, 0xa3, 0x61, 0x72, 0x72, 0x93, 0x01, 0x02, 0xae, 0x62, 0x75, 0x63,
    0x6b, 0x6c, 0x65, 0x20, 0x6d, 0x79, 0x20, 0x73, 0x68, 0x6f, 0x65,
];

#[test]
fn test_tofrom_file() {
    let mut infile = NamedTempFile::new().unwrap();
    let mut outfile = NamedTempFile::new().unwrap();
    infile.write_all(JSON.as_bytes()).unwrap();

    let mut cmd = Command::cargo_bin("msgpack").unwrap();

    cmd.arg(infile.path())
        .arg("--output")
        .arg(outfile.path())
        .arg("--to-msgpack");
    cmd.assert().success().stdout("");

    let mut outbuf = Vec::new();
    outfile.read_to_end(&mut outbuf).unwrap();
    assert_eq!(outbuf, Vec::from_iter(BYTES.iter().copied()));
}

#[test]
fn test_tofrom_stream() {
    // Try both directions
    let mut cmd = assert_cmd::Command::cargo_bin("msgpack").unwrap();
    cmd.arg("--to-msgpack").write_stdin(JSON);
    cmd.assert().success().stdout(BYTES.as_slice());

    let mut cmd = assert_cmd::Command::cargo_bin("msgpack").unwrap();
    cmd.arg("--to-json").write_stdin(BYTES);
    // We end with a newline so need to use contains
    cmd.assert().success().stdout(pred_str::contains(JSON));
}

#[test]
fn test_text_input() {
    // Just test everything else without trying much
    let mut cmd = assert_cmd::Command::cargo_bin("msgpack").unwrap();
    cmd.arg("--to-msgpack").arg("--input").arg(JSON);
    cmd.assert().success().stdout(BYTES.as_slice());

    let mut buf = Vec::new();
    for byte in BYTES {
        write!(&mut buf, "{byte:02x}").unwrap();
    }
    let hex_str = str::from_utf8(&buf).unwrap();

    let mut cmd = assert_cmd::Command::cargo_bin("msgpack").unwrap();
    cmd.arg("--to-json").arg("--input").arg(hex_str);
    cmd.assert().success().stdout(pred_str::contains(JSON));

    let mut cmd = assert_cmd::Command::cargo_bin("msgpack").unwrap();
    cmd.arg("--to-msgpack")
        .arg("--input")
        .arg(JSON)
        .arg("--hex");
    cmd.assert().success().stdout(pred_str::contains(hex_str));
}
