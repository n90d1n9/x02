# rustpdf v0.2

A complete, pure-Rust PDF **reader**, **extractor**, **exporter**, and **editor** library.

No C dependencies. No Python runtime. Compile once, use anywhere.

---

## What's New in v0.2

| Feature | API |
|---|---|
| **Rich text** spans (font, size, colour, bold/italic, position) | `extract_rich_text()`, `extract_rich_text_page(idx)` |
| **Image decoding** — JPEG passthrough, PNG/raw → valid PNG bytes, data URLs | `decode_images()`, `decode_images_from_page(idx)` |
| **Full-text search** with context snippets | `search(query)`, `search_regex(pattern)` |
| **Table detection** via Y/X clustering | `extract_tables()` |
| **Annotations** — read + write text, link, highlight | `extract_annotations()`, `add_*_annotation()` |
| **Page editing** — remove, rotate, reorder | `remove_page()`, `rotate_page()`, `reorder_pages()` |
| **Watermarks** — diagonal text stamp | `watermark_text(text, size, opacity)` |
| **Text injection** — place text at (x, y) | `inject_text(page, text, x, y, size)` |
| **Metadata editing** | `update_metadata(title, author, …)` |
| **Form fill** — set AcroForm field values | `set_field_value(name, value)` |
| **Merge / split** | `merge(&other)`, `extract_document_range(from, to)` |
| **Diff** | `diff(&other)`, `is_identical_to(&other)` |
| **Save** | `save(path)`, `to_bytes()` |
| **Enhanced metadata** — page size, custom properties | `metadata().page_size`, `.custom_properties` |

---

## Installation

```toml
[dependencies]
rustpdf = { path = "path/to/rustpdf" }
```

---

## Quick Start

```rust
use rustpdf::{PdfDocument, ExportFormat};

fn main() -> rustpdf::Result<()> {
    // ── Open ──────────────────────────────────────────────────
    let mut doc = PdfDocument::open("report.pdf")?;
    // or: PdfDocument::from_bytes(&bytes)?
    // or: PdfDocument::open_with_password("secure.pdf", "pw")?

    // ── Metadata ──────────────────────────────────────────────
    let meta = doc.metadata()?;
    println!("Title  : {:?}", meta.title);
    println!("Pages  : {}", meta.page_count);
    if let Some([w, h]) = meta.page_size {
        println!("Size   : {w:.0} × {h:.0} pt");
    }

    // ── Plain text ────────────────────────────────────────────
    let all_text = doc.extract_text_all()?;
    let pages    = doc.extract_pages()?;          // Vec<PageText>
    let p0_text  = doc.extract_page_text(0)?;

    // ── Rich text ─────────────────────────────────────────────
    for span in doc.extract_rich_text()? {
        println!("{} {}pt bold={} {:?}", span.base_font.unwrap_or_default(),
            span.font_size, span.bold, span.text);
    }

    // ── Images ────────────────────────────────────────────────
    for img in doc.decode_images()? {
        // img.data_url  = "data:image/png;base64,..."
        // img.mime_type = "image/png" or "image/jpeg"
        std::fs::write(format!("img_{}.png", img.info.image_index), &img.encoded_bytes)?;
    }

    // ── Search ────────────────────────────────────────────────
    for hit in doc.search("invoice")? {
        println!("p.{} offset {} — {}", hit.page_number, hit.char_offset, hit.context);
    }
    for hit in doc.search_regex(r"\d{4,}")? {
        println!("p.{} number: {}", hit.page_number, hit.matched_text);
    }

    // ── Bookmarks / forms / annotations ───────────────────────
    let bookmarks   = doc.extract_bookmarks()?;
    let form_fields = doc.extract_form_fields()?;
    let annotations = doc.extract_annotations()?;
    let tables      = doc.extract_tables()?;

    // ── Add annotations ───────────────────────────────────────
    doc.add_text_annotation(0, [100.0, 700.0, 200.0, 750.0], "Me", "Review this")?;
    doc.add_link_annotation(0, [50.0, 650.0, 200.0, 670.0], "https://example.com")?;
    doc.add_highlight_annotation(0, [50.0, 700.0, 300.0, 716.0], [1.0, 1.0, 0.0], "Me")?;

    // ── Edit ──────────────────────────────────────────────────
    doc.watermark_text("CONFIDENTIAL", None, Some(0.25))?;
    doc.inject_text(0, "Reviewed by Alice", 50.0, 50.0, 10.0)?;
    doc.rotate_page(0, 90)?;
    doc.update_metadata(Some("New Title"), Some("Alice"), None, None, None)?;
    doc.set_field_value("form.name", "Alice")?; // AcroForm fields

    // ── Merge / split ─────────────────────────────────────────
    let other = PdfDocument::open("appendix.pdf")?;
    doc.merge(&other)?;                                 // append pages
    let sub = doc.extract_document_range(0, 2)?;       // pages 0..=2

    // ── Diff ──────────────────────────────────────────────────
    let v2 = PdfDocument::open("report_v2.pdf")?;
    for d in doc.diff(&v2)? {
        if !d.identical {
            println!("p.{} changed: -{} +{}", d.page_index+1,
                d.only_in_left.len(), d.only_in_right.len());
        }
    }

    // ── Export ────────────────────────────────────────────────
    std::fs::write("out.json", doc.export(ExportFormat::Json)?)?;
    std::fs::write("out.md",   doc.export(ExportFormat::Markdown)?)?;
    std::fs::write("out.html", doc.export(ExportFormat::Html)?)?;
    std::fs::write("out.txt",  doc.export(ExportFormat::PlainText)?)?;
    std::fs::write("out.csv",  doc.export(ExportFormat::Csv)?)?;

    // ── Save ──────────────────────────────────────────────────
    doc.save("report_edited.pdf")?;
    let bytes = doc.to_bytes()?; // in-memory pipeline

    Ok(())
}
```

