
// ─────────────────────────────────────────────────────────────────────────────
// Plain text
// ─────────────────────────────────────────────────────────────────────────────

fn to_plain_text(result: &ExtractionResult) -> String {
    let meta = &result.metadata;
    let mut out = String::new();

    out.push_str("=== PDF EXTRACTION REPORT ===\n\n");
    out.push_str(&format!(
        "Title   : {}\n",
        meta.title.as_deref().unwrap_or("(none)")
    ));
    out.push_str(&format!(
        "Author  : {}\n",
        meta.author.as_deref().unwrap_or("(none)")
    ));
    out.push_str(&format!(
        "Subject : {}\n",
        meta.subject.as_deref().unwrap_or("(none)")
    ));
    out.push_str(&format!(
        "Creator : {}\n",
        meta.creator.as_deref().unwrap_or("(none)")
    ));
    out.push_str(&format!(
        "Producer: {}\n",
        meta.producer.as_deref().unwrap_or("(none)")
    ));
    out.push_str(&format!("Version : {}\n", meta.pdf_version));
    out.push_str(&format!("Pages   : {}\n", meta.page_count));
    out.push_str(&format!("Words   : {}\n", result.total_word_count));
    out.push_str(&format!("Chars   : {}\n", result.total_char_count));
    out.push('\n');

    if !result.bookmarks.is_empty() {
        out.push_str("--- BOOKMARKS ---\n");
        push_bookmarks_plain(&mut out, &result.bookmarks);
        out.push('\n');
    }

    if !result.form_fields.is_empty() {
        out.push_str("--- FORM FIELDS ---\n");
        for f in &result.form_fields {
            out.push_str(&format!(
                "  [{}] {} = {}\n",
                format!("{:?}", f.field_type),
                f.name,
                f.value.as_deref().unwrap_or("")
            ));
        }
        out.push('\n');
    }

    out.push_str("--- PAGE TEXT ---\n\n");
    for page in &result.pages {
        out.push_str(&format!("[ Page {} ]\n", page.page_number));
        out.push_str(&page.text);
        out.push_str("\n\n");
    }

    out
}

fn push_bookmarks_plain(out: &mut String, nodes: &[BookmarkNode]) {
    for node in nodes {
        let indent = "  ".repeat(node.level);
        let page = node
            .page_index
            .map(|p| format!(" → p.{}", p + 1))
            .unwrap_or_default();
        out.push_str(&format!("{}{}{}\n", indent, node.title, page));
        push_bookmarks_plain(out, &node.children);
    }
}