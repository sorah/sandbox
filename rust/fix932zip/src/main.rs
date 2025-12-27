use std::fs::File;
use std::path::PathBuf;

use clap::Parser;
use zip::read::ZipArchive;
use zip::write::ZipWriter;

#[derive(Parser)]
#[command(about = "Convert ZIP file names from CP932 to UTF-8")]
struct Args {
    /// Source ZIP file with CP932-encoded file names
    source: PathBuf,

    /// Destination ZIP file with UTF-8 file names
    dest: PathBuf,

    /// Show all file names being converted
    #[arg(short, long)]
    verbose: bool,
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args = Args::parse();

    let source_file = File::open(&args.source)?;
    let mut archive = ZipArchive::new(source_file)?;

    let dest_file = File::create(&args.dest)?;
    let mut writer = ZipWriter::new(dest_file);

    for i in 0..archive.len() {
        let file = archive.by_index_raw(i)?;
        let name_raw = file.name_raw().to_vec();

        let (decoded_name, _, had_errors) = encoding_rs::SHIFT_JIS.decode(&name_raw);

        if had_errors {
            eprintln!(
                "Warning: encoding error in entry {}: {:?}",
                i,
                String::from_utf8_lossy(&name_raw)
            );
        }

        if args.verbose {
            println!("{}", decoded_name);
        }

        writer.raw_copy_file_rename(file, decoded_name.as_ref())?;
    }

    writer.finish()?;

    Ok(())
}
