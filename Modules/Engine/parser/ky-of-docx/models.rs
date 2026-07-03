use serde::{Deserialize, Serialize};

// ---------------------------------------------------------------------------
// Document-level
// ---------------------------------------------------------------------------

/// The complete parsed representation of a `.docx` document.
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct Document {
    /// Core document metadata (author, title, dates, …).
    pub metadata: Metadata,
    /// Ordered list of top-level block elements.
    pub body: Vec<Block>,
    /// Footnotes keyed by their numeric ID.
    pub footnotes: Vec<Footnote>,
    /// Endnotes keyed by their numeric ID.
    pub endnotes: Vec<Endnote>,
    /// Comments embedded in the document.
    pub comments: Vec<Comment>,
    /// Tracked insertions and deletions.
    pub tracked_changes: Vec<TrackedChange>,
    /// Embedded images (metadata only; bytes loaded on demand).
    pub images: Vec<ImageRef>,
    /// Named styles defined in the document.
    pub styles: Vec<StyleDef>,
    /// Per-section headers and footers.
    pub headers_footers: Vec<SectionHeaderFooter>,
}

// ---------------------------------------------------------------------------
// Metadata
// ---------------------------------------------------------------------------

/// Core document properties (from `docProps/core.xml`).
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
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
// Block elements
// ---------------------------------------------------------------------------

/// A top-level content block in the document body.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type")]
pub enum Block {
    Paragraph(Paragraph),
    Table(Table),
    /// A structural section break.
    SectionBreak,
}

/// A paragraph with its inline runs.
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct Paragraph {
    /// Resolved style name (e.g. `"Heading 1"`, `"Normal"`).
    pub style: Option<String>,
    /// Heading level 1–9 if this paragraph is a heading, else `None`.
    pub heading_level: Option<u8>,
    /// List information if this paragraph belongs to a list.
    pub list_info: Option<ListInfo>,
    /// Inline content runs.
    pub runs: Vec<Run>,
    /// Paragraph-level alignment.
    pub alignment: Option<Alignment>,
    /// Spacing before/after in twips.
    pub spacing_before: Option<i32>,
    pub spacing_after: Option<i32>,
    /// Indentation in twips.
    pub indent_left: Option<i32>,
    pub indent_right: Option<i32>,
    /// Style-level border.
    pub border: Option<ParagraphBorder>,
}

impl Paragraph {
    /// Collect all text from runs, concatenated.
    pub fn text(&self) -> String {
        self.runs.iter().map(|r| r.text()).collect()
    }

    /// `true` if this paragraph has no runs or all runs are whitespace.
    pub fn is_empty(&self) -> bool {
        self.runs.iter().all(|r| r.text().trim().is_empty())
    }
}

/// An inline text run with optional formatting.
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct Run {
    /// The text content (may be empty for pure formatting markers).
    pub text: String,
    /// Formatting applied to this run.
    pub formatting: RunFormatting,
    /// If this run is a hyperlink, contains the URL.
    pub hyperlink: Option<String>,
    /// If this run is a footnote reference, contains the footnote ID.
    pub footnote_ref: Option<String>,
    /// If this run is an endnote reference, contains the endnote ID.
    pub endnote_ref: Option<String>,
    /// If this run contains an inline image, the relationship ID.
    pub image_rel_id: Option<String>,
    /// If this run is a field code result (e.g. page number), the field text.
    pub field_text: Option<String>,
}

impl Run {
    pub fn text(&self) -> &str {
        &self.text
    }
}

/// Character formatting for a run.
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct RunFormatting {
    pub bold: bool,
    pub italic: bool,
    pub underline: bool,
    pub strikethrough: bool,
    pub superscript: bool,
    pub subscript: bool,
    pub small_caps: bool,
    pub all_caps: bool,
    pub highlight: Option<String>,
    pub color: Option<String>,
    /// Font size in half-points (divide by 2 for points).
    pub size: Option<u32>,
    pub font_ascii: Option<String>,
    pub font_east_asia: Option<String>,
    pub style: Option<String>,
    pub vertical_align: Option<VerticalAlign>,
}

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

