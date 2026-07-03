//! Full-text search across all pages.

use crate::{
    error::Result,
    models::{PageText, SearchHit},
};

/// Search for a plain-text query (case-insensitive) across page texts.
pub fn search_text(pages: &[PageText], query: &str) -> Result<Vec<SearchHit>> {
    if query.is_empty() {
        return Ok(vec![]);
    }
    let query_lower = query.to_lowercase();
    let mut hits = Vec::new();

    for page in pages {
        let text_lower = page.text.to_lowercase();
        let mut start = 0;
        while let Some(pos) = text_lower[start..].find(&query_lower) {
            let abs_pos = start + pos;
            let matched_text = &page.text[abs_pos..abs_pos + query.len()];
            let ctx_start = abs_pos.saturating_sub(40);
            let ctx_end = (abs_pos + query.len() + 40).min(page.text.len());
            hits.push(SearchHit {
                page_index: page.page_index,
                page_number: page.page_number,
                char_offset: abs_pos,
                matched_text: matched_text.to_owned(),
                context: page.text[ctx_start..ctx_end].replace('\n', " "),
            });
            start = abs_pos + query.len();
        }
    }
    Ok(hits)
}

/// Regex search across page texts.
pub fn search_regex(pages: &[PageText], pattern: &str) -> Result<Vec<SearchHit>> {
    let re = regex::Regex::new(pattern)
        .map_err(|e| crate::error::Error::Internal(format!("bad regex: {e}")))?;
    let mut hits = Vec::new();
    for page in pages {
        for m in re.find_iter(&page.text) {
            let ctx_start = m.start().saturating_sub(40);
            let ctx_end = (m.end() + 40).min(page.text.len());
            hits.push(SearchHit {
                page_index: page.page_index,
                page_number: page.page_number,
                char_offset: m.start(),
                matched_text: m.as_str().to_owned(),
                context: page.text[ctx_start..ctx_end].replace('\n', " "),
            });
        }
    }
    Ok(hits)
}
