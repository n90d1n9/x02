//! rustpdf CLI — demonstrates every major API in v0.2
//!
//! Usage:
//!   cargo run --example cli -- <file.pdf> [command] [args...]
//!
//! Commands:
//!   info                    Print metadata summary
//!   text [page]             Extract plain text (all pages, or single page index)
//!   rich [page]             Extract rich text spans with style info
//!   search <query>          Full-text search
//!   regex <pattern>         Regex search
//!   images [--decode]       List embedded images; --decode writes PNG/JPEG files
//!   annotations             List all annotations
//!   tables                  Detect and print tables
//!   bookmarks               Print bookmark tree
//!   fields                  List form fields
//!   export <fmt> [out]      Export: json|md|html|txt|csv (optional output path)
//!   watermark <text>        Stamp watermark on all pages → output.pdf
//!   inject <page> <x> <y> <text>  Inject text at position → output.pdf
//!   rotate <page> <deg>     Rotate page 90/180/270 → output.pdf
//!   remove <page>           Remove page → output.pdf
//!   merge <other.pdf>       Merge another PDF → output.pdf
//!   split <from> <to>       Extract page range → output.pdf
//!   annotate <page> <note>  Add sticky-note annotation → output.pdf
//!   diff <other.pdf>        Diff text with another PDF
//!   update-meta [--title T] [--author A] [--subject S]  → output.pdf

use rustpdf::{ExportFormat, PdfDocument};
use std::{env, path::PathBuf};

fn main() {
    let args: Vec<String> = env::args().collect();
    if args.len() < 3 {
        print_usage(&args[0]);
        std::process::exit(0);
    }

    let path = &args[1];
    let cmd = args[2].as_str();

    let mut doc = match PdfDocument::open(path) {
        Ok(d) => d,
        Err(e) => {
            eprintln!("Error opening {path}: {e}");
            std::process::exit(1);
        }
    };

    match cmd {
        "info" => cmd_info(&doc),
        "text" => {
            let page = args.get(3).and_then(|s| s.parse::<usize>().ok());
            cmd_text(&doc, page);
        }
        "rich" => {
            let page = args.get(3).and_then(|s| s.parse::<usize>().ok());
            cmd_rich(&doc, page);
        }
        "search" => {
            let q = args.get(3).map(|s| s.as_str()).unwrap_or("");
            cmd_search(&doc, q, false);
        }
        "regex" => {
            let q = args.get(3).map(|s| s.as_str()).unwrap_or("");
            cmd_search(&doc, q, true);
        }
        "images" => {
            let decode = args.get(3).map(|s| s == "--decode").unwrap_or(false);
            cmd_images(&doc, decode, path);
        }
        "annotations" => cmd_annotations(&doc),
        "tables" => cmd_tables(&doc),
        "bookmarks" => cmd_bookmarks(&doc),
        "fields" => cmd_fields(&doc),
        "export" => {
            let fmt_str = args.get(3).map(|s| s.as_str()).unwrap_or("txt");
            let out = args.get(4).cloned();
            cmd_export(&doc, fmt_str, out);
        }
        "watermark" => {
            let text = args.get(3).map(|s| s.as_str()).unwrap_or("DRAFT");
            doc.watermark_text(text, None, None)
                .expect("watermark failed");
            save_output(&mut doc, "output.pdf");
        }
        "inject" => {
            let page = args
                .get(3)
                .and_then(|s| s.parse::<usize>().ok())
                .unwrap_or(0);
            let x = args
                .get(4)
                .and_then(|s| s.parse::<f64>().ok())
                .unwrap_or(50.0);
            let y = args
                .get(5)
                .and_then(|s| s.parse::<f64>().ok())
                .unwrap_or(400.0);
            let text = args.get(6).map(|s| s.as_str()).unwrap_or("Injected");
            doc.inject_text(page, text, x, y, 12.0)
                .expect("inject failed");
            save_output(&mut doc, "output.pdf");
        }
        "rotate" => {
            let page = args
                .get(3)
                .and_then(|s| s.parse::<usize>().ok())
                .unwrap_or(0);
            let deg = args
                .get(4)
                .and_then(|s| s.parse::<i64>().ok())
                .unwrap_or(90);
            doc.rotate_page(page, deg).expect("rotate failed");
            save_output(&mut doc, "output.pdf");
        }
        "remove" => {
            let page = args
                .get(3)
                .and_then(|s| s.parse::<usize>().ok())
                .unwrap_or(0);
            doc.remove_page(page).expect("remove failed");
            save_output(&mut doc, "output.pdf");
        }
        "merge" => {
            let other_path = args.get(3).expect("provide path to other PDF");
            let other = PdfDocument::open(other_path).expect("could not open other PDF");
            doc.merge(&other).expect("merge failed");
            save_output(&mut doc, "output.pdf");
        }
        "split" => {
            let from = args
                .get(3)
                .and_then(|s| s.parse::<usize>().ok())
                .unwrap_or(0);
            let to = args
                .get(4)
                .and_then(|s| s.parse::<usize>().ok())
                .unwrap_or(doc.page_count().saturating_sub(1));
            let mut sub = doc.extract_document_range(from, to).expect("split failed");
            save_output(&mut sub, "output.pdf");
        }
        "annotate" => {
            let page = args
                .get(3)
                .and_then(|s| s.parse::<usize>().ok())
                .unwrap_or(0);
            let note = args.get(4).map(|s| s.as_str()).unwrap_or("Note");
            doc.add_text_annotation(page, [50.0, 700.0, 200.0, 750.0], "CLI", note)
                .expect("annotate failed");
            save_output(&mut doc, "output.pdf");
        }
        "diff" => {
            let other_path = args.get(3).expect("provide path to other PDF");
            let other = PdfDocument::open(other_path).expect("could not open other PDF");
            cmd_diff(&doc, &other);
        }
        "update-meta" => {
            let title = flag_value(&args, "--title");
            let author = flag_value(&args, "--author");
            let subject = flag_value(&args, "--subject");
            doc.update_metadata(
                title.as_deref(),
                author.as_deref(),
                subject.as_deref(),
                None,
                None,
            )
            .expect("update-meta failed");
            save_output(&mut doc, "output.pdf");
        }
        other => {
            eprintln!("Unknown command: {other}");
            print_usage(&args[0]);
            std::process::exit(1);
        }
    }
}

