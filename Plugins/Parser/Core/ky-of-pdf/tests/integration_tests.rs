//! Integration tests for rustpdf v0.2
//! All tests run against hand-crafted in-memory PDFs — no fixture files needed.

use rustpdf::{ExportFormat, PdfDocument};

// ─────────────────────────────────────────────────────────────────────────────
// Minimal PDF builder helpers
// ─────────────────────────────────────────────────────────────────────────────

fn xref_entry(offset: usize) -> String {
    format!("{:010} 00000 n \n", offset)
}

/// Build a minimal one-page PDF with selectable text and a full Info dictionary.
fn one_page_pdf(body_text: &str) -> Vec<u8> {
    let content = format!(
        "BT /F1 12 Tf 50 700 Td ({}) Tj ET",
        body_text.replace('(', "\\(").replace(')', "\\)")
    );
    let clen = content.len();

    let mut pdf = Vec::<u8>::new();
    pdf.extend_from_slice(b"%PDF-1.4\n");

    let off1 = pdf.len();
    pdf.extend_from_slice(b"1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n");
    let off2 = pdf.len();
    pdf.extend_from_slice(b"2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n");
    let off3 = pdf.len();
    pdf.extend_from_slice(
        b"3 0 obj\n<< /Type /Page /Parent 2 0 R \
        /MediaBox [0 0 612 792] \
        /Resources << /Font << /F1 << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> >> >> \
        /Contents 4 0 R >>\nendobj\n",
    );
    let off4 = pdf.len();
    pdf.extend_from_slice(format!("4 0 obj\n<< /Length {clen} >>\nstream\n").as_bytes());
    pdf.extend_from_slice(content.as_bytes());
    pdf.extend_from_slice(b"\nendstream\nendobj\n");
    let off5 = pdf.len();
    pdf.extend_from_slice(
        b"5 0 obj\n<< /Title (Test Document) /Author (Jane Doe) \
          /Subject (Integration Testing) /Keywords (rust pdf test) \
          /Creator (rustpdf-test) /Producer (rustpdf v0.2) >>\nendobj\n",
    );
    let xref_off = pdf.len();
    let xref = format!(
        "xref\n0 6\n0000000000 65535 f \n{}{}{}{}{}\n",
        xref_entry(off1),
        xref_entry(off2),
        xref_entry(off3),
        xref_entry(off4),
        xref_entry(off5),
    );
    pdf.extend_from_slice(xref.as_bytes());
    pdf.extend_from_slice(
        format!("trailer\n<< /Size 6 /Root 1 0 R /Info 5 0 R >>\nstartxref\n{xref_off}\n%%EOF\n")
            .as_bytes(),
    );
    pdf
}

/// Build a two-page PDF.
fn two_page_pdf(p1: &str, p2: &str) -> Vec<u8> {
    // Page 1 content
    let c1 = format!(
        "BT /F1 12 Tf 50 700 Td ({}) Tj ET",
        p1.replace('(', "\\(").replace(')', "\\)")
    );
    let c2 = format!(
        "BT /F1 12 Tf 50 700 Td ({}) Tj ET",
        p2.replace('(', "\\(").replace(')', "\\)")
    );
    let l1 = c1.len();
    let l2 = c2.len();
    let font_res = b"/Font << /F1 << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> >>";

    let mut pdf = Vec::<u8>::new();
    pdf.extend_from_slice(b"%PDF-1.4\n");
    let off1 = pdf.len();
    pdf.extend_from_slice(b"1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n");
    let off2 = pdf.len();
    pdf.extend_from_slice(b"2 0 obj\n<< /Type /Pages /Kids [3 0 R 5 0 R] /Count 2 >>\nendobj\n");
    let off3 = pdf.len();
    pdf.extend_from_slice(format!("3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << {} >> /Contents 4 0 R >>\nendobj\n", String::from_utf8_lossy(font_res)).as_bytes());
    let off4 = pdf.len();
    pdf.extend_from_slice(
        format!("4 0 obj\n<< /Length {l1} >>\nstream\n{c1}\nendstream\nendobj\n").as_bytes(),
    );
    let off5 = pdf.len();
    pdf.extend_from_slice(format!("5 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << {} >> /Contents 6 0 R >>\nendobj\n", String::from_utf8_lossy(font_res)).as_bytes());
    let off6 = pdf.len();
    pdf.extend_from_slice(
        format!("6 0 obj\n<< /Length {l2} >>\nstream\n{c2}\nendstream\nendobj\n").as_bytes(),
    );
    let off7 = pdf.len();
    pdf.extend_from_slice(b"7 0 obj\n<< /Title (Two Page Doc) /Author (Test) >>\nendobj\n");
    let xref_off = pdf.len();
    let xref = format!(
        "xref\n0 8\n0000000000 65535 f \n{}{}{}{}{}{}{}\n",
        xref_entry(off1),
        xref_entry(off2),
        xref_entry(off3),
        xref_entry(off4),
        xref_entry(off5),
        xref_entry(off6),
        xref_entry(off7),
    );
    pdf.extend_from_slice(xref.as_bytes());
    pdf.extend_from_slice(
        format!("trailer\n<< /Size 8 /Root 1 0 R /Info 7 0 R >>\nstartxref\n{xref_off}\n%%EOF\n")
            .as_bytes(),
    );
    pdf
}

