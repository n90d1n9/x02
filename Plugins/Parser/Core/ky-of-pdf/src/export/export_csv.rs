// ─────────────────────────────────────────────────────────────────────────────
// CSV
// ─────────────────────────────────────────────────────────────────────────────

fn to_csv(result: &ExtractionResult) -> String {
    let mut out = String::from("page_number,word_count,char_count,text\n");
    for page in &result.pages {
        // Escape text: wrap in quotes, double any internal quotes
        let escaped = page.text.replace('"', "\"\"");
        out.push_str(&format!(
            "{},{},{},\"{}\"\n",
            page.page_number, page.word_count, page.char_count, escaped
        ));
    }
    out
}