// ─── command implementations ──────────────────────────────────────────────────

fn cmd_info(doc: &PdfDocument) {
    let meta = doc.metadata().expect("metadata failed");
    println!("═══ Document Info ═══════════════════════");
    println!("  Title    : {}", opt(&meta.title));
    println!("  Author   : {}", opt(&meta.author));
    println!("  Subject  : {}", opt(&meta.subject));
    println!("  Keywords : {}", opt(&meta.keywords));
    println!("  Creator  : {}", opt(&meta.creator));
    println!("  Producer : {}", opt(&meta.producer));
    println!("  Created  : {}", opt(&meta.creation_date));
    println!("  Modified : {}", opt(&meta.modification_date));
    println!("  Version  : {}", meta.pdf_version);
    println!("  Pages    : {}", meta.page_count);
    println!("  Encrypted: {}", meta.is_encrypted);
    if let Some([w, h]) = meta.page_size {
        println!(
            "  Page size: {w:.0} × {h:.0} pt  ({:.1}\" × {:.1}\")",
            w / 72.0,
            h / 72.0
        );
    }
    if !meta.custom_properties.is_empty() {
        println!("  Custom   :");
        for (k, v) in &meta.custom_properties {
            println!("    {k}: {v}");
        }
    }
}

fn cmd_text(doc: &PdfDocument, page: Option<usize>) {
    match page {
        Some(idx) => {
            let text = doc.extract_page_text(idx).expect("text extraction failed");
            println!("── Page {} ──────────────────────────────", idx + 1);
            println!("{text}");
        }
        None => {
            let pages = doc.extract_pages().expect("extraction failed");
            for p in &pages {
                println!(
                    "── Page {} ({} words, {} chars) ──",
                    p.page_number, p.word_count, p.char_count
                );
                println!("{}", p.text);
                println!();
            }
        }
    }
}

fn cmd_rich(doc: &PdfDocument, page: Option<usize>) {
    let spans = match page {
        Some(idx) => doc.extract_rich_text_page(idx).expect("rich text failed"),
        None => doc.extract_rich_text().expect("rich text failed"),
    };
    if spans.is_empty() {
        println!("(no styled spans found)");
        return;
    }
    println!(
        "{:>4}  {:>6}  {:5}  {:5}  {:12}  {}",
        "page", "size", "bold", "ital", "font", "text"
    );
    println!("{}", "─".repeat(72));
    for s in &spans {
        println!(
            "  p.{:<3}  {:>5.1}  {:5}  {:5}  {:12}  {}",
            s.page_index + 1,
            s.font_size,
            if s.bold { "bold" } else { "" },
            if s.italic { "ital" } else { "" },
            s.base_font
                .as_deref()
                .unwrap_or(&s.font_name)
                .chars()
                .take(12)
                .collect::<String>(),
            s.text.chars().take(60).collect::<String>()
        );
    }
}