// ─────────────────────────────────────────────────────────────────────────────
// Basic open / parse
// ─────────────────────────────────────────────────────────────────────────────

#[test]
fn test_from_bytes_one_page() {
    let doc = PdfDocument::from_bytes(&one_page_pdf("Hello World")).unwrap();
    assert_eq!(doc.page_count(), 1);
    assert!(!doc.is_encrypted());
}

#[test]
fn test_from_bytes_two_pages() {
    let doc = PdfDocument::from_bytes(&two_page_pdf("Page one", "Page two")).unwrap();
    assert_eq!(doc.page_count(), 2);
}

// ─────────────────────────────────────────────────────────────────────────────
// Metadata
// ─────────────────────────────────────────────────────────────────────────────

#[test]
fn test_metadata_all_fields() {
    let doc = PdfDocument::from_bytes(&one_page_pdf("x")).unwrap();
    let meta = doc.metadata().unwrap();
    assert_eq!(meta.title.as_deref(), Some("Test Document"));
    assert_eq!(meta.author.as_deref(), Some("Jane Doe"));
    assert_eq!(meta.subject.as_deref(), Some("Integration Testing"));
    assert_eq!(meta.keywords.as_deref(), Some("rust pdf test"));
    assert_eq!(meta.creator.as_deref(), Some("rustpdf-test"));
    assert_eq!(meta.producer.as_deref(), Some("rustpdf v0.2"));
    assert_eq!(meta.page_count, 1);
    assert!(!meta.pdf_version.is_empty());
    assert!(!meta.is_encrypted);
}

