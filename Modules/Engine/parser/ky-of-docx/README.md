# docx_reader

A comprehensive, ergonomic Rust library for **reading and extracting content** from `.docx` (Word) files.

---

## Features

| Capability | API |
|---|---|
| Plain-text extraction | `extract_text()` / `extract_text_with_options()` |
| Structured parse (paragraphs, tables, lists, …) | `parse()` → `Document` |
| Metadata (author, title, dates, word count, …) | `metadata()` |
| Headings | `headings(level)` |
| Tables | `tables()` |
| Embedded images (list + bytes) | `images()` / `image_bytes()` / `save_image()` |
| Styles | `styles()` |
| Comments | `comments()` |
| Footnotes & Endnotes | `footnotes()` / `endnotes()` |
| Tracked changes (insertions & deletions) | `tracked_changes()` |
| Headers & Footers | `headers_footers()` |
| JSON export | `to_json()` |
| Word / char count | `word_count()` / `char_count()` |
| Raw XML access | `raw_document_xml()` / `read_part()` |

---

## Quick Start

Add to `Cargo.toml`:

```toml
[dependencies]
docx_reader = { path = "path/to/docx_reader" }
# or once published:
# docx_reader = "0.1"
```

```rust
use docx_reader::DocxReader;

fn main() {
    // Open from disk
    let reader = DocxReader::open("report.docx").unwrap();

    // Or from bytes (useful in web handlers / tests)
    // let reader = DocxReader::from_bytes(bytes).unwrap();

    // ── Plain text ───────────────────────────────────────────────────────
    let text = reader.extract_text().unwrap();
    println!("{}", text);

    // ── Statistics ───────────────────────────────────────────────────────
    println!("Words: {}", reader.word_count().unwrap());
    println!("Chars: {}", reader.char_count().unwrap());

    // ── Metadata ─────────────────────────────────────────────────────────
    let meta = reader.metadata().unwrap();
    println!("Author: {:?}", meta.creator);
    println!("Title:  {:?}", meta.title);
    println!("Pages:  {:?}", meta.pages);

    // ── Structured document ──────────────────────────────────────────────
    let doc = reader.parse().unwrap();
    for block in &doc.body {
        match block {
            docx_reader::Block::Paragraph(p) => {
                if let Some(level) = p.heading_level {
                    println!("[H{}] {}", level, p.text());
                }
            }
            docx_reader::Block::Table(t) => {
                println!("Table {}×{}", t.row_count(), t.col_count());
                for row in t.to_text_grid() {
                    println!("  {:?}", row);
                }
            }
            _ => {}
        }
    }
}
```

---

## Detailed API Reference

### `DocxReader`

#### Constructors

```rust
// From a file path
let reader = DocxReader::open("document.docx")?;

// From in-memory bytes (e.g. downloaded from S3, received over HTTP)
let reader = DocxReader::from_bytes(bytes)?;
```

#### Text Extraction

```rust
// Default options
let text = reader.extract_text()?;

// Full control with TextOptions
use docx_reader::TextOptions;
let opts = TextOptions {
    include_headers:   true,
    include_footers:   true,
    include_footnotes: true,
    include_endnotes:  true,
    include_comments:  true,
    include_deletions: false,           // skip deleted tracked-change text
    paragraph_separator: "\n".into(),
    table_cell_separator: "\t".into(),
    table_row_separator: "\n".into(),
};
let text = reader.extract_text_with_options(&opts)?;

// Shortcut: include absolutely everything
let text = reader.extract_text_with_options(&TextOptions::all())?;
```

#### Metadata

```rust
let meta = reader.metadata()?;
// meta.title, meta.creator, meta.created, meta.modified,
// meta.keywords, meta.pages, meta.words, meta.characters, …
```

#### Headings

```rust
// All headings
let all = reader.headings(None)?;

// Only H1
let h1 = reader.headings(Some(1))?;
for h in &h1 {
    println!("{}", h.text());
}
```

#### Tables

