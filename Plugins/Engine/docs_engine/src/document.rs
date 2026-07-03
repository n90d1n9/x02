use crate::block::Block;
use serde::{Deserialize, Serialize};

/// Represents a rich text document composed of sequential blocks
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct Document {
    pub title: String,
    pub blocks: Vec<Block>,
}

impl Document {
    pub fn new(title: impl Into<String>) -> Self {
        Self {
            title: title.into(),
            blocks: Vec::new(),
        }
    }

    pub fn add_block(&mut self, block: Block) {
        self.blocks.push(block);
    }

    pub fn get_block(&self, index: usize) -> Option<&Block> {
        self.blocks.get(index)
    }

    pub fn get_block_mut(&mut self, index: usize) -> Option<&mut Block> {
        self.blocks.get_mut(index)
    }

    pub fn to_json(&self) -> Result<String, serde_json::Error> {
        serde_json::to_string(self)
    }

    pub fn from_json(json: &str) -> Result<Self, serde_json::Error> {
        serde_json::from_str(json)
    }

    /// Insert text into a specific block at a given span index and character offset
    pub fn insert_text(
        &mut self,
        block_index: usize,
        span_index: usize,
        char_offset: usize,
        text: &str,
    ) -> Result<(), String> {
        let block = self.blocks.get_mut(block_index).ok_or("Block not found")?;
        let span = block.spans.get_mut(span_index).ok_or("Span not found")?;
        let byte_offset = char_to_byte_offset(&span.text, char_offset)?;
        span.text.insert_str(byte_offset, text);
        Ok(())
    }

    /// Split a block into two at the given span index and character offset (e.g. when pressing Enter)
    pub fn split_block(
        &mut self,
        block_index: usize,
        span_index: usize,
        char_offset: usize,
    ) -> Result<(), String> {
        let block = self.blocks.get_mut(block_index).ok_or("Block not found")?;
        let span = block.spans.get_mut(span_index).ok_or("Span not found")?;
        let byte_offset = char_to_byte_offset(&span.text, char_offset)?;

        let remainder_text = span.text[byte_offset..].to_string();
        span.text.truncate(byte_offset);

        let mut new_block = Block::new(uuid::Uuid::new_v4().to_string(), block.block_type.clone());

        // Copy the remainder of the current span
        if !remainder_text.is_empty() {
            new_block.add_span(remainder_text, span.style.clone());
        }

        // Move subsequent spans to the new block
        if span_index + 1 < block.spans.len() {
            let remaining_spans = block.spans.split_off(span_index + 1);
            new_block.spans.extend(remaining_spans);
        }

        self.blocks.insert(block_index + 1, new_block);
        Ok(())
    }
}

fn char_to_byte_offset(text: &str, char_offset: usize) -> Result<usize, String> {
    if char_offset == text.chars().count() {
        return Ok(text.len());
    }

    text.char_indices()
        .nth(char_offset)
        .map(|(byte_offset, _)| byte_offset)
        .ok_or_else(|| "Character offset out of bounds".to_string())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::block::{BlockType, InlineStyle};

    fn paragraph(text: &str) -> Block {
        let mut block = Block::new("block-1", BlockType::Paragraph);
        block.add_span(text, InlineStyle::default());
        block
    }

    #[test]
    fn insert_text_uses_character_offsets() {
        let mut doc = Document::new("Draft");
        doc.add_block(paragraph("cafe"));

        doc.insert_text(0, 0, 4, " ☕").unwrap();
        assert_eq!(doc.blocks[0].spans[0].text, "cafe ☕");

        doc.insert_text(0, 0, 4, " noir").unwrap();
        assert_eq!(doc.blocks[0].spans[0].text, "cafe noir ☕");
    }

    #[test]
    fn split_block_preserves_unicode_boundaries_and_remaining_spans() {
        let mut doc = Document::new("Draft");
        let mut block = paragraph("hello ☕ world");
        let mut bold = InlineStyle::default();
        bold.bold = true;
        block.add_span(" second", bold.clone());
        doc.add_block(block);

        doc.split_block(0, 0, 7).unwrap();

        assert_eq!(doc.blocks.len(), 2);
        assert_eq!(doc.blocks[0].spans[0].text, "hello ☕");
        assert_eq!(doc.blocks[1].spans[0].text, " world");
        assert_eq!(doc.blocks[1].spans[1].text, " second");
        assert_eq!(doc.blocks[1].spans[1].style, bold);
    }

    #[test]
    fn insert_text_rejects_out_of_bounds_character_offset() {
        let mut doc = Document::new("Draft");
        doc.add_block(paragraph("hi"));

        assert!(doc.insert_text(0, 0, 3, "!").is_err());
    }

    #[test]
    fn document_json_roundtrip() {
        let mut doc = Document::new("Draft");
        doc.add_block(paragraph("hello"));

        let json = doc.to_json().unwrap();
        let restored = Document::from_json(&json).unwrap();

        assert_eq!(restored.title, "Draft");
        assert_eq!(restored.blocks[0].spans[0].text, "hello");
    }
}
