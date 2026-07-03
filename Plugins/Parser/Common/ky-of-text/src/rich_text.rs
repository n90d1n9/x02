//! Rich text: a string composed of individually-styled runs.

#[cfg(feature = "serde-support")]
use serde::{Deserialize, Serialize};

/// A single styled text run within a rich-text cell.
#[derive(Debug, Clone, Default, PartialEq)]
#[cfg_attr(feature = "serde-support", derive(Serialize, Deserialize))]
pub struct TextRun {
    /// The text content of this run.
    pub text: String,
    /// Bold.
    pub bold: bool,
    /// Italic.
    pub italic: bool,
    /// Underline.
    pub underline: bool,
    /// Strikethrough.
    pub strike: bool,
    /// Font name (e.g. `"Calibri"`).
    pub font_name: Option<String>,
    /// Font size in points.
    pub font_size: Option<f32>,
    /// Foreground colour as `"RRGGBB"` hex.
    pub color: Option<String>,
    /// Vertical alignment: `"superscript"` | `"subscript"`.
    pub vert_align: Option<String>,
}

impl TextRun {
    /// Plain text run with no formatting.
    pub fn plain(text: impl Into<String>) -> Self {
        Self {
            text: text.into(),
            ..Default::default()
        }
    }
}

/// A rich-text value: an ordered list of [`TextRun`]s.
#[derive(Debug, Clone, Default, PartialEq)]
#[cfg_attr(feature = "serde-support", derive(Serialize, Deserialize))]
pub struct RichText {
    /// Ordered text runs.
    pub runs: Vec<TextRun>,
}

impl RichText {
    /// Concatenate all runs into a plain string.
    pub fn plain_text(&self) -> String {
        self.runs.iter().map(|r| r.text.as_str()).collect()
    }

    /// Return `true` if there are no runs or all runs are empty.
    pub fn is_empty(&self) -> bool {
        self.runs.iter().all(|r| r.text.is_empty())
    }
}

impl std::fmt::Display for RichText {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.plain_text())
    }
}

// ── Parse from XML ────────────────────────────────────────────────────────────

use crate::xml_util::{attr, read_text};
use quick_xml::events::Event;
use quick_xml::Reader;

/// Parse an `<si>` (shared-string item) element that may contain
/// `<t>` (plain) or `<r>` (rich) children.
#[allow(dead_code)]
pub(crate) fn parse_si(xml: &str) -> RichText {
    let mut reader = Reader::from_str(xml);
    reader.trim_text(false);
    let mut buf = Vec::new();
    let mut runs: Vec<TextRun> = Vec::new();
    let mut current: Option<TextRun> = None;

    loop {
        match reader.read_event_into(&mut buf) {
            Ok(Event::Start(ref e)) => match e.name().as_ref() {
                b"r" => {
                    current = Some(TextRun::default());
                }
                b"t" if current.is_some() => {
                    if let Ok(t) = read_text(&mut reader, b"t") {
                        if let Some(run) = current.as_mut() {
                            run.text.push_str(&t);
                        }
                    }
                }
                b"t" => {
                    // plain <si><t>…</t></si>
                    if let Ok(t) = read_text(&mut reader, b"t") {
                        runs.push(TextRun::plain(t));
                    }
                }
                b"b" => {
                    if let Some(r) = current.as_mut() {
                        r.bold = true;
                    }
                }
                b"i" => {
                    if let Some(r) = current.as_mut() {
                        r.italic = true;
                    }
                }
                b"u" => {
                    if let Some(r) = current.as_mut() {
                        r.underline = true;
                    }
                }
                b"strike" => {
                    if let Some(r) = current.as_mut() {
                        r.strike = true;
                    }
                }
                b"sz" => {
                    if let Some(r) = current.as_mut() {
                        if let Some(v) = attr(e, "val") {
                            r.font_size = v.parse().ok();
                        }
                    }
                }
                b"name" | b"rFont" => {
                    if let Some(r) = current.as_mut() {
                        if let Some(v) = attr(e, "val") {
                            r.font_name = Some(v);
                        }
                    }
                }
                b"color" => {
                    if let Some(r) = current.as_mut() {
                        r.color = attr(e, "rgb").or_else(|| attr(e, "theme"));
                    }
                }
                b"vertAlign" => {
                    if let Some(r) = current.as_mut() {
                        r.vert_align = attr(e, "val");
                    }
                }
                _ => {}
            },
            Ok(Event::End(ref e)) if e.name().as_ref() == b"r" => {
                if let Some(run) = current.take() {
                    if !run.text.is_empty() {
                        runs.push(run);
                    }
                }
            }
            Ok(Event::Eof) | Err(_) => break,
            _ => {}
        }
        buf.clear();
    }

    RichText { runs }
}
