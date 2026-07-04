//! Cell comments (also called "notes" in newer Excel versions).

use crate::cell::CellAddress;
use crate::xml_util::read_text;
use quick_xml::events::Event;
use quick_xml::Reader;

#[cfg(feature = "serde-support")]
use serde::{Deserialize, Serialize};

/// A comment attached to a single cell.
#[derive(Debug, Clone)]
#[cfg_attr(feature = "serde-support", derive(Serialize, Deserialize))]
pub struct Comment {
    /// The cell this comment is attached to.
    pub address: CellAddress,
    /// Comment text (plain).
    pub text: String,
    /// Author name (if present in the XML).
    pub author: Option<String>,
}

/// Parse `xl/comments{n}.xml` and return all comments.
#[allow(dead_code)]
pub(crate) fn parse_comments_xml(xml: &str) -> Vec<Comment> {
    let mut reader = Reader::from_str(xml);
    reader.trim_text(true);

    let mut authors: Vec<String> = Vec::new();
    let mut comments: Vec<Comment> = Vec::new();
    let mut buf = Vec::new();
    let mut in_authors = false;
    let mut in_comment = false;
    let mut current_ref = String::new();
    let mut current_author_idx: usize = 0;

    loop {
        match reader.read_event_into(&mut buf) {
            Ok(Event::Start(ref e)) => match e.name().as_ref() {
                b"authors" => {
                    in_authors = true;
                }
                b"author" if in_authors => {
                    if let Ok(t) = read_text(&mut reader, b"author") {
                        authors.push(t);
                    }
                }
                b"comment" => {
                    in_comment = true;
                    current_ref = String::new();
                    current_author_idx = 0;
                    for attr in e.attributes().filter_map(|a| a.ok()) {
                        match attr.key.as_ref() {
                            b"ref" => {
                                current_ref = String::from_utf8_lossy(&attr.value).into_owned()
                            }
                            b"authorId" => {
                                current_author_idx =
                                    String::from_utf8_lossy(&attr.value).parse().unwrap_or(0)
                            }
                            _ => {}
                        }
                    }
                }
                b"t" if in_comment => {
                    if let Ok(text) = read_text(&mut reader, b"t") {
                        if !current_ref.is_empty() {
                            if let Ok(addr) = CellAddress::from_a1(&current_ref) {
                                let author = authors.get(current_author_idx).cloned();
                                comments.push(Comment {
                                    address: addr,
                                    text,
                                    author,
                                });
                                current_ref.clear();
                            }
                        }
                    }
                }
                _ => {}
            },
            Ok(Event::End(ref e)) => match e.name().as_ref() {
                b"authors" => {
                    in_authors = false;
                }
                b"comment" => {
                    in_comment = false;
                }
                _ => {}
            },
            Ok(Event::Eof) | Err(_) => break,
            _ => {}
        }
        buf.clear();
    }

    comments
}



// ---------------------------------------------------------------------------
// Comments
// ---------------------------------------------------------------------------

pub fn parse_comments(xml: &str) -> Vec<Comment> {
    let mut comments = Vec::new();
    let mut reader = Reader::from_str(xml);
    reader.trim_text(false);
    let mut buf = Vec::new();
    let mut in_comment = false;
    let mut current = Comment {
        id: String::new(),
        author: String::new(),
        date: None,
        initials: None,
        paragraphs: Vec::new(),
        parent_id: None,
    };
    let mut in_run = false;
    let mut in_t = false;
    let mut current_text = String::new();
    let mut current_para = Paragraph::default();

    loop {
        match reader.read_event_into(&mut buf) {
            Ok(Event::Start(ref e)) | Ok(Event::Empty(ref e)) => {
                let local = String::from_utf8_lossy(e.local_name().as_ref()).to_string();
                match local.as_str() {
                    "comment" => {
                        in_comment = true;
                        current = Comment {
                            id: String::new(),
                            author: String::new(),
                            date: None,
                            initials: None,
                            paragraphs: Vec::new(),
                            parent_id: None,
                        };
                        for attr in e.attributes().flatten() {
                            match attr.key.as_ref() {
                                b"w:id" => current.id = String::from_utf8_lossy(&attr.value).to_string(),
                                b"w:author" => current.author = String::from_utf8_lossy(&attr.value).to_string(),
                                b"w:date" => current.date = Some(String::from_utf8_lossy(&attr.value).to_string()),
                                b"w:initials" => current.initials = Some(String::from_utf8_lossy(&attr.value).to_string()),
                                b"w:paraIdParent" => current.parent_id = Some(String::from_utf8_lossy(&attr.value).to_string()),
                                _ => {}
                            }
                        }
                    }
                    "r" if in_comment => in_run = true,
                    "t" if in_run => in_t = true,
                    "p" if in_comment => current_para = Paragraph::default(),
                    _ => {}
                }
            }
            Ok(Event::Text(ref t)) if in_t => {
                current_text.push_str(&t.unescape().unwrap_or_default());
            }
            Ok(Event::End(ref e)) => {
                let local = String::from_utf8_lossy(e.local_name().as_ref()).to_string();
                match local.as_str() {
                    "t" => in_t = false,
                    "r" if in_comment => {
                        if !current_text.is_empty() {
                            current_para.runs.push(Run {
                                text: current_text.clone(),
                                ..Default::default()
                            });
                            current_text.clear();
                        }
                        in_run = false;
                    }
                    "p" if in_comment => {
                        current.paragraphs.push(current_para.clone());
                        current_para = Paragraph::default();
                    }
                    "comment" => {
                        comments.push(current.clone());
                        in_comment = false;
                    }
                    _ => {}
                }
            }
            Ok(Event::Eof) | Err(_) => break,
            _ => {}
        }
        buf.clear();
    }
    comments
}
