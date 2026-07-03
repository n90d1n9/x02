use crate::edit::EditOp;
use crate::types::Range;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct TextChange {
    pub replaced: Range,
    pub inserted: String,
    pub deleted: String,
    pub byte_delta: i64,
    pub first_line: usize,
    pub last_line: usize,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum TextBufferError {
    InvalidRange {
        start: usize,
        end: usize,
        len: usize,
    },
    InvalidBoundary {
        index: usize,
    },
}

pub type TextBufferResult<T> = Result<T, TextBufferError>;

#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct TextBuffer {
    text: String,
}

impl TextBuffer {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn from_text(text: impl Into<String>) -> Self {
        Self { text: text.into() }
    }

    pub fn as_str(&self) -> &str {
        &self.text
    }

    pub fn into_string(self) -> String {
        self.text
    }

    pub fn len(&self) -> usize {
        self.text.len()
    }

    pub fn is_empty(&self) -> bool {
        self.text.is_empty()
    }

    pub fn apply(&mut self, op: EditOp) -> TextBufferResult<TextChange> {
        match op {
            EditOp::Insert { at, text } => self.insert(at, &text),
            EditOp::Delete { range } => self.delete(range),
            EditOp::Replace { range, text } => self.replace(range, &text),
        }
    }

    pub fn insert(&mut self, at: usize, text: &str) -> TextBufferResult<TextChange> {
        self.validate_index(at)?;

        let first_line = self.line_at(at);
        self.text.insert_str(at, text);

        Ok(TextChange {
            replaced: Range::new(at, at),
            inserted: text.to_owned(),
            deleted: String::new(),
            byte_delta: text.len() as i64,
            first_line,
            last_line: first_line + text.bytes().filter(|byte| *byte == b'\n').count(),
        })
    }

    pub fn delete(&mut self, range: Range) -> TextBufferResult<TextChange> {
        self.validate_range(range)?;

        let first_line = self.line_at(range.start);
        let last_line = self.line_at(range.end);
        let deleted = self.text[range.start..range.end].to_owned();
        self.text.replace_range(range.start..range.end, "");

        Ok(TextChange {
            replaced: range,
            inserted: String::new(),
            byte_delta: -(deleted.len() as i64),
            deleted,
            first_line,
            last_line,
        })
    }

    pub fn replace(&mut self, range: Range, text: &str) -> TextBufferResult<TextChange> {
        self.validate_range(range)?;

        let first_line = self.line_at(range.start);
        let last_line = self.line_at(range.end);
        let deleted = self.text[range.start..range.end].to_owned();
        self.text.replace_range(range.start..range.end, text);

        Ok(TextChange {
            replaced: range,
            inserted: text.to_owned(),
            byte_delta: text.len() as i64 - deleted.len() as i64,
            deleted,
            first_line,
            last_line,
        })
    }

    fn validate_index(&self, index: usize) -> TextBufferResult<()> {
        if index > self.text.len() {
            return Err(TextBufferError::InvalidRange {
                start: index,
                end: index,
                len: self.text.len(),
            });
        }

        if !self.text.is_char_boundary(index) {
            return Err(TextBufferError::InvalidBoundary { index });
        }

        Ok(())
    }

    fn validate_range(&self, range: Range) -> TextBufferResult<()> {
        if range.start > range.end || range.end > self.text.len() {
            return Err(TextBufferError::InvalidRange {
                start: range.start,
                end: range.end,
                len: self.text.len(),
            });
        }

        self.validate_index(range.start)?;
        self.validate_index(range.end)?;
        Ok(())
    }

    fn line_at(&self, index: usize) -> usize {
        self.text[..index]
            .bytes()
            .filter(|byte| *byte == b'\n')
            .count()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn applies_insert_delete_and_replace_edits() {
        let mut buffer = TextBuffer::from_text("Hello team");

        let insert = buffer.apply(EditOp::insert(5, ",")).unwrap();
        assert_eq!(buffer.as_str(), "Hello, team");
        assert_eq!(insert.inserted, ",");
        assert_eq!(insert.deleted, "");
        assert_eq!(insert.replaced, Range::new(5, 5));
        assert_eq!(insert.byte_delta, 1);

        let delete = buffer.apply(EditOp::delete(5, 6)).unwrap();
        assert_eq!(buffer.as_str(), "Hello team");
        assert_eq!(delete.deleted, ",");
        assert_eq!(delete.byte_delta, -1);

        let replace = buffer.apply(EditOp::replace(6, 10, "office")).unwrap();
        assert_eq!(buffer.as_str(), "Hello office");
        assert_eq!(replace.deleted, "team");
        assert_eq!(replace.inserted, "office");
        assert_eq!(replace.byte_delta, 2);
    }

    #[test]
    fn rejects_out_of_bounds_ranges() {
        let mut buffer = TextBuffer::from_text("abc");

        assert_eq!(
            buffer.apply(EditOp::delete(2, 4)),
            Err(TextBufferError::InvalidRange {
                start: 2,
                end: 4,
                len: 3
            })
        );
        assert_eq!(
            buffer.apply(EditOp::replace(3, 1, "x")),
            Err(TextBufferError::InvalidRange {
                start: 3,
                end: 1,
                len: 3
            })
        );
    }

    #[test]
    fn rejects_non_char_boundary_edits() {
        let mut buffer = TextBuffer::from_text("éclair");

        assert_eq!(
            buffer.apply(EditOp::insert(1, "x")),
            Err(TextBufferError::InvalidBoundary { index: 1 })
        );
    }

    #[test]
    fn tracks_line_span_for_multiline_edits() {
        let mut buffer = TextBuffer::from_text("a\nb\nc");

        let change = buffer.apply(EditOp::replace(2, 3, "B\nB2")).unwrap();

        assert_eq!(buffer.as_str(), "a\nB\nB2\nc");
        assert_eq!(change.first_line, 1);
        assert_eq!(change.last_line, 1);
        assert_eq!(change.deleted, "b");
    }
}
