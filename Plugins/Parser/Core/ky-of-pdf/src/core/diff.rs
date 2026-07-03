//! Diff two PDFs page-by-page and report text differences.

use crate::{error::Result, extractor, models::PageDiff};
use lopdf::Document;

/// Compare two documents and return a per-page diff.
pub fn diff_documents(doc_a: &Document, doc_b: &Document) -> Result<Vec<PageDiff>> {
    let pages_a = extractor::extract_all_text(doc_a)?;
    let pages_b = extractor::extract_all_text(doc_b)?;
    let max_pages = pages_a.len().max(pages_b.len());

    let mut diffs = Vec::new();
    for i in 0..max_pages {
        let text_a = pages_a.get(i).map(|p| p.text.as_str()).unwrap_or("");
        let text_b = pages_b.get(i).map(|p| p.text.as_str()).unwrap_or("");

        let lines_a: Vec<&str> = text_a.lines().filter(|l| !l.trim().is_empty()).collect();
        let lines_b: Vec<&str> = text_b.lines().filter(|l| !l.trim().is_empty()).collect();

        let only_left: Vec<String> = lines_a
            .iter()
            .filter(|l| !lines_b.contains(l))
            .map(|s| s.to_string())
            .collect();
        let only_right: Vec<String> = lines_b
            .iter()
            .filter(|l| !lines_a.contains(l))
            .map(|s| s.to_string())
            .collect();
        let identical = only_left.is_empty() && only_right.is_empty();

        diffs.push(PageDiff {
            page_index: i,
            only_in_left: only_left,
            only_in_right: only_right,
            identical,
        });
    }
    Ok(diffs)
}

/// Returns `true` if two documents have identical text on every page.
pub fn are_identical(doc_a: &Document, doc_b: &Document) -> Result<bool> {
    Ok(diff_documents(doc_a, doc_b)?.iter().all(|d| d.identical))
}