---

## CLI

```bash
# Build
cargo build --example cli

# Commands
./target/debug/examples/cli report.pdf info
./target/debug/examples/cli report.pdf text
./target/debug/examples/cli report.pdf text 2          # page 2 (0-based)
./target/debug/examples/cli report.pdf rich
./target/debug/examples/cli report.pdf search invoice
./target/debug/examples/cli report.pdf regex '\d{4,}'
./target/debug/examples/cli report.pdf images --decode  # writes PNG/JPEG files
./target/debug/examples/cli report.pdf annotations
./target/debug/examples/cli report.pdf tables
./target/debug/examples/cli report.pdf bookmarks
./target/debug/examples/cli report.pdf fields
./target/debug/examples/cli report.pdf export json out.json
./target/debug/examples/cli report.pdf export html out.html
./target/debug/examples/cli report.pdf watermark CONFIDENTIAL
./target/debug/examples/cli report.pdf inject 0 50 400 "Reviewed"
./target/debug/examples/cli report.pdf rotate 0 90
./target/debug/examples/cli report.pdf remove 0
./target/debug/examples/cli report.pdf merge appendix.pdf
./target/debug/examples/cli report.pdf split 0 4
./target/debug/examples/cli report.pdf annotate 0 "Check this section"
./target/debug/examples/cli report.pdf diff report_v2.pdf
./target/debug/examples/cli report.pdf update-meta --title "New Title" --author "Alice"
```

---

## Module Overview

| Module | Purpose |
|---|---|
| `document` | `PdfDocument` — unified public API |
| `extractor` | Plain text, metadata, images, bookmarks, form fields |
| `rich_text` | Styled text spans with font/size/colour/position |
| `image_decoder` | JPEG/PNG/raw decoding → PNG bytes + data URLs |
| `annotator` | Read & write PDF annotations |
| `editor` | Page CRUD, watermark, text injection, metadata, form fill, merge/split |
| `search` | Plain-text and regex full-text search |
| `table_extractor` | Heuristic table detection from span geometry |
| `diff` | Page-by-page text diff |
| `exporter` | JSON / Markdown / HTML / plain text / CSV rendering |
| `models` | All data types (Metadata, PageText, RichSpan, ImageInfo, …) |
| `error` | `Error` enum + `Result` alias |

---

## Error Handling

```rust
use rustpdf::{Error, PdfDocument};

match PdfDocument::open("file.pdf") {
    Err(Error::Io(e))            => eprintln!("file error: {e}"),
    Err(Error::Parse(msg))       => eprintln!("corrupt PDF: {msg}"),
    Err(Error::PasswordRequired) => eprintln!("needs a password"),
    Err(Error::WrongPassword)    => eprintln!("wrong password"),
    Err(Error::PageOutOfRange(i, n)) => eprintln!("page {i} not in {n}-page doc"),
    Err(e) => eprintln!("other: {e}"),
    Ok(doc) => { /* use doc */ }
}
```

---

## Running Tests

```bash
cargo test
# 60 integration tests + 6 doc-tests, all passing
```

---

## License

MIT
