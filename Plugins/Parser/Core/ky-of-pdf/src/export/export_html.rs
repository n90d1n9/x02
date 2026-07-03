
// ─────────────────────────────────────────────────────────────────────────────
// HTML
// ─────────────────────────────────────────────────────────────────────────────

fn to_html(result: &ExtractionResult) -> String {
    let meta = &result.metadata;
    let title = html_escape(meta.title.as_deref().unwrap_or("PDF Document"));

    let mut body = String::new();

    body.push_str(&format!("<h1>{title}</h1>\n"));

    body.push_str("<section class=\"metadata\">\n<h2>Metadata</h2>\n<table>\n");
    push_html_row(&mut body, "Author", meta.author.as_deref());
    push_html_row(&mut body, "Subject", meta.subject.as_deref());
    push_html_row(&mut body, "Keywords", meta.keywords.as_deref());
    push_html_row(&mut body, "Creator", meta.creator.as_deref());
    push_html_row(&mut body, "Producer", meta.producer.as_deref());
    push_html_row(&mut body, "Created", meta.creation_date.as_deref());
    push_html_row(&mut body, "Modified", meta.modification_date.as_deref());
    push_html_row(&mut body, "PDF Version", Some(meta.pdf_version.as_str()));
    push_html_row(&mut body, "Pages", Some(&meta.page_count.to_string()));
    push_html_row(
        &mut body,
        "Words",
        Some(&result.total_word_count.to_string()),
    );
    body.push_str("</table>\n</section>\n\n");

    if !result.bookmarks.is_empty() {
        body.push_str("<section class=\"toc\">\n<h2>Table of Contents</h2>\n");
        push_bookmarks_html(&mut body, &result.bookmarks);
        body.push_str("</section>\n\n");
    }

    if !result.form_fields.is_empty() {
        body.push_str("<section class=\"forms\">\n<h2>Form Fields</h2>\n<table>\n");
        body.push_str("<tr><th>Name</th><th>Type</th><th>Value</th></tr>\n");
        for f in &result.form_fields {
            body.push_str(&format!(
                "<tr><td>{}</td><td>{:?}</td><td>{}</td></tr>\n",
                html_escape(&f.name),
                f.field_type,
                html_escape(f.value.as_deref().unwrap_or(""))
            ));
        }
        body.push_str("</table>\n</section>\n\n");
    }

    body.push_str("<section class=\"content\">\n<h2>Content</h2>\n");
    for page in &result.pages {
        body.push_str(&format!(
            "<article id=\"page-{}\">\n<h3>Page {}</h3>\n",
            page.page_number, page.page_number
        ));
        body.push_str("<pre class=\"page-text\">");
        body.push_str(&html_escape(&page.text));
        body.push_str("</pre>\n</article>\n\n");
    }
    body.push_str("</section>\n");

    format!(
        r#"<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>{title}</title>
  <style>
    :root {{ --accent: #2563eb; --border: #e5e7eb; --bg: #f9fafb; }}
    body {{ font-family: system-ui, sans-serif; max-width: 900px; margin: 0 auto; padding: 2rem; color: #111; }}
    h1 {{ color: var(--accent); border-bottom: 2px solid var(--accent); padding-bottom: .5rem; }}
    h2 {{ color: #374151; margin-top: 2rem; }}
    h3 {{ color: #6b7280; }}
    table {{ border-collapse: collapse; width: 100%; margin-bottom: 1rem; }}
    th, td {{ text-align: left; padding: .5rem .75rem; border: 1px solid var(--border); }}
    th {{ background: var(--bg); font-weight: 600; }}
    pre.page-text {{ background: var(--bg); padding: 1rem; border-radius: .5rem; white-space: pre-wrap; word-break: break-word; font-size: .875rem; line-height: 1.6; }}
    ul {{ list-style: disc; padding-left: 1.5rem; }}
    article {{ margin-bottom: 2rem; border-left: 4px solid var(--accent); padding-left: 1rem; }}
  </style>
</head>
<body>
{body}
</body>
</html>
"#
    )
}

fn push_html_row(out: &mut String, key: &str, val: Option<&str>) {
    if let Some(v) = val {
        if !v.is_empty() {
            out.push_str(&format!(
                "<tr><th>{key}</th><td>{}</td></tr>\n",
                html_escape(v)
            ));
        }
    }
}

fn push_bookmarks_html(out: &mut String, nodes: &[BookmarkNode]) {
    out.push_str("<ul>\n");
    for node in nodes {
        let page = node
            .page_index
            .map(|p| format!(" <small>(p. {})</small>", p + 1))
            .unwrap_or_default();
        out.push_str(&format!("<li>{}{}", html_escape(&node.title), page));
        if !node.children.is_empty() {
            push_bookmarks_html(out, &node.children);
        }
        out.push_str("</li>\n");
    }
    out.push_str("</ul>\n");
}

fn html_escape(s: &str) -> String {
    s.replace('&', "&amp;")
        .replace('<', "&lt;")
        .replace('>', "&gt;")
        .replace('"', "&quot;")
}


fn push_bm_html(o: &mut String, nodes: &[BookmarkNode]) {
    *o += "<ul>\n";
    for n in nodes {
        let pg = n
            .page_index
            .map(|p| format!(" <small>(p. {})</small>", p + 1))
            .unwrap_or_default();
        *o += &format!("<li>{}{}", he(&n.title), pg);
        if !n.children.is_empty() {
            push_bm_html(o, &n.children);
        }
        *o += "</li>\n";
    }
    *o += "</ul>\n";
}

fn he(s: &str) -> String {
    s.replace('&', "&amp;")
        .replace('<', "&lt;")
        .replace('>', "&gt;")
        .replace('"', "&quot;")
}
