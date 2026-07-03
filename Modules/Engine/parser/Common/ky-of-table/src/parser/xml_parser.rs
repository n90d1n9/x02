//! XML parser for table structures in OOXML formats (DOCX, XLSX, PPTX).

#[cfg(feature = "parser")]
use quick_xml::events::Event;
#[cfg(feature = "parser")]
use quick_xml::Reader;
#[cfg(feature = "parser")]
use std::io::BufRead;
use crate::models::table::{Table, TableRow, TableCell, CellContent, TableDimensions};
use crate::types::table_type::TableType;

/// Parser for extracting table data from XML streams.
#[cfg(feature = "parser")]
pub struct TableParser {
    reader: Reader<Vec<u8>>,
}

#[cfg(feature = "parser")]
impl TableParser {
    /// Create a new table parser from XML data.
    pub fn new(xml_data: &[u8]) -> Self {
        let mut reader = Reader::from_reader(xml_data);
        reader.trim_text(true);
        TableParser { reader }
    }

    /// Parse all tables from the XML stream.
    pub fn parse_tables(&mut self) -> Result<Vec<Table>, TableParseError> {
        let mut tables = Vec::new();
        let mut buf = Vec::new();
        let mut in_table = false;
        let mut current_table_builder = TableBuilder::default();

        loop {
            match self.reader.read_event_into(&mut buf) {
                Ok(Event::Start(ref e)) => {
                    match e.name().as_ref() {
                        b"table" | b"w:tbl" | b"x:table" => {
                            in_table = true;
                            current_table_builder = TableBuilder::default();
                            for attr in e.attributes().flatten() {
                                if attr.key.as_ref() == b"id" || attr.key.as_ref() == b"w:id" {
                                    current_table_builder.id = String::from_utf8_lossy(&attr.value).to_string();
                                }
                            }
                        }
                        b"tr" | b"x:row" if in_table => {
                            current_table_builder.start_row();
                        }
                        b"tc" | b"x:cell" if in_table => {
                            current_table_builder.start_cell();
                        }
                        b"p" | b"si" if in_table => {
                            current_table_builder.start_text();
                        }
                        _ => {}
                    }
                }
                Ok(Event::End(ref e)) => {
                    match e.name().as_ref() {
                        b"table" | b"w:tbl" | b"x:table" => {
                            in_table = false;
                            if let Some(table) = current_table_builder.build() {
                                tables.push(table);
                            }
                        }
                        b"tr" | b"x:row" if in_table => {
                            current_table_builder.end_row();
                        }
                        b"tc" | b"x:cell" if in_table => {
                            current_table_builder.end_cell();
                        }
                        b"p" | b"si" if in_table => {
                            current_table_builder.end_text();
                        }
                        _ => {}
                    }
                }
                Ok(Event::Text(ref e)) if in_table => {
                    let text = String::from_utf8_lossy(e).to_string();
                    current_table_builder.add_text(&text);
                }
                Ok(Event::Eof) => break,
                Err(e) => return Err(TableParseError::XmlError(e.to_string())),
                _ => {}
            }
            buf.clear();
        }

        Ok(tables)
    }
}

#[derive(Default)]
struct TableBuilder {
    id: String,
    rows: Vec<TableRow>,
    current_row_index: usize,
    current_cell_index: usize,
    current_text: String,
    in_cell: bool,
}

#[cfg(feature = "parser")]
impl TableBuilder {
    fn start_row(&mut self) {
        self.current_cell_index = 0;
    }

    fn end_row(&mut self) {
        // Row is already added via cells
    }

    fn start_cell(&mut self) {
        self.in_cell = true;
        self.current_text.clear();
    }

    fn end_cell(&mut self) {
        self.in_cell = false;
        
        let content = if self.current_text.trim().is_empty() {
            CellContent::Empty
        } else {
            CellContent::Text(ky_of_text::RichText::from(self.current_text.clone()))
        };

        let cell = TableCell {
            column_index: self.current_cell_index,
            content,
            merge: None,
            style: None,
            validation: None,
            formula: None,
        };

        while self.rows.len() <= self.current_row_index {
            self.rows.push(TableRow {
                index: self.rows.len(),
                cells: Vec::new(),
                height: None,
                is_header: false,
                is_total: false,
                style: None,
            });
        }

        self.rows[self.current_row_index].cells.push(cell);
        self.current_cell_index += 1;
    }

    fn start_text(&mut self) {
        self.current_text.clear();
    }

    fn end_text(&mut self) {
        // Text accumulation happens in Event::Text
    }

    fn add_text(&mut self, text: &str) {
        if self.in_cell {
            self.current_text.push_str(text);
        }
    }

    fn build(mut self) -> Option<Table> {
        if self.rows.is_empty() {
            return None;
        }

        let row_count = self.rows.len();
        let column_count = self.rows.iter().map(|r| r.cells.len()).max().unwrap_or(0);

        Some(Table {
            id: self.id,
            name: None,
            table_type: TableType::Grid,
            header_position: crate::types::table_type::HeaderRowPosition::Top,
            dimensions: TableDimensions { row_count, column_count },
            rows: self.rows,
            style: None,
            alt_text: None,
            has_total_row: false,
        })
    }
}

/// Errors that can occur during table parsing.
#[derive(Debug, Clone)]
pub enum TableParseError {
    XmlError(String),
    InvalidStructure(String),
    MissingRequiredField(String),
}

impl std::fmt::Display for TableParseError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            TableParseError::XmlError(e) => write!(f, "XML parsing error: {}", e),
            TableParseError::InvalidStructure(e) => write!(f, "Invalid table structure: {}", e),
            TableParseError::MissingRequiredField(e) => write!(f, "Missing required field: {}", e),
        }
    }
}

impl std::error::Error for TableParseError {}

#[cfg(all(test, feature = "parser"))]
mod tests {
    use super::*;

    #[test]
    fn test_parse_simple_table() {
        let xml = r#"<?xml version="1.0"?>
<table id="table1">
    <tr><tc><p>Hello</p></tc><tc><p>World</p></tc></tr>
    <tr><tc><p>Foo</p></tc><tc><p>Bar</p></tc></tr>
</table>"#;

        let mut parser = TableParser::new(xml.as_bytes());
        let tables = parser.parse_tables().unwrap();
        
        assert_eq!(tables.len(), 1);
        assert_eq!(tables[0].id, "table1");
        assert_eq!(tables[0].rows.len(), 2);
        assert_eq!(tables[0].rows[0].cells.len(), 2);
    }
}
