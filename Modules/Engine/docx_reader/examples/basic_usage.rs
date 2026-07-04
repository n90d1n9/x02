/// Demonstrates the most common API calls.
///
/// Run with:
///   cargo run --example basic_usage -- path/to/document.docx
use docx_reader::DocxReader;

fn main() {
    let path = std::env::args().nth(1).expect("usage: basic_usage <file.docx>");

    let reader = DocxReader::open(&path).expect("failed to open file");

    // ── Metadata ─────────────────────────────────────────────────────────────
    let meta = reader.metadata().expect("failed to read metadata");
    println!("=== Metadata ===");
    println!("  Title:    {:?}", meta.title);
    println!("  Author:   {:?}", meta.creator);
    println!("  Modified: {:?}", meta.modified);
    println!("  Pages:    {:?}", meta.pages);
    println!("  Words:    {:?}", meta.words);
    println!();

    // ── Plain text ────────────────────────────────────────────────────────────
    let text = reader.extract_text().expect("failed to extract text");
    println!("=== Plain Text (first 500 chars) ===");
    let preview: String = text.chars().take(500).collect();
    println!("{}", preview);
    println!("…");
    println!();
    println!("Word count:  {}", reader.word_count().unwrap());
    println!("Char count:  {}", reader.char_count().unwrap());
    println!();

    // ── Headings ─────────────────────────────────────────────────────────────
    let headings = reader.headings(None).expect("failed to get headings");
    println!("=== Headings ({}) ===", headings.len());
    for h in &headings {
        println!("  [H{}] {}", h.heading_level.unwrap_or(0), h.text());
    }
    println!();

    // ── Tables ────────────────────────────────────────────────────────────────
    let tables = reader.tables().expect("failed to get tables");
    println!("=== Tables ({}) ===", tables.len());
    for (i, t) in tables.iter().enumerate() {
        println!("  Table {}: {}×{}", i + 1, t.row_count(), t.col_count());
        let grid = t.to_text_grid();
        for row in grid.iter().take(3) {
            println!("    {:?}", row);
        }
    }
    println!();

    // ── Images ────────────────────────────────────────────────────────────────
    let images = reader.images().expect("failed to list images");
    println!("=== Images ({}) ===", images.len());
    for img in &images {
        println!(
            "  {} → {} [{}]  {:.2}\" × {:.2}\"",
            img.rel_id,
            img.target,
            img.content_type,
            img.width_inches().unwrap_or(0.0),
            img.height_inches().unwrap_or(0.0),
        );
    }
    println!();

    // ── Comments ─────────────────────────────────────────────────────────────
    let comments = reader.comments().expect("failed to read comments");
    println!("=== Comments ({}) ===", comments.len());
    for c in &comments {
        println!("  [{}] {} ({}): {}", c.id, c.author, c.date.as_deref().unwrap_or("?"), c.text());
    }
    println!();

    // ── Footnotes ────────────────────────────────────────────────────────────
    let footnotes = reader.footnotes().expect("failed to read footnotes");
    println!("=== Footnotes ({}) ===", footnotes.len());
    for fn_ in &footnotes {
        println!("  [{}] {}", fn_.id, fn_.text());
    }
    println!();

    // ── Tracked changes ───────────────────────────────────────────────────────
    let changes = reader.tracked_changes().expect("failed to read tracked changes");
    println!("=== Tracked Changes ({}) ===", changes.len());
    for tc in &changes {
        println!("  {:?} by {} @ {:?}: {:?}", tc.change_type, tc.author, tc.date, tc.text);
    }
}
