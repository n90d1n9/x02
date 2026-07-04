//! Hyperlinks associated with cells.

use crate::cell::CellAddress;

#[cfg(feature = "serde-support")]
use serde::{Deserialize, Serialize};

/// Kind of hyperlink target.
#[derive(Debug, Clone, PartialEq, Eq)]
#[cfg_attr(feature = "serde-support", derive(Serialize, Deserialize))]
pub enum HyperlinkTarget {
    /// An external URL (http, https, ftp, mailto, …).
    External(String),
    /// A reference to another cell or named range within the workbook.
    Internal(String),
    /// A reference to another file on disk.
    File(String),
}

impl HyperlinkTarget {
    /// Classify and construct from a raw target string and optional `location`.
    pub fn classify(target: &str, location: &str) -> Self {
        if !location.is_empty() {
            return Self::Internal(location.to_owned());
        }
        if target.starts_with('#') {
            return Self::Internal(target.trim_start_matches('#').to_owned());
        }
        if target.starts_with("http://")
            || target.starts_with("https://")
            || target.starts_with("ftp://")
            || target.starts_with("mailto:")
        {
            return Self::External(target.to_owned());
        }
        if target.starts_with("file:///") || target.contains('\\') || target.contains('/') {
            return Self::File(target.to_owned());
        }
        Self::External(target.to_owned())
    }

    /// The raw target string.
    pub fn as_str(&self) -> &str {
        match self {
            Self::External(s) | Self::Internal(s) | Self::File(s) => s,
        }
    }
}

/// A hyperlink bound to a cell range.
#[derive(Debug, Clone)]
#[cfg_attr(feature = "serde-support", derive(Serialize, Deserialize))]
pub struct Hyperlink {
    /// Top-left cell of the hyperlinked range.
    pub address: CellAddress,
    /// The hyperlink target.
    pub target: HyperlinkTarget,
    /// Optional tooltip / screen-tip text.
    pub tooltip: Option<String>,
    /// Optional display text (if different from cell content).
    pub display: Option<String>,
}

impl Hyperlink {
    /// True if the hyperlink points to an external URL.
    pub fn is_external(&self) -> bool {
        matches!(self.target, HyperlinkTarget::External(_))
    }
}

/// Parse `<hyperlinks>` section inside a `sheet.xml`.
#[allow(dead_code)]
pub(crate) fn parse_hyperlinks_section(
    xml: &str,
    // Relationship map: `rId` -> target URL (from `.rels` file).
    rels: &std::collections::HashMap<String, String>,
) -> Vec<Hyperlink> {
    use quick_xml::events::Event;
    use quick_xml::Reader;

    let mut reader = Reader::from_str(xml);
    reader.trim_text(true);
    let mut buf = Vec::new();
    let mut links: Vec<Hyperlink> = Vec::new();

    loop {
        match reader.read_event_into(&mut buf) {
            Ok(Event::Start(ref e)) | Ok(Event::Empty(ref e))
                if e.name().as_ref() == b"hyperlink" =>
            {
                let mut cell_ref = String::new();
                let mut r_id = String::new();
                let mut location = String::new();
                let mut tooltip = None;
                let mut display = None;

                for a in e.attributes().filter_map(|a| a.ok()) {
                    match a.key.as_ref() {
                        b"ref" => cell_ref = String::from_utf8_lossy(&a.value).into_owned(),
                        b"r:id" => r_id = String::from_utf8_lossy(&a.value).into_owned(),
                        b"location" => location = String::from_utf8_lossy(&a.value).into_owned(),
                        b"tooltip" => {
                            tooltip = Some(String::from_utf8_lossy(&a.value).into_owned())
                        }
                        b"display" => {
                            display = Some(String::from_utf8_lossy(&a.value).into_owned())
                        }
                        _ => {}
                    }
                }

                // Resolve rId to actual URL
                let raw_target = if !r_id.is_empty() {
                    rels.get(&r_id).cloned().unwrap_or_default()
                } else {
                    location.clone()
                };

                if cell_ref.is_empty() {
                    buf.clear();
                    continue;
                }

                // Handle ranges like "A1:B3" — use top-left cell
                let top_left = cell_ref.split(':').next().unwrap_or(&cell_ref);
                if let Ok(addr) = CellAddress::from_a1(top_left) {
                    let target = HyperlinkTarget::classify(&raw_target, &location);
                    links.push(Hyperlink {
                        address: addr,
                        target,
                        tooltip,
                        display,
                    });
                }
            }
            Ok(Event::Eof) | Err(_) => break,
            _ => {}
        }
        buf.clear();
    }

    links
}
