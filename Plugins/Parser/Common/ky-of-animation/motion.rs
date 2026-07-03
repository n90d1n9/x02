// src/core/motion.rs
//
// Motion engine — computes target offsets for all cursor movements.
//
// Separating motion logic from cursor state means:
//   • Easy to test (pure functions, no side effects)
//   • Easy to reuse for keyboard shortcuts, find-next, selection expansion
//   • Each motion is a ByteOffset → ByteOffset function given a Buffer
//
// Motion taxonomy:
//   Character   — left/right by 1 char (Unicode scalar, not byte)
//   Word        — forward/backward to word boundary (alphanumeric + _)
//   Word-end    — forward to end of current/next word
//   WORD        — like word but delimited only by whitespace (vi W/B/E)
//   Line        — start/end of line, up/down by N lines
//   Paragraph   — blank-line delimited blocks
//   Page        — viewport-sized jumps
//   Bracket     — jump to matching bracket ( ) [ ] { }
//   Document    — start/end of document

use crate::core::buffer::Buffer;
use crate::core::types::ByteOffset;

// ── Character motion ──────────────────────────────────────────────────────────

/// Move one Unicode scalar value to the right (never past end of document).
pub fn char_right(buf: &Buffer, pos: ByteOffset) -> ByteOffset {
    let text = buf.to_string();
    let bytes = text.as_bytes();
    if pos.0 >= bytes.len() {
        return pos;
    }
    // Skip forward past a full UTF-8 sequence
    let mut i = pos.0 + 1;
    while i < bytes.len() && (bytes[i] & 0xC0) == 0x80 {
        i += 1;
    }
    ByteOffset(i)
}

/// Move one Unicode scalar value to the left (never past start).
pub fn char_left(buf: &Buffer, pos: ByteOffset) -> ByteOffset {
    if pos.0 == 0 {
        return pos;
    }
    let text = buf.to_string();
    let bytes = text.as_bytes();
    let mut i = pos.0 - 1;
    while i > 0 && (bytes[i] & 0xC0) == 0x80 {
        i -= 1;
    }
    ByteOffset(i)
}

// ── Word motion ───────────────────────────────────────────────────────────────

/// Classify a character for word boundary purposes.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum CharClass {
    Word,        // alphanumeric, _
    Whitespace,  // space, tab, newline
    Punctuation, // everything else
}

fn char_class(c: char) -> CharClass {
    if c.is_alphanumeric() || c == '_' {
        CharClass::Word
    } else if c.is_whitespace() {
        CharClass::Whitespace
    } else {
        CharClass::Punctuation
    }
}

/// Move forward to start of next word (like vi `w`).
pub fn word_forward(buf: &Buffer, pos: ByteOffset) -> ByteOffset {
    let text = buf.to_string();
    let mut chars = text[pos.0..].char_indices().peekable();

    // Skip current word/punct
    let start_class = chars
        .peek()
        .map(|(_, c)| char_class(*c))
        .unwrap_or(CharClass::Whitespace);

    if start_class != CharClass::Whitespace {
        for (_, c) in chars.by_ref() {
            if char_class(c) != start_class {
                break;
            }
        }
    }
    // Skip whitespace
    // Re-anchor
    let remainder_start = text[pos.0..]
        .char_indices()
        .skip_while(|(_, c)| char_class(*c) == start_class)
        .find(|(_, c)| char_class(*c) != CharClass::Whitespace)
        .map(|(i, _)| pos.0 + i)
        .unwrap_or(buf.len_bytes());

    ByteOffset(remainder_start)
}

/// Move backward to start of previous word (like vi `b`).
pub fn word_backward(buf: &Buffer, pos: ByteOffset) -> ByteOffset {
    if pos.0 == 0 {
        return pos;
    }
    let text = buf.to_string();
    let prefix = &text[..pos.0];

    // Walk backwards as chars
    let chars: Vec<(usize, char)> = prefix.char_indices().collect();
    if chars.is_empty() {
        return ByteOffset(0);
    }

    let mut i = chars.len().saturating_sub(1);

    // Skip whitespace going left
    while i > 0 && char_class(chars[i].1) == CharClass::Whitespace {
        i -= 1;
    }
    if char_class(chars[i].1) == CharClass::Whitespace {
        return ByteOffset(0);
    }

    let target_class = char_class(chars[i].1);
    // Skip word/punct going left
    while i > 0 && char_class(chars[i - 1].1) == target_class {
        i -= 1;
    }

    ByteOffset(chars[i].0)
}