```rust
let tables = reader.tables()?;
for table in &tables {
    println!("{}×{}", table.row_count(), table.col_count());

    // 2-D text grid
    for row in table.to_text_grid() {
        println!("{:?}", row);
    }

    // Structured access
    for row in &table.rows {
        for cell in &row.cells {
            println!("{}", cell.text());
        }
    }
}
```

#### Images

```rust
// List image refs (no bytes loaded)
for img in reader.images()? {
    println!("{} ({}) {:.2}\" × {:.2}\"",
        img.rel_id, img.content_type,
        img.width_inches().unwrap_or(0.0),
        img.height_inches().unwrap_or(0.0));
}

// Load raw bytes
let data = reader.image_bytes("rId5")?;
data.save("out.png")?;
println!("{}", data.to_data_uri()); // data:image/png;base64,…

// Save directly
reader.save_image("rId5", "picture.png")?;
```

#### Comments

```rust
for comment in reader.comments()? {
    println!("[{}] {} @ {:?}: {}",
        comment.id, comment.author, comment.date, comment.text());
    // comment.parent_id is Some() for replies
}
```

#### Footnotes & Endnotes

```rust
for fn_ in reader.footnotes()? {
    println!("[{}] {}", fn_.id, fn_.text());
}
for en in reader.endnotes()? {
    println!("[{}] {}", en.id, en.text());
}
```

#### Tracked Changes

```rust
for tc in reader.tracked_changes()? {
    match tc.change_type {
        docx_reader::ChangeType::Insertion => print!("+ "),
        docx_reader::ChangeType::Deletion  => print!("- "),
        docx_reader::ChangeType::FormatChange => print!("~ "),
    }
    println!("{:?} by {} on {:?}", tc.text, tc.author, tc.date);
}
```

#### Styles

```rust
for style in reader.styles()? {
    println!("{:?} '{}' (based on {:?})", style.style_type, style.name, style.based_on);
}
```

#### JSON Export

```rust
let json = reader.to_json()?;
std::fs::write("document.json", &json)?;
```

#### Low-Level / Raw Access

```rust
// List all ZIP entries
let names = reader.part_names()?;

// Read any XML part
let xml = reader.read_part("word/document.xml")?;
let xml = reader.read_part("docProps/core.xml")?;

// Read raw bytes (for images, fonts, …)
let bytes = reader.read_part_bytes("word/media/image1.png")?;
```

---

## Data Types

### `Document`

```
Document
├── metadata: Metadata
├── body: Vec<Block>
│   ├── Block::Paragraph(Paragraph)
│   │   ├── style: Option<String>
│   │   ├── heading_level: Option<u8>   // 1-9
│   │   ├── list_info: Option<ListInfo>
│   │   ├── alignment: Option<Alignment>
│   │   └── runs: Vec<Run>
│   │       ├── text: String
│   │       ├── formatting: RunFormatting
│   │       │   ├── bold, italic, underline, strikethrough
│   │       │   ├── color, highlight, size (half-points)
│   │       │   └── font_ascii, font_east_asia
│   │       └── hyperlink: Option<String>
│   ├── Block::Table(Table)
│   │   └── rows: Vec<TableRow>
│   │       └── cells: Vec<TableCell>
│   │           └── paragraphs: Vec<Paragraph>
│   └── Block::SectionBreak
├── footnotes: Vec<Footnote>
├── endnotes: Vec<Endnote>
├── comments: Vec<Comment>
├── tracked_changes: Vec<TrackedChange>
├── images: Vec<ImageRef>
├── styles: Vec<StyleDef>
└── headers_footers: Vec<SectionHeaderFooter>
```

---

## Running Tests

```bash
cargo test
```

## Running Examples

```bash
# Basic extraction
cargo run --example basic_usage -- document.docx

# Full JSON export + image saving
cargo run --example extract_all -- document.docx output.json
```

---

## Dependencies

| Crate | Purpose |
|---|---|
| `zip` | ZIP archive reading |
| `quick-xml` | Streaming XML parser |
| `serde` / `serde_json` | Serialisation |
| `thiserror` | Ergonomic error types |
| `base64` | Image data-URI encoding |

---

## License

MIT