// ---------------------------------------------------------------------------
// Lists
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ListInfo {
    /// Abstract numbering ID (used to group items into the same list).
    pub num_id: String,
    /// 0-based nesting level.
    pub level: u8,
    /// Whether the list uses ordered (numbered) or unordered (bulleted) style.
    pub list_type: ListType,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum ListType {
    Ordered,
    Unordered,
}

// ---------------------------------------------------------------------------
// Tables
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct Table {
    pub rows: Vec<TableRow>,
    /// Column widths in twips, if specified.
    pub column_widths: Vec<u32>,
    pub style: Option<String>,
}

impl Table {
    /// Number of rows.
    pub fn row_count(&self) -> usize {
        self.rows.len()
    }

    /// Number of columns (derived from the first row).
    pub fn col_count(&self) -> usize {
        self.rows.first().map_or(0, |r| r.cells.len())
    }

    /// Extract all text from the table as a 2-D vector `[row][col]`.
    pub fn to_text_grid(&self) -> Vec<Vec<String>> {
        self.rows
            .iter()
            .map(|r| r.cells.iter().map(|c| c.text()).collect())
            .collect()
    }
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct TableRow {
    pub cells: Vec<TableCell>,
    pub is_header: bool,
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct TableCell {
    pub paragraphs: Vec<Paragraph>,
    /// Column span.
    pub col_span: u32,
    /// Row span.
    pub row_span: u32,
    /// Width in twips.
    pub width: Option<u32>,
    pub background_color: Option<String>,
    pub vertical_align: Option<CellVerticalAlign>,
}

impl TableCell {
    /// Concatenate all paragraph text, separated by newlines.
    pub fn text(&self) -> String {
        self.paragraphs
            .iter()
            .map(|p| p.text())
            .collect::<Vec<_>>()
            .join("\n")
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum CellVerticalAlign {
    Top,
    Center,
    Bottom,
}

// ---------------------------------------------------------------------------
// Footnotes & Endnotes
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Footnote {
    pub id: String,
    pub paragraphs: Vec<Paragraph>,
}

impl Footnote {
    pub fn text(&self) -> String {
        self.paragraphs
            .iter()
            .map(|p| p.text())
            .collect::<Vec<_>>()
            .join("\n")
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Endnote {
    pub id: String,
    pub paragraphs: Vec<Paragraph>,
}

impl Endnote {
    pub fn text(&self) -> String {
        self.paragraphs
            .iter()
            .map(|p| p.text())
            .collect::<Vec<_>>()
            .join("\n")
    }
}

// ---------------------------------------------------------------------------
// Comments
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Comment {
    pub id: String,
    pub author: String,
    pub date: Option<String>,
    pub initials: Option<String>,
    pub paragraphs: Vec<Paragraph>,
    /// ID of the parent comment if this is a reply.
    pub parent_id: Option<String>,
}

impl Comment {
    pub fn text(&self) -> String {
        self.paragraphs
            .iter()
            .map(|p| p.text())
            .collect::<Vec<_>>()
            .join("\n")
    }
}

// ---------------------------------------------------------------------------
// Tracked changes
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TrackedChange {
    pub id: String,
    pub change_type: ChangeType,
    pub author: String,
    pub date: Option<String>,
    pub text: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum ChangeType {
    Insertion,
    Deletion,
    FormatChange,
}

// ---------------------------------------------------------------------------
// Images
// ---------------------------------------------------------------------------

/// Lightweight reference to an embedded image (no raw bytes).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ImageRef {
    /// Relationship ID (e.g. `"rId5"`).
    pub rel_id: String,
    /// Target path inside the archive (e.g. `"word/media/image1.png"`).
    pub target: String,
    /// MIME type (e.g. `"image/png"`).
    pub content_type: String,
    /// Display width in EMUs (English Metric Units; 914400 = 1 inch).
    pub width_emu: Option<i64>,
    /// Display height in EMUs.
    pub height_emu: Option<i64>,
    /// Alt-text / description, if provided.
    pub description: Option<String>,
}

impl ImageRef {
    /// Width in inches (approximate).
    pub fn width_inches(&self) -> Option<f64> {
        self.width_emu.map(|w| w as f64 / 914400.0)
    }
    /// Height in inches (approximate).
    pub fn height_inches(&self) -> Option<f64> {
        self.height_emu.map(|h| h as f64 / 914400.0)
    }
    /// File extension derived from the target path.
    pub fn extension(&self) -> &str {
        self.target.rsplit('.').next().unwrap_or("bin")
    }
}
/// Representation of a chart embedded in a Word document.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Chart {
    /// Relationship ID linking to the chart XML.
    pub rel_id: String,
    /// Target path inside the archive (e.g., "word/charts/chart1.xml").
    pub target: String,
    /// Optional title of the chart.
    pub title: Option<String>,
}
/// Representation of an embedded OLE object.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EmbeddedObject {
    /// Relationship ID linking to the binary data.
    pub rel_id: String,
    /// Target path inside the archive.
    pub target: String,
    /// Optional description.
    pub description: Option<String>,
}
/// Representation of a diagram embedded in a Word document.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Diagram {
    /// Relationship ID linking to the diagram XML.
    pub rel_id: String,
    /// Target path inside the archive.
    pub target: String,
    /// Optional title of the diagram.
    pub title: Option<String>,
}

// ---------------------------------------------------------------------------
// Styles
// ---------------------------------------------------------------------------

/// A named style as defined in `word/styles.xml`.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StyleDef {
    pub id: String,
    pub name: String,
    pub style_type: StyleType,
    pub based_on: Option<String>,
    pub next_style: Option<String>,
    pub paragraph_formatting: Option<ParagraphFormatting>,
    pub run_formatting: Option<RunFormatting>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum StyleType {
    Paragraph,
    Character,
    Table,
    Numbering,
    Unknown,
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct ParagraphFormatting {
    pub alignment: Option<Alignment>,
    pub spacing_before: Option<i32>,
    pub spacing_after: Option<i32>,
    pub line_spacing: Option<i32>,
    pub outline_level: Option<u8>,
    pub indent_left: Option<i32>,
    pub indent_right: Option<i32>,
    pub indent_hanging: Option<i32>,
    pub keep_lines: bool,
    pub keep_next: bool,
    pub page_break_before: bool,
}

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

// ---------------------------------------------------------------------------
// Extraction options
// ---------------------------------------------------------------------------

/// Options controlling what `DocxReader::extract_text` returns.
#[derive(Debug, Clone)]
pub struct TextOptions {
    /// Include header text.
    pub include_headers: bool,
    /// Include footer text.
    pub include_footers: bool,
    /// Include footnotes inline after the paragraph that references them.
    pub include_footnotes: bool,
    /// Include endnotes at the end.
    pub include_endnotes: bool,
    /// Include comment text.
    pub include_comments: bool,
    /// Include deleted text from tracked changes (default: false).
    pub include_deletions: bool,
    /// Separator inserted between paragraphs.
    pub paragraph_separator: String,
    /// Separator inserted between table cells.
    pub table_cell_separator: String,
    /// Separator between table rows.
    pub table_row_separator: String,
}

impl Default for TextOptions {
    fn default() -> Self {
        Self {
            include_headers: false,
            include_footers: false,
            include_footnotes: true,
            include_endnotes: true,
            include_comments: false,
            include_deletions: false,
            paragraph_separator: "\n".into(),
            table_cell_separator: "\t".into(),
            table_row_separator: "\n".into(),
        }
    }
}

impl TextOptions {
    pub fn all() -> Self {
        Self {
            include_headers: true,
            include_footers: true,
            include_footnotes: true,
            include_endnotes: true,
            include_comments: true,
            include_deletions: false,
            paragraph_separator: "\n".into(),
            table_cell_separator: "\t".into(),
            table_row_separator: "\n".into(),
        }
    }
}