/// Move forward to end of current/next word (like vi `e`).
pub fn word_end_forward(buf: &Buffer, pos: ByteOffset) -> ByteOffset {
    let text = buf.to_string();
    let suffix = &text[pos.0..];
    let chars: Vec<(usize, char)> = suffix.char_indices().collect();
    if chars.len() < 2 {
        return ByteOffset(buf.len_bytes());
    }

    let mut i = 1; // skip current position

    // Skip whitespace
    while i < chars.len() && char_class(chars[i].1) == CharClass::Whitespace {
        i += 1;
    }
    if i >= chars.len() {
        return ByteOffset(buf.len_bytes());
    }

    let target_class = char_class(chars[i].1);
    // Advance through the word
    while i + 1 < chars.len() && char_class(chars[i + 1].1) == target_class {
        i += 1;
    }

    ByteOffset(pos.0 + chars[i].0 + chars[i].1.len_utf8())
}

// ── WORD motion (whitespace-delimited, like vi W/B) ───────────────────────────

/// Move forward past whitespace to start of next WORD.
pub fn big_word_forward(buf: &Buffer, pos: ByteOffset) -> ByteOffset {
    let text = buf.to_string();
    let suffix = &text[pos.0..];
    // Skip non-whitespace
    let after_word: usize = suffix
        .char_indices()
        .skip_while(|(_, c)| !c.is_whitespace())
        .next()
        .map(|(i, _)| i)
        .unwrap_or(suffix.len());
    // Skip whitespace
    let next_word: usize = suffix[after_word..]
        .char_indices()
        .skip_while(|(_, c)| c.is_whitespace())
        .next()
        .map(|(i, _)| after_word + i)
        .unwrap_or(suffix.len());
    ByteOffset(pos.0 + next_word)
}

/// Move backward to start of previous WORD.
pub fn big_word_backward(buf: &Buffer, pos: ByteOffset) -> ByteOffset {
    if pos.0 == 0 {
        return pos;
    }
    let text = buf.to_string();
    let prefix = &text[..pos.0];
    let chars: Vec<(usize, char)> = prefix.char_indices().collect();
    if chars.is_empty() {
        return ByteOffset(0);
    }

    let mut i = chars.len().saturating_sub(1);
    // Skip whitespace going left
    while i > 0 && chars[i].1.is_whitespace() {
        i -= 1;
    }
    if chars[i].1.is_whitespace() {
        return ByteOffset(0);
    }
    // Skip non-whitespace going left
    while i > 0 && !chars[i - 1].1.is_whitespace() {
        i -= 1;
    }
    ByteOffset(chars[i].0)
}

// ── Line motion ───────────────────────────────────────────────────────────────

/// Move to the byte offset of the start of `line` (0-based).
pub fn line_start(buf: &Buffer, line: usize) -> ByteOffset {
    buf.line_col_to_offset(crate::core::types::LineCol::new(line, 0))
}

/// Move to byte offset of the first non-whitespace character on `line`.
pub fn line_first_nonwhitespace(buf: &Buffer, line: usize) -> ByteOffset {
    let text = buf.line_str(line);
    let col = text.chars().take_while(|c| *c == ' ' || *c == '\t').count();
    buf.line_col_to_offset(crate::core::types::LineCol::new(line, col))
}

/// Move to byte offset of the last character on `line` (before newline).
pub fn line_end(buf: &Buffer, line: usize) -> ByteOffset {
    let text = buf.line_str(line);
    let col = text.chars().count();
    buf.line_col_to_offset(crate::core::types::LineCol::new(line, col))
}

// ── Paragraph motion ──────────────────────────────────────────────────────────

/// Move to the start of the next paragraph (blank-line delimited).
pub fn paragraph_forward(buf: &Buffer, pos: ByteOffset) -> ByteOffset {
    let lc = buf.offset_to_line_col(pos);
    let total = buf.len_lines();
    let mut line = lc.line;

    // Skip non-blank lines
    while line < total && !buf.line_str(line).trim().is_empty() {
        line += 1;
    }
    // Skip blank lines
    while line < total && buf.line_str(line).trim().is_empty() {
        line += 1;
    }

    if line >= total {
        return ByteOffset(buf.len_bytes());
    }
    line_start(buf, line)
}

/// Move to the start of the previous paragraph.
pub fn paragraph_backward(buf: &Buffer, pos: ByteOffset) -> ByteOffset {
    let lc = buf.offset_to_line_col(pos);
    if lc.line == 0 {
        return ByteOffset(0);
    }
    let mut line = lc.line.saturating_sub(1);

    // Skip blank lines going up
    while line > 0 && buf.line_str(line).trim().is_empty() {
        line -= 1;
    }
    // Skip non-blank lines going up
    while line > 0 && !buf.line_str(line.saturating_sub(1)).trim().is_empty() {
        line -= 1;
    }

    line_start(buf, line)
}

// ── Bracket matching ──────────────────────────────────────────────────────────

