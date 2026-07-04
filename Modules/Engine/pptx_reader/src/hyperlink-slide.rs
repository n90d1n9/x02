use serde::{Deserialize, Serialize};

/// A hyperlink attached to a shape or text run.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Hyperlink {
    pub target: HyperlinkTarget,
    pub tooltip: Option<String>,
    pub highlight_click: bool,
    pub end_sound: Option<String>,
}

/// The destination of a hyperlink.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum HyperlinkTarget {
    /// An external URL (http, https, ftp, mailto, etc.)
    Url(String),
    /// A slide within the same presentation (0-based index).
    SlideIndex(usize),
    /// A named slide.
    SlideName(String),
    /// First slide.
    FirstSlide,
    /// Last slide.
    LastSlide,
    /// Previous slide.
    PreviousSlide,
    /// Next slide.
    NextSlide,
    /// End show.
    EndShow,
    /// A custom show.
    CustomShow(String),
    /// A file path.
    File(String),
    /// A bookmark/anchor within a file.
    Bookmark { target: String, anchor: String },
    /// An OLE action.
    OleVerb(String),
}

impl Hyperlink {
    /// Get the URL string if this is an external URL.
    pub fn url(&self) -> Option<&str> {
        match &self.target {
            HyperlinkTarget::Url(u) => Some(u),
            _ => None,
        }
    }

    /// Check if this is a slide navigation link.
    pub fn is_slide_navigation(&self) -> bool {
        matches!(
            &self.target,
            HyperlinkTarget::SlideIndex(_)
                | HyperlinkTarget::SlideName(_)
                | HyperlinkTarget::FirstSlide
                | HyperlinkTarget::LastSlide
                | HyperlinkTarget::PreviousSlide
                | HyperlinkTarget::NextSlide
                | HyperlinkTarget::EndShow
        )
    }
}
