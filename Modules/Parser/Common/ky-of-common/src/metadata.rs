use quick_xml::events::Event;
use quick_xml::Reader;

#[cfg(feature = "serde-support")]
use serde::{Deserialize, Serialize};

// ---------------------------------------------------------------------------
// Metadata
// ---------------------------------------------------------------------------

/// Core document properties (from `docProps/core.xml`).
#[derive(Debug, Clone, Default)]
#[cfg_attr(feature = "serde-support", derive(Serialize, Deserialize))]
pub struct Metadata {
    pub title: Option<String>,
    pub subject: Option<String>,
    pub creator: Option<String>,
    pub description: Option<String>,
    pub keywords: Option<String>,
    pub last_modified_by: Option<String>,
    pub revision: Option<u32>,
    pub created: Option<String>,
    pub modified: Option<String>,
    pub category: Option<String>,
    pub content_status: Option<String>,
    /// Page count (from `docProps/app.xml`).
    pub pages: Option<u32>,
    /// Word count (from `docProps/app.xml`).
    pub words: Option<u32>,
    /// Character count (from `docProps/app.xml`).
    pub characters: Option<u32>,
    /// Application that created the file.
    pub application: Option<String>,
    pub app_version: Option<String>,
}



// ---------------------------------------------------------------------------
// Metadata
// ---------------------------------------------------------------------------

pub fn parse_core_props(xml: &str) -> Metadata {
    let mut meta = Metadata::default();
    let mut reader = Reader::from_str(xml);
    reader.trim_text(true);
    let mut buf = Vec::new();
    let mut current_tag = String::new();

    loop {
        match reader.read_event_into(&mut buf) {
            Ok(Event::Start(ref e)) => {
                current_tag = String::from_utf8_lossy(e.local_name().as_ref()).to_string();
            }
            Ok(Event::Text(ref t)) => {
                let val = t.unescape().unwrap_or_default().to_string();
                match current_tag.as_str() {
                    "title" => meta.title = Some(val),
                    "subject" => meta.subject = Some(val),
                    "creator" => meta.creator = Some(val),
                    "description" => meta.description = Some(val),
                    "keywords" => meta.keywords = Some(val),
                    "lastModifiedBy" => meta.last_modified_by = Some(val),
                    "revision" => meta.revision = val.parse().ok(),
                    "created" => meta.created = Some(val),
                    "modified" => meta.modified = Some(val),
                    "category" => meta.category = Some(val),
                    "contentStatus" => meta.content_status = Some(val),
                    _ => {}
                }
            }
            Ok(Event::Eof) | Err(_) => break,
            _ => {}
        }
        buf.clear();
    }
    meta
}

pub fn parse_app_props(xml: &str, meta: &mut Metadata) {
    let mut reader = Reader::from_str(xml);
    reader.trim_text(true);
    let mut buf = Vec::new();
    let mut current_tag = String::new();

    loop {
        match reader.read_event_into(&mut buf) {
            Ok(Event::Start(ref e)) => {
                current_tag = String::from_utf8_lossy(e.local_name().as_ref()).to_string();
            }
            Ok(Event::Text(ref t)) => {
                let val = t.unescape().unwrap_or_default().to_string();
                match current_tag.as_str() {
                    "Pages" => meta.pages = val.parse().ok(),
                    "Words" => meta.words = val.parse().ok(),
                    "Characters" => meta.characters = val.parse().ok(),
                    "Application" => meta.application = Some(val),
                    "AppVersion" => meta.app_version = Some(val),
                    _ => {}
                }
            }
            Ok(Event::Eof) | Err(_) => break,
            _ => {}
        }
        buf.clear();
    }
}