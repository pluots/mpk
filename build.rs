use std::env;
use std::fs::File;
// Need to rename PathBuf because of the `include!` macro
use std::path::{self, Path};

use clap::{Command, CommandFactory};
use clap_complete::generate_to;
use clap_complete::shells::Shell;

mod cli {
    include!("src/cli.rs");
}

fn build_shell_completion(cmd: &mut Command, outdir: &path::PathBuf) -> Result<(), std::io::Error> {
    // Generate shell completion scripts for our
    for shell in [
        Shell::Bash,
        Shell::Elvish,
        Shell::Fish,
        Shell::PowerShell,
        Shell::Zsh,
    ] {
        // We specify our generator, binary name, and output directory
        let path = generate_to(shell, cmd, "mpk", outdir)?;

        println!("cargo:warning=completion file written to {path:?}");
    }

    Ok(())
}

fn build_man_pages(cmd: Command, outdir: &Path) -> Result<(), std::io::Error> {
    // Generate man pages
    let man = clap_mangen::Man::new(cmd);
    let mut buffer: Vec<u8> = Default::default();

    man.render(&mut buffer)?;

    let manpage_out = outdir.join("mpk.1");

    println!("cargo:warning=manpage written to {manpage_out:?}");

    std::fs::write(manpage_out, buffer)?;

    Ok(())
}

fn main() -> Result<(), std::io::Error> {
    // Output directory will be a cargo-generated random directory
    let outdir = match env::var_os("OUT_DIR") {
        Some(outdir) => std::path::PathBuf::from(outdir),
        None => return Ok(()),
    };

    let profile = std::env::var("PROFILE").unwrap();
    let make_dist = std::env::var("MAKE_DIST").map_or(false, |v| v == "1");

    // Don't generate outputs if we're in debug mode
    if make_dist || profile.as_str() != "debug" {
        // Create a dummy file to help find the latest output
        let stamp_path = Path::new(&outdir).join("mpk-stamp");
        if let Err(err) = File::create(&stamp_path) {
            panic!("failed to write {}: {}", stamp_path.display(), err);
        }

        println!("cargo:warning=stamp written to {stamp_path:?}");

        let mut cmd = cli::Args::command();

        build_shell_completion(&mut cmd, &outdir)?;
        build_man_pages(cmd, &outdir)?;
    }

    Ok(())
}