fn cmd_search(doc: &PdfDocument, query: &str, is_regex: bool) {
    if query.is_empty() {
        eprintln!("Provide a search query.");
        return;
    }
    let hits = if is_regex {
        doc.search_regex(query).expect("regex search failed")
    } else {
        doc.search(query).expect("search failed")
    };
    if hits.is_empty() {
        println!("No matches for: {query}");
        return;
    }
    println!("Found {} match(es) for: {query}", hits.len());
    println!("{}", "─".repeat(60));
    for h in &hits {
        println!(
            "  p.{} offset {:4}  │  …{}…",
            h.page_number,
            h.char_offset,
            h.context.chars().take(70).collect::<String>()
        );
    }
}

fn cmd_images(doc: &PdfDocument, decode: bool, src_path: &str) {
    if decode {
        let decoded = doc.decode_images().expect("image decode failed");
        if decoded.is_empty() {
            println!("No images found.");
            return;
        }
        println!("Decoded {} image(s):", decoded.len());
        let stem = PathBuf::from(src_path)
            .file_stem()
            .and_then(|s| s.to_str())
            .unwrap_or("pdf")
            .to_owned();
        for img in &decoded {
            let ext = if img.mime_type == "image/jpeg" {
                "jpg"
            } else {
                "png"
            };
            let name = format!("{stem}_img_{}.{ext}", img.info.image_index);
            std::fs::write(&name, &img.encoded_bytes).expect("write failed");
            println!(
                "  Wrote {name}  ({}×{:?} {})",
                img.info.width.unwrap_or(0),
                img.info.height,
                img.mime_type
            );
        }
    } else {
        let images = doc.extract_images().expect("image extraction failed");
        if images.is_empty() {
            println!("No images found.");
            return;
        }
        println!("{} image(s):", images.len());
        for img in &images {
            println!(
                "  [{}] p.{}  {}×{:?}  cs={:?}  bpc={:?}  fmt={:?}  filters={:?}",
                img.image_index,
                img.page_index + 1,
                img.width.unwrap_or(0),
                img.height,
                img.color_space,
                img.bits_per_component,
                img.format,
                img.filters
            );
        }
    }
}

fn cmd_annotations(doc: &PdfDocument) {
    let annots = doc
        .extract_annotations()
        .expect("annotation extraction failed");
    if annots.is_empty() {
        println!("No annotations.");
        return;
    }
    println!("{} annotation(s):", annots.len());
    for a in &annots {
        println!(
            "  p.{} [{:?}]  author={:?}  uri={:?}",
            a.page_index + 1,
            a.kind,
            a.author.as_deref().unwrap_or(""),
            a.uri.as_deref().unwrap_or("")
        );
        if let Some(c) = &a.contents {
            println!("    └─ {c}");
        }
    }
}

fn cmd_tables(doc: &PdfDocument) {
    let tables = doc.extract_tables().expect("table extraction failed");
    if tables.is_empty() {
        println!("No tables detected.");
        return;
    }
    println!("{} table(s) detected:", tables.len());
    for (ti, t) in tables.iter().enumerate() {
        println!(
            "\n  Table {} on page {}  ({} rows × {} cols)",
            ti + 1,
            t.page_index + 1,
            t.rows.len(),
            t.col_count
        );
        for (ri, row) in t.rows.iter().enumerate() {
            let cells: Vec<&str> = row.cells.iter().map(|c| c.text.as_str()).collect();
            println!("    [{ri:2}] {}", cells.join(" │ "));
        }
    }
}

fn cmd_bookmarks(doc: &PdfDocument) {
    let bm = doc.extract_bookmarks().expect("bookmark extraction failed");
    if bm.is_empty() {
        println!("No bookmarks.");
        return;
    }
    print_bm(&bm, 0);
}

fn print_bm(nodes: &[rustpdf::BookmarkNode], depth: usize) {
    for n in nodes {
        let pg = n
            .page_index
            .map(|p| format!(" → p.{}", p + 1))
            .unwrap_or_default();
        println!("{}{}{pg}", "  ".repeat(depth), n.title);
        print_bm(&n.children, depth + 1);
    }
}

