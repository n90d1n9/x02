use serde::{Deserialize, Serialize};




#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum VerticalAlign {
    Superscript,
    Subscript,
    Baseline,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum Alignment {
    Left,
    Center,
    Right,
    Justify,
    Distribute,
    Both,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ParagraphBorder {
    pub top: Option<BorderSide>,
    pub bottom: Option<BorderSide>,
    pub left: Option<BorderSide>,
    pub right: Option<BorderSide>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BorderSide {
    pub style: String,
    pub size: u32,
    pub color: Option<String>,
}