const OPEN_BRACKETS: &[char] = &['(', '[', '{', '<'];
const CLOSE_BRACKETS: &[char] = &[')', ']', '}', '>'];

fn matching_close(open: char) -> Option<char> {
    OPEN_BRACKETS
        .iter()
        .zip(CLOSE_BRACKETS.iter())
        .find(|(&o, _)| o == open)
        .map(|(_, &c)| c)
}

fn matching_open(close: char) -> Option<char> {
    CLOSE_BRACKETS
        .iter()
        .zip(OPEN_BRACKETS.iter())
        .find(|(&c, _)| c == close)
        .map(|(_, &o)| o)
}

/// Jump to the matching bracket. Works on `()`, `[]`, `{}`, `<>`.
/// Returns `None` if the character at `pos` is not a bracket, or no match found.
pub fn matching_bracket(buf: &Buffer, pos: ByteOffset) -> Option<ByteOffset> {
    let text = buf.to_string();
    let chars: Vec<(usize, char)> = text.char_indices().collect();

    // Find the char at pos
    let idx = chars.iter().position(|(byte_pos, _)| *byte_pos == pos.0)?;
    let ch = chars[idx].1;

    if let Some(close) = matching_close(ch) {
        // Search forward
        let mut depth = 0i32;
        for (byte_pos, c) in &chars[idx..] {
            if *c == ch {
                depth += 1;
            }
            if *c == close {
                depth -= 1;
            }
            if depth == 0 {
                return Some(ByteOffset(*byte_pos));
            }
        }
    } else if let Some(open) = matching_open(ch) {
        // Search backward
        let mut depth = 0i32;
        for (byte_pos, c) in chars[..=idx].iter().rev() {
            if *c == ch {
                depth += 1;
            }
            if *c == open {
                depth -= 1;
            }
            if depth == 0 {
                return Some(ByteOffset(*byte_pos));
            }
        }
    }
    None
}

// ── Document motion ───────────────────────────────────────────────────────────

pub fn document_start() -> ByteOffset {
    ByteOffset(0)
}
pub fn document_end(buf: &Buffer) -> ByteOffset {
    ByteOffset(buf.len_bytes())
}

// ── Page motion ───────────────────────────────────────────────────────────────

/// Move up/down by `page_lines` lines (viewport page jump).
pub fn page_up(buf: &Buffer, pos: ByteOffset, page_lines: usize) -> ByteOffset {
    let lc = buf.offset_to_line_col(pos);
    let new_line = lc.line.saturating_sub(page_lines);
    line_start(buf, new_line)
}

