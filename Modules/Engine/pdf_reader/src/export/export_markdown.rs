

// ─────────────────────────────────────────────────────────────────────────────
// Markdown
// ─────────────────────────────────────────────────────────────────────────────

fn to_markdown(result: &ExtractionResult) -> String {
    let meta = &result.metadata;
    let mut out = String::new();

    let title = meta.title.as_deref().unwrap_or("Untitled Document");
    out.push_str(&format!("# {title}\n\n"));

    out.push_str("## Metadata\n\n");
    out.push_str("| Property | Value |\n");
    out.push_str("|----------|-------|\n");
    push_md_row(&mut out, "Author", meta.author.as_deref().unwrap_or(""));
    push_md_row(&mut out, "Subject", meta.subject.as_deref().unwrap_or(""));
    push_md_row(&mut out, "Keywords", meta.keywords.as_deref().unwrap_or(""));
    push_md_row(&mut out, "Creator", meta.creator.as_deref().unwrap_or(""));
    push_md_row(&mut out, "Producer", meta.producer.as_deref().unwrap_or(""));
    push_md_row(
        &mut out,
        "Created",
        meta.creation_date.as_deref().unwrap_or(""),
    );
    push_md_row(
        &mut out,
        "Modified",
        meta.modification_date.as_deref().unwrap_or(""),
    );
    push_md_row(&mut out, "PDF Version", &meta.pdf_version);
    push_md_row(&mut out, "Pages", &meta.page_count.to_string());
    push_md_row(&mut out, "Words", &result.total_word_count.to_string());
    push_md_row(&mut out, "Characters", &result.total_char_count.to_string());
    out.push('\n');

    if !result.bookmarks.is_empty() {
        out.push_str("## Table of Contents\n\n");
        push_bookmarks_md(&mut out, &result.bookmarks);
        out.push('\n');
    }

    if !result.form_fields.is_empty() {
        out.push_str("## Form Fields\n\n");
        out.push_str("| Name | Type | Value |\n");
        out.push_str("|------|------|-------|\n");
        for f in &result.form_fields {
            out.push_str(&format!(
                "| {} | {:?} | {} |\n",
                md_escape(&f.name),
                f.field_type,
                md_escape(f.value.as_deref().unwrap_or(""))
            ));
        }
        out.push('\n');
    }

    out.push_str("## Content\n\n");
    for page in &result.pages {
        out.push_str(&format!("### Page {}\n\n", page.page_number));
        out.push_str(&page.text);
        out.push_str("\n\n---\n\n");
    }

    out
}

fn push_md_row(out: &mut String, key: &str, val: &str) {
    if !val.is_empty() {
        out.push_str(&format!("| {} | {} |\n", key, md_escape(val)));
    }
}

fn push_bookmarks_md(out: &mut String, nodes: &[BookmarkNode]) {
    for node in nodes {
        let indent = "  ".repeat(node.level);
        let page = node
            .page_index
            .map(|p| format!(" *(p. {})*", p + 1))
            .unwrap_or_default();
        out.push_str(&format!("{}- {}{}\n", indent, node.title, page));
        push_bookmarks_md(out, &node.children);
    }
}

fn md_escape(s: &str) -> String {
    s.replace('|', "\\|").replace('\n', " ")
}