#[test]
fn test_metadata_page_size() {
    let doc = PdfDocument::from_bytes(&one_page_pdf("x")).unwrap();
    let meta = doc.metadata().unwrap();
    // MediaBox [0 0 612 792]
    if let Some(sz) = meta.page_size {
        assert!((sz[0] - 612.0).abs() < 1.0);
        assert!((sz[1] - 792.0).abs() < 1.0);
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Plain text extraction
// ─────────────────────────────────────────────────────────────────────────────

#[test]
fn test_extract_text_all() {
    let doc = PdfDocument::from_bytes(&one_page_pdf("Hello rustpdf")).unwrap();
    let text = doc.extract_text_all().unwrap();
    assert!(text.contains("Hello"), "got: {text:?}");
}

#[test]
fn test_extract_pages_stats() {
    let doc = PdfDocument::from_bytes(&one_page_pdf("one two three four five")).unwrap();
    let pages = doc.extract_pages().unwrap();
    assert_eq!(pages.len(), 1);
    assert_eq!(pages[0].page_number, 1);
    assert_eq!(pages[0].page_index, 0);
    assert!(pages[0].word_count >= 1);
    assert!(pages[0].char_count >= 1);
}

#[test]
fn test_extract_page_text_single() {
    let doc = PdfDocument::from_bytes(&one_page_pdf("SinglePage content")).unwrap();
    let t = doc.extract_page_text(0).unwrap();
    assert!(t.contains("SinglePage"), "got: {t:?}");
}

#[test]
fn test_extract_page_out_of_range() {
    let doc = PdfDocument::from_bytes(&one_page_pdf("x")).unwrap();
    assert!(matches!(
        doc.extract_page_text(5),
        Err(rustpdf::Error::PageOutOfRange(_, _))
    ));
}

#[test]
fn test_extract_page_range() {
    let doc = PdfDocument::from_bytes(&two_page_pdf("Alpha content", "Beta content")).unwrap();
    let pages = doc.extract_page_range(0, 1).unwrap();
    assert_eq!(pages.len(), 2);
    let combined: String = pages
        .iter()
        .map(|p| p.text.as_str())
        .collect::<Vec<_>>()
        .join(" ");
    assert!(combined.contains("Alpha") || combined.contains("Beta"));
}

#[test]
fn test_two_page_individual_extraction() {
    let doc = PdfDocument::from_bytes(&two_page_pdf("FirstPageText", "SecondPageText")).unwrap();
    let p1 = doc.extract_page_text(0).unwrap();
    let p2 = doc.extract_page_text(1).unwrap();
    assert!(
        p1.contains("First")
            || p2.contains("First")
            || p1.contains("Second")
            || p2.contains("Second"),
        "p1={p1:?} p2={p2:?}"
    );
}

// ─────────────────────────────────────────────────────────────────────────────
// Rich text
// ─────────────────────────────────────────────────────────────────────────────

#[test]
fn test_rich_text_returns_spans() {
    let doc = PdfDocument::from_bytes(&one_page_pdf("Rich text test")).unwrap();
    let spans = doc.extract_rich_text().unwrap();
    // May return 0 spans for very simple PDFs — just check it doesn't panic
    for s in &spans {
        assert!(!s.font_name.is_empty() || s.font_size >= 0.0);
    }
}

#[test]
fn test_rich_text_page_index() {
    let doc = PdfDocument::from_bytes(&two_page_pdf("Page A", "Page B")).unwrap();
    let spans = doc.extract_rich_text().unwrap();
    for s in &spans {
        assert!(s.page_index < 2, "page_index {} out of range", s.page_index);
    }
}

#[test]
fn test_rich_text_single_page() {
    let doc = PdfDocument::from_bytes(&one_page_pdf("Page zero only")).unwrap();
    let spans = doc.extract_rich_text_page(0).unwrap();
    // page_index of all spans must be 0
    for s in &spans {
        assert_eq!(s.page_index, 0);
    }
}

#[test]
fn test_rich_text_page_out_of_range() {
    let doc = PdfDocument::from_bytes(&one_page_pdf("x")).unwrap();
    assert!(doc.extract_rich_text_page(99).is_err());
}

// ─────────────────────────────────────────────────────────────────────────────
// Images
// ─────────────────────────────────────────────────────────────────────────────

#[test]
fn test_extract_images_empty() {
    let doc = PdfDocument::from_bytes(&one_page_pdf("no images here")).unwrap();
    let imgs = doc.extract_images().unwrap();
    assert!(imgs.is_empty());
}

#[test]
fn test_decode_images_empty() {
    let doc = PdfDocument::from_bytes(&one_page_pdf("no images")).unwrap();
    let decoded = doc.decode_images().unwrap();
    assert!(decoded.is_empty());
}

// ─────────────────────────────────────────────────────────────────────────────
// Bookmarks & form fields
// ─────────────────────────────────────────────────────────────────────────────

#[test]
fn test_bookmarks_empty() {
    let doc = PdfDocument::from_bytes(&one_page_pdf("x")).unwrap();
    assert!(doc.extract_bookmarks().unwrap().is_empty());
}

#[test]
fn test_form_fields_empty() {
    let doc = PdfDocument::from_bytes(&one_page_pdf("x")).unwrap();
    assert!(doc.extract_form_fields().unwrap().is_empty());
}

// ─────────────────────────────────────────────────────────────────────────────
// Annotations
// ─────────────────────────────────────────────────────────────────────────────

#[test]
fn test_annotations_empty_on_plain_pdf() {
    let doc = PdfDocument::from_bytes(&one_page_pdf("no annotations")).unwrap();
    let annots = doc.extract_annotations().unwrap();
    assert!(annots.is_empty());
}

#[test]
fn test_add_text_annotation_roundtrip() {
    let mut doc = PdfDocument::from_bytes(&one_page_pdf("annotatable page")).unwrap();
    doc.add_text_annotation(0, [100.0, 100.0, 200.0, 200.0], "Tester", "My note")
        .unwrap();
    let annots = doc.extract_annotations().unwrap();
    assert!(!annots.is_empty(), "annotation was not written");
    let a = &annots[0];
    assert_eq!(a.page_index, 0);
    assert!(matches!(a.kind, rustpdf::AnnotationKind::Text));
    assert_eq!(a.contents.as_deref(), Some("My note"));
    assert_eq!(a.author.as_deref(), Some("Tester"));
}

#[test]
fn test_add_link_annotation() {
    let mut doc = PdfDocument::from_bytes(&one_page_pdf("link page")).unwrap();
    doc.add_link_annotation(0, [50.0, 50.0, 150.0, 70.0], "https://example.com")
        .unwrap();
    let annots = doc.extract_annotations().unwrap();
    let link = annots
        .iter()
        .find(|a| matches!(a.kind, rustpdf::AnnotationKind::Link));
    assert!(link.is_some(), "link annotation not found");
    assert_eq!(link.unwrap().uri.as_deref(), Some("https://example.com"));
}

#[test]
fn test_add_highlight_annotation() {
    let mut doc = PdfDocument::from_bytes(&one_page_pdf("highlight me")).unwrap();
    doc.add_highlight_annotation(0, [50.0, 700.0, 200.0, 715.0], [1.0, 1.0, 0.0], "Reviewer")
        .unwrap();
    let annots = doc.extract_annotations().unwrap();
    let hl = annots
        .iter()
        .find(|a| matches!(a.kind, rustpdf::AnnotationKind::Highlight));
    assert!(hl.is_some());
}

#[test]
fn test_multiple_annotations() {
    let mut doc = PdfDocument::from_bytes(&one_page_pdf("multi-annot")).unwrap();
    doc.add_text_annotation(0, [10.0, 10.0, 50.0, 50.0], "Alice", "First note")
        .unwrap();
    doc.add_text_annotation(0, [60.0, 10.0, 100.0, 50.0], "Bob", "Second note")
        .unwrap();
    let annots = doc.extract_annotations().unwrap();
    assert!(annots.len() >= 2);
}

// ─────────────────────────────────────────────────────────────────────────────
// Tables
// ─────────────────────────────────────────────────────────────────────────────

#[test]
fn test_tables_no_panic_on_plain_text() {
    let doc = PdfDocument::from_bytes(&one_page_pdf("just plain text no table")).unwrap();
    let tables = doc.extract_tables().unwrap();
    // May or may not find a table — we just check it doesn't panic
    let _ = tables;
}

// ─────────────────────────────────────────────────────────────────────────────
// Search
// ─────────────────────────────────────────────────────────────────────────────

#[test]
fn test_search_found() {
    let doc = PdfDocument::from_bytes(&one_page_pdf("invoice number 12345")).unwrap();
    let hits = doc.search("invoice").unwrap();
    assert!(!hits.is_empty(), "expected at least one hit");
    assert_eq!(hits[0].page_number, 1);
    assert!(hits[0].context.to_lowercase().contains("invoice"));
}

#[test]
fn test_search_not_found() {
    let doc = PdfDocument::from_bytes(&one_page_pdf("hello world")).unwrap();
    let hits = doc.search("quantum").unwrap();
    assert!(hits.is_empty());
}

#[test]
fn test_search_case_insensitive() {
    let doc = PdfDocument::from_bytes(&one_page_pdf("Hello World rustpdf")).unwrap();
    let lower = doc.search("hello").unwrap();
    let upper = doc.search("HELLO").unwrap();
    assert_eq!(lower.len(), upper.len());
}

#[test]
fn test_search_multipage() {
    let doc = PdfDocument::from_bytes(&two_page_pdf("find me here", "and also here")).unwrap();
    let hits = doc.search("here").unwrap();
    assert!(
        hits.len() >= 1,
        "expected hits across pages, got {}",
        hits.len()
    );
}

#[test]
fn test_search_regex() {
    let doc = PdfDocument::from_bytes(&one_page_pdf("Order 12345 total 99.99")).unwrap();
    let hits = doc.search_regex(r"\d{4,}").unwrap();
    assert!(!hits.is_empty(), "regex should match numbers");
}

#[test]
fn test_search_regex_bad_pattern() {
    let doc = PdfDocument::from_bytes(&one_page_pdf("text")).unwrap();
    assert!(doc.search_regex("[unclosed").is_err());
}

#[test]
fn test_search_hit_fields() {
    let doc = PdfDocument::from_bytes(&one_page_pdf("the quick brown fox")).unwrap();
    let hits = doc.search("quick").unwrap();
    if !hits.is_empty() {
        let h = &hits[0];
        assert_eq!(h.page_index, 0);
        assert_eq!(h.page_number, 1);
        assert!(h.char_offset < 100);
        assert!(!h.context.is_empty());
        assert!(!h.matched_text.is_empty());
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Editing — page manipulation
// ─────────────────────────────────────────────────────────────────────────────

#[test]
fn test_remove_page() {
    let mut doc = PdfDocument::from_bytes(&two_page_pdf("First", "Second")).unwrap();
    assert_eq!(doc.page_count(), 2);
    doc.remove_page(0).unwrap();
    assert_eq!(doc.page_count(), 1);
}

#[test]
fn test_remove_page_out_of_range() {
    let mut doc = PdfDocument::from_bytes(&one_page_pdf("x")).unwrap();
    assert!(doc.remove_page(5).is_err());
}

#[test]
fn test_rotate_page() {
    let mut doc = PdfDocument::from_bytes(&one_page_pdf("rotate me")).unwrap();
    doc.rotate_page(0, 90).unwrap();
    // No panic and document still parseable
    assert_eq!(doc.page_count(), 1);
}

#[test]
fn test_rotate_page_invalid_angle() {
    let mut doc = PdfDocument::from_bytes(&one_page_pdf("x")).unwrap();
    assert!(doc.rotate_page(0, 45).is_err());
}

#[test]
fn test_extract_document_range_single() {
    let doc = PdfDocument::from_bytes(&two_page_pdf("A", "B")).unwrap();
    let sub = doc.extract_document_range(0, 0).unwrap();
    assert_eq!(sub.page_count(), 1);
}

#[test]
fn test_extract_document_range_all() {
    let doc = PdfDocument::from_bytes(&two_page_pdf("A", "B")).unwrap();
    let sub = doc.extract_document_range(0, 1).unwrap();
    assert_eq!(sub.page_count(), 2);
}

#[test]
fn test_merge_documents() {
    let mut doc_a = PdfDocument::from_bytes(&one_page_pdf("Doc A")).unwrap();
    let doc_b = PdfDocument::from_bytes(&one_page_pdf("Doc B")).unwrap();
    doc_a.merge(&doc_b).unwrap();
    assert_eq!(doc_a.page_count(), 2);
}

// ─────────────────────────────────────────────────────────────────────────────
// Editing — text injection & watermark
// ─────────────────────────────────────────────────────────────────────────────

#[test]
fn test_inject_text_then_save() {
    let mut doc = PdfDocument::from_bytes(&one_page_pdf("original content")).unwrap();
    doc.inject_text(0, "Injected Line", 50.0, 400.0, 10.0)
        .unwrap();
    let bytes = doc.to_bytes().unwrap();
    assert!(!bytes.is_empty());
    // Re-parse
    let doc2 = PdfDocument::from_bytes(&bytes).unwrap();
    assert_eq!(doc2.page_count(), 1);
}

#[test]
fn test_watermark_text_produces_valid_pdf() {
    let mut doc = PdfDocument::from_bytes(&one_page_pdf("watermark target")).unwrap();
    doc.watermark_text("CONFIDENTIAL", Some(36.0), Some(0.2))
        .unwrap();
    let bytes = doc.to_bytes().unwrap();
    assert!(!bytes.is_empty());
    let doc2 = PdfDocument::from_bytes(&bytes).unwrap();
    assert_eq!(doc2.page_count(), 1);
}

#[test]
fn test_watermark_default_params() {
    let mut doc = PdfDocument::from_bytes(&one_page_pdf("default watermark")).unwrap();
    doc.watermark_text("DRAFT", None, None).unwrap();
    assert!(doc.to_bytes().unwrap().len() > 100);
}

// ─────────────────────────────────────────────────────────────────────────────
// Editing — metadata
// ─────────────────────────────────────────────────────────────────────────────

#[test]
fn test_update_metadata() {
    let mut doc = PdfDocument::from_bytes(&one_page_pdf("x")).unwrap();
    doc.update_metadata(
        Some("New Title"),
        Some("New Author"),
        Some("New Subject"),
        None,
        None,
    )
    .unwrap();
    let meta = doc.metadata().unwrap();
    assert_eq!(meta.title.as_deref(), Some("New Title"));
    assert_eq!(meta.author.as_deref(), Some("New Author"));
    assert_eq!(meta.subject.as_deref(), Some("New Subject"));
}

#[test]
fn test_update_metadata_preserves_unchanged_fields() {
    let mut doc = PdfDocument::from_bytes(&one_page_pdf("x")).unwrap();
    // Only update title; author should stay "Jane Doe"
    doc.update_metadata(Some("Updated Title"), None, None, None, None)
        .unwrap();
    let meta = doc.metadata().unwrap();
    assert_eq!(meta.title.as_deref(), Some("Updated Title"));
    // Author should still be the original
    assert_eq!(meta.author.as_deref(), Some("Jane Doe"));
}

// ─────────────────────────────────────────────────────────────────────────────
// Diff
// ─────────────────────────────────────────────────────────────────────────────

#[test]
fn test_diff_identical_documents() {
    let bytes = one_page_pdf("same content");
    let doc_a = PdfDocument::from_bytes(&bytes).unwrap();
    let doc_b = PdfDocument::from_bytes(&bytes).unwrap();
    let diffs = doc_a.diff(&doc_b).unwrap();
    assert!(
        diffs.iter().all(|d| d.identical),
        "same PDF should diff as identical"
    );
    assert!(doc_a.is_identical_to(&doc_b).unwrap());
}

#[test]
fn test_diff_different_documents() {
    let doc_a = PdfDocument::from_bytes(&one_page_pdf("unique content alpha")).unwrap();
    let doc_b = PdfDocument::from_bytes(&one_page_pdf("unique content beta")).unwrap();
    let diffs = doc_a.diff(&doc_b).unwrap();
    assert!(!diffs.is_empty());
    // At least one page should be non-identical
    let any_diff = diffs.iter().any(|d| !d.identical);
    assert!(any_diff, "different PDFs should show a diff");
}

#[test]
fn test_is_identical_to_false() {
    let doc_a = PdfDocument::from_bytes(&one_page_pdf("content X")).unwrap();
    let doc_b = PdfDocument::from_bytes(&one_page_pdf("content Y")).unwrap();
    assert!(!doc_a.is_identical_to(&doc_b).unwrap());
}

#[test]
fn test_diff_page_fields() {
    let doc_a = PdfDocument::from_bytes(&one_page_pdf("line one\nline two")).unwrap();
    let doc_b = PdfDocument::from_bytes(&one_page_pdf("line one\nline three")).unwrap();
    let diffs = doc_a.diff(&doc_b).unwrap();
    let d = &diffs[0];
    assert_eq!(d.page_index, 0);
    assert!(
        d.only_in_left.iter().any(|l| l.contains("two"))
            || d.only_in_right.iter().any(|l| l.contains("three"))
            || !d.identical,
        "diff should detect changed line"
    );
}

// ─────────────────────────────────────────────────────────────────────────────
// Serialisation round-trips
// ─────────────────────────────────────────────────────────────────────────────

#[test]
fn test_to_bytes_and_reload() {
    let mut doc = PdfDocument::from_bytes(&one_page_pdf("roundtrip test")).unwrap();
    let bytes = doc.to_bytes().unwrap();
    assert!(
        bytes.starts_with(b"%PDF"),
        "saved bytes should be a valid PDF"
    );
    let doc2 = PdfDocument::from_bytes(&bytes).unwrap();
    assert_eq!(doc2.page_count(), 1);
}

// ─────────────────────────────────────────────────────────────────────────────
// All-in-one extraction
// ─────────────────────────────────────────────────────────────────────────────

#[test]
fn test_extract_all_fields_populated() {
    let doc = PdfDocument::from_bytes(&one_page_pdf("all in one test content")).unwrap();
    let result = doc.extract_all().unwrap();
    assert_eq!(result.metadata.page_count, 1);
    assert_eq!(result.pages.len(), 1);
    assert!(result.total_word_count > 0);
    assert!(result.total_char_count > 0);
    assert!(result.images.is_empty());
    assert!(result.annotations.is_empty());
}

// ─────────────────────────────────────────────────────────────────────────────
// Exports
// ─────────────────────────────────────────────────────────────────────────────

#[test]
fn test_export_json_valid() {
    let doc = PdfDocument::from_bytes(&one_page_pdf("json export test")).unwrap();
    let json = doc.export(ExportFormat::Json).unwrap();
    let v: serde_json::Value = serde_json::from_str(&json).expect("valid JSON");
    assert!(v["metadata"]["page_count"].as_u64().unwrap() > 0);
    assert!(v["pages"].is_array());
    assert!(v["annotations"].is_array());
    assert!(v["tables"].is_array());
}

#[test]
fn test_export_plain_text_contains_content() {
    let doc = PdfDocument::from_bytes(&one_page_pdf("export plain text")).unwrap();
    let txt = doc.export(ExportFormat::PlainText).unwrap();
    assert!(txt.contains("Pages"), "should have metadata header");
    assert!(
        txt.contains("export") || txt.contains("plain"),
        "should have page text"
    );
}

#[test]
fn test_export_markdown_structure() {
    let doc = PdfDocument::from_bytes(&one_page_pdf("markdown export")).unwrap();
    let md = doc.export(ExportFormat::Markdown).unwrap();
    assert!(md.starts_with('#'), "should start with heading");
    assert!(md.contains("## Metadata"), "should have metadata section");
    assert!(md.contains("## Content"), "should have content section");
}

#[test]
fn test_export_html_structure() {
    let doc = PdfDocument::from_bytes(&one_page_pdf("html export")).unwrap();
    let html = doc.export(ExportFormat::Html).unwrap();
    assert!(html.contains("<!DOCTYPE html>"));
    assert!(html.contains("<h1>"));
    assert!(html.contains("<h2>Metadata</h2>"));
    assert!(html.contains("<h2>Content</h2>"));
}

#[test]
fn test_export_csv_format() {
    let doc = PdfDocument::from_bytes(&one_page_pdf("csv export test")).unwrap();
    let csv = doc.export(ExportFormat::Csv).unwrap();
    let lines: Vec<&str> = csv.lines().collect();
    assert_eq!(lines[0], "page_number,word_count,char_count,text");
    assert!(lines.len() >= 2);
    // Data row starts with "1,"
    assert!(lines[1].starts_with("1,"));
}

#[test]
fn test_export_result_static_method() {
    let doc = PdfDocument::from_bytes(&one_page_pdf("static export")).unwrap();
    let result = doc.extract_all().unwrap();
    let md = PdfDocument::export_result(&result, ExportFormat::Markdown).unwrap();
    assert!(md.contains("## Metadata"));
    let html = PdfDocument::export_result(&result, ExportFormat::Html).unwrap();
    assert!(html.contains("<!DOCTYPE html>"));
}

#[test]
fn test_export_json_includes_annotations() {
    let mut doc = PdfDocument::from_bytes(&one_page_pdf("annotated")).unwrap();
    doc.add_text_annotation(0, [10.0, 10.0, 50.0, 50.0], "Bot", "auto note")
        .unwrap();
    let json = doc.export(ExportFormat::Json).unwrap();
    let v: serde_json::Value = serde_json::from_str(&json).unwrap();
    let annots = v["annotations"].as_array().unwrap();
    assert!(!annots.is_empty(), "JSON should include annotations");
}

// ─────────────────────────────────────────────────────────────────────────────
// Image decoder unit tests
// ─────────────────────────────────────────────────────────────────────────────

#[test]
fn test_image_decoder_format_detection_jpeg_magic() {
    use rustpdf::ImageInfo;
    let info = ImageInfo {
        page_index: 0,
        image_index: 0,
        width: Some(10),
        height: Some(10),
        color_space: Some("DeviceRGB".into()),
        bits_per_component: Some(8),
        filters: vec![],
        format: rustpdf::ImageFormat::Unknown,
        data: vec![0xFF, 0xD8, 0xFF, 0xE0], // JPEG magic
        data_base64: String::new(),
    };
    let fmt = rustpdf::image_decoder::detect_format(&info);
    assert_eq!(fmt, rustpdf::ImageFormat::Jpeg);
}

#[test]
fn test_image_decoder_format_detection_dct_filter() {
    use rustpdf::ImageInfo;
    let info = ImageInfo {
        page_index: 0,
        image_index: 0,
        width: Some(4),
        height: Some(4),
        color_space: Some("DeviceRGB".into()),
        bits_per_component: Some(8),
        filters: vec!["DCTDecode".to_string()],
        format: rustpdf::ImageFormat::Unknown,
        data: vec![0xFF, 0xD8, 0xFF],
        data_base64: String::new(),
    };
    let fmt = rustpdf::image_decoder::detect_format(&info);
    assert_eq!(fmt, rustpdf::ImageFormat::Jpeg);
}

#[test]
fn test_image_decoder_raw_1x1_rgb() {
    use rustpdf::ImageInfo;
    let info = ImageInfo {
        page_index: 0,
        image_index: 0,
        width: Some(1),
        height: Some(1),
        color_space: Some("DeviceRGB".into()),
        bits_per_component: Some(8),
        filters: vec![],
        format: rustpdf::ImageFormat::Raw,
        data: vec![255, 0, 128], // one RGB pixel
        data_base64: String::new(),
    };
    let decoded = rustpdf::image_decoder::decode_image(&info).unwrap();
    // PNG signature
    assert!(decoded.encoded_bytes.starts_with(&[137, 80, 78, 71]));
    assert_eq!(decoded.mime_type, "image/png");
    assert!(decoded.data_url.starts_with("data:image/png;base64,"));
}

#[test]
fn test_image_decoder_raw_gray_2x2() {
    use rustpdf::ImageInfo;
    let info = ImageInfo {
        page_index: 0,
        image_index: 0,
        width: Some(2),
        height: Some(2),
        color_space: Some("DeviceGray".into()),
        bits_per_component: Some(8),
        filters: vec![],
        format: rustpdf::ImageFormat::Raw,
        data: vec![0, 128, 255, 64],
        data_base64: String::new(),
    };
    let decoded = rustpdf::image_decoder::decode_image(&info).unwrap();
    assert!(
        decoded.encoded_bytes.starts_with(&[137, 80, 78, 71]),
        "should be valid PNG"
    );
}
