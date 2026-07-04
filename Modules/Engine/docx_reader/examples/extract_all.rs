/// Extract everything from a DOCX and dump as JSON.
///
/// Run with:
///   cargo run --example extract_all -- path/to/document.docx [output.json]
use docx_reader::DocxReader;
use std::path::Path;

fn main() {
    let mut args = std::env::args().skip(1);
    let path = args.next().expect("usage: extract_all <file.docx> [output.json]");
    let out_path = args.next();

    let reader = DocxReader::open(&path).expect("failed to open file");

    // ── Full JSON dump ────────────────────────────────────────────────────────
    let json = reader.to_json().expect("serialisation failed");
    match &out_path {
        Some(p) => {
            std::fs::write(p, &json).expect("failed to write JSON");
            println!("Written {} bytes of JSON to {}", json.len(), p);
        }
        None => {
            // Print first 2 000 chars
            let preview: String = json.chars().take(2000).collect();
            println!("{}", preview);
            if json.len() > 2000 { println!("… (truncated)"); }
        }
    }

    // ── Save all images to current dir ────────────────────────────────────────
    let images = reader.images().expect("failed to list images");
    println!("\nSaving {} image(s)…", images.len());
    for img in &images {
        let filename = format!("{}_{}.{}", &path, img.rel_id, img.extension());
        match reader.save_image(&img.rel_id, &filename) {
            Ok(()) => println!("  Saved: {}", filename),
            Err(e) => eprintln!("  Could not save {}: {}", img.rel_id, e),
        }
    }

    // ── Extract text with all options enabled ─────────────────────────────────
    use docx_reader::TextOptions;
    let opts = TextOptions::all();
    let full_text = reader.extract_text_with_options(&opts).expect("failed to extract");
    println!("\nFull text length: {} chars", full_text.len());
}