fn cmd_fields(doc: &PdfDocument) {
    let fields = doc
        .extract_form_fields()
        .expect("form field extraction failed");
    if fields.is_empty() {
        println!("No form fields.");
        return;
    }
    println!(
        "{:30}  {:12}  {:6}  {:6}  value",
        "name", "type", "R/O", "req"
    );
    println!("{}", "─".repeat(72));
    for f in &fields {
        println!(
            "{:30}  {:12}  {:6}  {:6}  {:?}",
            f.name.chars().take(30).collect::<String>(),
            format!("{:?}", f.field_type),
            if f.read_only { "yes" } else { "no" },
            if f.required { "yes" } else { "no" },
            f.value.as_deref().unwrap_or("")
        );
    }
}

fn cmd_export(doc: &PdfDocument, fmt_str: &str, out: Option<String>) {
    let (format, default_ext) = match fmt_str {
        "json" => (ExportFormat::Json, "json"),
        "md" | "markdown" => (ExportFormat::Markdown, "md"),
        "html" => (ExportFormat::Html, "html"),
        "csv" => (ExportFormat::Csv, "csv"),
        _ => (ExportFormat::PlainText, "txt"),
    };
    let output = doc.export(format).expect("export failed");
    match out {
        Some(path) => {
            std::fs::write(&path, &output).expect("write failed");
            eprintln!("Exported to {path}");
        }
        None => {
            let default_name = format!("output.{default_ext}");
            std::fs::write(&default_name, &output).expect("write failed");
            eprintln!("Exported to {default_name}");
        }
    }
}

fn cmd_diff(doc: &PdfDocument, other: &PdfDocument) {
    let diffs = doc.diff(other).expect("diff failed");
    let identical = diffs.iter().all(|d| d.identical);
    if identical {
        println!("Documents are textually identical.");
        return;
    }
    println!("Differences found:");
    for d in &diffs {
        if d.identical {
            continue;
        }
        println!(
            "  Page {} has {} removed / {} added line(s):",
            d.page_index + 1,
            d.only_in_left.len(),
            d.only_in_right.len()
        );
        for l in &d.only_in_left {
            println!("    - {l}");
        }
        for l in &d.only_in_right {
            println!("    + {l}");
        }
    }
}

// ─── helpers ──────────────────────────────────────────────────────────────────

fn opt(s: &Option<String>) -> &str {
    s.as_deref().unwrap_or("(none)")
}

fn save_output(doc: &mut PdfDocument, path: &str) {
    doc.save(path).expect("save failed");
    eprintln!("Saved → {path}");
}

fn flag_value(args: &[String], flag: &str) -> Option<String> {
    args.windows(2).find(|w| w[0] == flag).map(|w| w[1].clone())
}

fn print_usage(bin: &str) {
    eprintln!("rustpdf v0.2 — PDF reader, extractor, exporter & editor\n");
    eprintln!("Usage: {bin} <file.pdf> <command> [args...]\n");
    eprintln!("Commands:");
    eprintln!("  info                        Metadata summary");
    eprintln!("  text [page_index]           Plain text extraction");
    eprintln!("  rich [page_index]           Rich (styled) text spans");
    eprintln!("  search <query>              Full-text search");
    eprintln!("  regex  <pattern>            Regex search");
    eprintln!("  images [--decode]           List/decode embedded images");
    eprintln!("  annotations                 List annotations");
    eprintln!("  tables                      Detect tables");
    eprintln!("  bookmarks                   Print bookmark tree");
    eprintln!("  fields                      List AcroForm fields");
    eprintln!("  export <fmt> [output]       json|md|html|txt|csv");
    eprintln!("  watermark <text>            Stamp watermark → output.pdf");
    eprintln!("  inject <pg> <x> <y> <txt>   Inject text → output.pdf");
    eprintln!("  rotate <page> <90|180|270>  Rotate page → output.pdf");
    eprintln!("  remove <page>               Remove page → output.pdf");
    eprintln!("  merge  <other.pdf>          Append pages → output.pdf");
    eprintln!("  split  <from> <to>          Extract range → output.pdf");
    eprintln!("  annotate <page> <note>      Add comment → output.pdf");
    eprintln!("  diff   <other.pdf>          Text diff");
    eprintln!("  update-meta [--title T] [--author A] [--subject S]  → output.pdf");
}