pub fn page_down(buf: &Buffer, pos: ByteOffset, page_lines: usize) -> ByteOffset {
    let lc = buf.offset_to_line_col(pos);
    let new_line = (lc.line + page_lines).min(buf.len_lines().saturating_sub(1));
    line_start(buf, new_line)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::core::buffer::Buffer;

    fn buf(s: &str) -> Buffer {
        Buffer::from_str(s)
    }

    // ── Character ─────────────────────────────────────────────────────────────

    #[test]
    fn test_char_right_ascii() {
        let b = buf("hello");
        assert_eq!(char_right(&b, ByteOffset(0)).0, 1);
        assert_eq!(char_right(&b, ByteOffset(4)).0, 5);
        // At end — clamped
        assert_eq!(char_right(&b, ByteOffset(5)).0, 5);
    }

    #[test]
    fn test_char_left_ascii() {
        let b = buf("hello");
        assert_eq!(char_left(&b, ByteOffset(3)).0, 2);
        // At start — clamped
        assert_eq!(char_left(&b, ByteOffset(0)).0, 0);
    }

    #[test]
    fn test_char_right_multibyte() {
        // "é" = 2 bytes (0xC3 0xA9)
        let b = buf("café");
        // 'c'=0, 'a'=1, 'f'=2, 'é'=3-4, end=5
        let pos = char_right(&b, ByteOffset(2)); // after 'f'
        assert_eq!(pos.0, 3); // start of 'é'
        let pos2 = char_right(&b, ByteOffset(3)); // after 'é'
        assert_eq!(pos2.0, 5); // past the 2-byte 'é'
    }

    #[test]
    fn test_char_left_multibyte() {
        let b = buf("café");
        // 'é' starts at byte 3
        let pos = char_left(&b, ByteOffset(5));
        assert_eq!(pos.0, 3); // back to start of 'é'
    }

    // ── Word ──────────────────────────────────────────────────────────────────

    #[test]
    fn test_word_forward_basic() {
        let b = buf("hello world foo");
        let p = word_forward(&b, ByteOffset(0));
        assert_eq!(&b.to_string()[p.0..p.0 + 5], "world");
    }

    #[test]
    fn test_word_backward_basic() {
        let b = buf("hello world");
        let p = word_backward(&b, ByteOffset(11)); // at end
        assert_eq!(&b.to_string()[p.0..], "world");
    }

    #[test]
    fn test_word_end_forward() {
        let b = buf("hello world");
        let p = word_end_forward(&b, ByteOffset(0));
        // Should land at end of "hello" = byte 5
        assert_eq!(p.0, 5);
    }

    #[test]
    fn test_word_forward_at_end() {
        let b = buf("hello");
        let p = word_forward(&b, ByteOffset(0));
        assert_eq!(p.0, 5); // end of document
    }

    // ── Line ──────────────────────────────────────────────────────────────────

    #[test]
    fn test_line_start() {
        let b = buf("hello\nworld\n");
        assert_eq!(line_start(&b, 0).0, 0);
        assert_eq!(line_start(&b, 1).0, 6); // 'w' in "world"
    }

    #[test]
    fn test_line_first_nonwhitespace() {
        let b = buf("hello\n    world\n");
        assert_eq!(line_first_nonwhitespace(&b, 0).0, 0); // no indent
        assert_eq!(line_first_nonwhitespace(&b, 1).0, 10); // 4 spaces + newline
    }

    #[test]
    fn test_line_end() {
        let b = buf("hello\nworld\n");
        let e = line_end(&b, 0);
        // "hello" = 5 chars, line_end returns offset past last char
        assert_eq!(e.0, 5);
    }

    // ── Paragraph ─────────────────────────────────────────────────────────────

    #[test]
    fn test_paragraph_forward() {
        let b = buf("line1\nline2\n\nline3\nline4\n");
        let p = paragraph_forward(&b, ByteOffset(0));
        // Should jump to line3 (after the blank line)
        assert_eq!(b.offset_to_line_col(p).line, 3);
    }

    #[test]
    fn test_paragraph_backward() {
        let b = buf("line1\nline2\n\nline3\nline4\n");
        let p = paragraph_backward(&b, ByteOffset(20)); // somewhere in line4
                                                        // Should jump to line3 (start of paragraph)
        let line = b.offset_to_line_col(p).line;
        assert!(line <= 3);
    }

    // ── Bracket matching ──────────────────────────────────────────────────────

    #[test]
    fn test_bracket_match_forward() {
        let b = buf("fn foo(a, b) {}");
        // '(' is at byte 6
        let m = matching_bracket(&b, ByteOffset(6));
        assert!(m.is_some());
        let matched = m.unwrap();
        assert_eq!(&b.to_string()[matched.0..matched.0 + 1], ")");
    }

    #[test]
    fn test_bracket_match_backward() {
        let b = buf("fn foo(a, b) {}");
        // ')' is at byte 11
        let m = matching_bracket(&b, ByteOffset(11));
        assert!(m.is_some());
        let matched = m.unwrap();
        assert_eq!(&b.to_string()[matched.0..matched.0 + 1], "(");
    }

    #[test]
    fn test_bracket_match_nested() {
        let b = buf("((a + (b * c)))");
        // outer '(' at byte 0
        let m = matching_bracket(&b, ByteOffset(0)).unwrap();
        // Should match the last ')'
        assert_eq!(m.0, 14);
    }

    #[test]
    fn test_bracket_no_match() {
        let b = buf("hello world");
        let m = matching_bracket(&b, ByteOffset(0));
        assert!(m.is_none()); // 'h' is not a bracket
    }

    #[test]
    fn test_bracket_curly() {
        let b = buf("fn main() {\n    return 1;\n}");
        // '{' is at byte 10
        let m = matching_bracket(&b, ByteOffset(10)).unwrap();
        assert_eq!(&b.to_string()[m.0..m.0 + 1], "}");
    }

    // ── Page ──────────────────────────────────────────────────────────────────

    #[test]
    fn test_page_down() {
        let content: String = (0..100).map(|i| format!("line {}\n", i)).collect();
        let b = Buffer::from_str(&content);
        let p = page_down(&b, ByteOffset(0), 20);
        let lc = b.offset_to_line_col(p);
        assert_eq!(lc.line, 20);
    }

    #[test]
    fn test_page_up() {
        let content: String = (0..100).map(|i| format!("line {}\n", i)).collect();
        let b = Buffer::from_str(&content);
        let start = line_start(&b, 50);
        let p = page_up(&b, start, 20);
        let lc = b.offset_to_line_col(p);
        assert_eq!(lc.line, 30);
    }

    #[test]
    fn test_page_up_clamps_at_start() {
        let b = buf("hello\nworld\n");
        let p = page_up(&b, ByteOffset(0), 50);
        assert_eq!(p.0, 0);
    }
}
