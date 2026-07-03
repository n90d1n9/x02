use serde::{Deserialize, Serialize};




// ---------------------------------------------------------------------------
// Headers & Footers
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct SectionHeaderFooter {
    pub default_header: Option<Vec<Paragraph>>,
    pub first_header: Option<Vec<Paragraph>>,
    pub even_header: Option<Vec<Paragraph>>,
    pub default_footer: Option<Vec<Paragraph>>,
    pub first_footer: Option<Vec<Paragraph>>,
    pub even_footer: Option<Vec<Paragraph>>,
}
