use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum BlockType {
    Paragraph,
    Heading(u8),
    ListItem(u8),      // indentation level
    CodeBlock(String), // language
    Quote,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct InlineStyle {
    pub bold: bool,
    pub italic: bool,
    pub underline: bool,
    pub strikethrough: bool,
    pub font_family: Option<String>,
    pub font_size: Option<f32>,
    pub color: Option<String>,
}

impl Default for InlineStyle {
    fn default() -> Self {
        Self {
            bold: false,
            italic: false,
            underline: false,
            strikethrough: false,
            font_family: None,
            font_size: None,
            color: None,
        }
    }
}

/// A span of text with uniform styling
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct TextSpan {
    pub text: String,
    pub style: InlineStyle,
}

/// A block element in the document (like a paragraph or heading)
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Block {
    pub id: String,
    pub block_type: BlockType,
    pub spans: Vec<TextSpan>,
}

impl Block {
    pub fn new(id: impl Into<String>, block_type: BlockType) -> Self {
        Self {
            id: id.into(),
            block_type,
            spans: Vec::new(),
        }
    }

    pub fn add_span(&mut self, text: impl Into<String>, style: InlineStyle) {
        self.spans.push(TextSpan {
            text: text.into(),
            style,
        });
    }
}
