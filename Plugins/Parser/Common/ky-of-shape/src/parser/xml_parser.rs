//! Shape XML parser for Office documents.
//!
//! This module provides streaming XML parsing capabilities for shape elements
//! in OOXML documents (DOCX, PPTX, XLSX).

use quick_xml::events::Event;
use quick_xml::Reader;
use std::io::BufRead;
use crate::models::{Shape, ShapeGeometry, ShapeType};
use crate::types::shape_type::ShapeType as ShapeTypeEnum;

/// Result type for shape parsing operations.
pub type ParseResult<T> = Result<T, ShapeParseError>;

/// Errors that can occur during shape parsing.
#[derive(Debug, Clone)]
pub enum ShapeParseError {
    /// Invalid XML structure.
    InvalidXml(String),
    /// Missing required attribute.
    MissingAttribute(String),
    /// Invalid attribute value.
    InvalidAttributeValue(String, String),
    /// Unsupported shape type.
    UnsupportedShapeType(String),
    /// IO error.
    IoError(String),
}

impl std::fmt::Display for ShapeParseError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            ShapeParseError::InvalidXml(msg) => write!(f, "Invalid XML: {}", msg),
            ShapeParseError::MissingAttribute(attr) => write!(f, "Missing attribute: {}", attr),
            ShapeParseError::InvalidAttributeValue(attr, val) => {
                write!(f, "Invalid value '{}' for attribute '{}'", val, attr)
            }
            ShapeParseError::UnsupportedShapeType(ty) => {
                write!(f, "Unsupported shape type: {}", ty)
            }
            ShapeParseError::IoError(msg) => write!(f, "IO error: {}", msg),
        }
    }
}

impl std::error::Error for ShapeParseError {}

/// Parses shapes from an XML reader.
///
/// This function reads through the XML stream and extracts all shape elements,
/// converting them into `Shape` structs.
pub fn parse_shapes<R: BufRead>(reader: &mut Reader<R>) -> ParseResult<Vec<Shape>> {
    let mut shapes = Vec::new();
    let mut buf = Vec::new();
    let mut current_shape_id_counter = 0u32;

    loop {
        match reader.read_event_into(&mut buf) {
            Ok(Event::Start(ref e)) | Ok(Event::Empty(ref e)) => {
                match e.name().as_ref() {
                    b"a:sp" | b"a:grpSp" | b"a:graphicFrame" | b"v:shape" | b"w:pict" => {
                        // Found a shape element, parse it
                        if let Some(shape) = parse_shape_element(reader, e, &mut current_shape_id_counter)? {
                            shapes.push(shape);
                        }
                    }
                    _ => {}
                }
            }
            Ok(Event::Eof) => break,
            Err(e) => return Err(ShapeParseError::InvalidXml(e.to_string())),
            _ => {}
        }
        buf.clear();
    }

    Ok(shapes)
}

/// Parses a single shape element.
fn parse_shape_element<R: BufRead>(
    reader: &mut Reader<R>,
    event: &quick_xml::events::BytesStart,
    id_counter: &mut u32,
) -> ParseResult<Option<Shape>> {
    let mut shape_type = ShapeTypeEnum::Rectangle; // Default
    let mut x = 0i64;
    let mut y = 0i64;
    let mut width = 100000i64; // Default 1 inch in EMUs
    let mut height = 100000i64;
    let mut id = format!("shape_{}", id_counter);
    let mut name: Option<String> = None;

    // Parse attributes
    for attr_result in event.attributes() {
        let attr = attr_result.map_err(|e| ShapeParseError::InvalidXml(e.to_string()))?;
        let key = std::str::from_utf8(attr.key.as_ref())
            .map_err(|e| ShapeParseError::InvalidXml(e.to_string()))?;
        let value = std::str::from_utf8(&attr.value)
            .map_err(|e| ShapeParseError::InvalidXml(e.to_string()))?;

        match key {
            "prstGeom" | "prst" => {
                shape_type = ShapeTypeEnum::from_ooxml_string(value);
            }
            "offX" | "x" => {
                x = value.parse().unwrap_or(0);
            }
            "offY" | "y" => {
                y = value.parse().unwrap_or(0);
            }
            "cx" | "width" => {
                width = value.parse().unwrap_or(100000);
            }
            "cy" | "height" => {
                height = value.parse().unwrap_or(100000);
            }
            "id" => {
                id = value.to_string();
            }
            "name" | "nvPrName" => {
                name = Some(value.to_string());
            }
            _ => {}
        }
    }

    *id_counter += 1;

    let mut shape = Shape::new(id, shape_type, x, y, width, height);
    if let Some(n) = name {
        shape = shape.with_name(n);
    }

    // Skip to end of this element for now
    // In a full implementation, we would recursively parse child elements
    // for text, fill, outline, effects, etc.
    skip_to_end_element(reader, event.name().as_ref())?;

    Ok(Some(shape))
}

/// Skips XML content until the matching end element is found.
fn skip_to_end_element<R: BufRead>(
    reader: &mut Reader<R>,
    start_name: &[u8],
) -> ParseResult<()> {
    let mut depth = 1;
    let mut buf = Vec::new();

    while depth > 0 {
        match reader.read_event_into(&mut buf) {
            Ok(Event::Start(ref e)) => {
                depth += 1;
            }
            Ok(Event::End(ref e)) => {
                if e.name().as_ref() == start_name {
                    depth -= 1;
                }
            }
            Ok(Event::Eof) => {
                return Err(ShapeParseError::InvalidXml(
                    "Unexpected end of file while skipping element".to_string(),
                ));
            }
            Err(e) => {
                return Err(ShapeParseError::InvalidXml(e.to_string()));
            }
            _ => {}
        }
        buf.clear();
    }

    Ok(())
}

/// Parses a shape from an XML string.
pub fn parse_shape_from_string(xml: &str) -> ParseResult<Option<Shape>> {
    let mut reader = Reader::from_str(xml);
    reader.trim_text(true);
    
    let mut id_counter = 0u32;
    let mut buf = Vec::new();

    loop {
        match reader.read_event_into(&mut buf) {
            Ok(Event::Start(ref e)) | Ok(Event::Empty(ref e)) => {
                match e.name().as_ref() {
                    b"a:sp" | b"a:grpSp" | b"a:graphicFrame" | b"v:shape" | b"w:pict" => {
                        return parse_shape_element(&mut reader, e, &mut id_counter);
                    }
                    _ => {}
                }
            }
            Ok(Event::Eof) => break,
            Err(e) => return Err(ShapeParseError::InvalidXml(e.to_string())),
            _ => {}
        }
        buf.clear();
    }

    Ok(None)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_simple_shape() {
        let xml = r#"<a:sp xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">
            <a:nvSpPr>
                <a:cNvPr id="1" name="Rectangle 1"/>
            </a:nvSpPr>
            <a:spPr>
                <a:xfrm>
                    <a:off x="100000" y="100000"/>
                    <a:ext cx="200000" cy="100000"/>
                </a:xfrm>
                <a:prstGeom prst="rect"/>
            </a:spPr>
        </a:sp>"#;

        let result = parse_shape_from_string(xml);
        assert!(result.is_ok());
        let shape_opt = result.unwrap();
        assert!(shape_opt.is_some());
        
        let shape = shape_opt.unwrap();
        assert_eq!(shape.shape_type, ShapeTypeEnum::Rectangle);
        assert_eq!(shape.geometry.x, 100000);
        assert_eq!(shape.geometry.y, 100000);
        assert_eq!(shape.geometry.width, 200000);
        assert_eq!(shape.geometry.height, 100000);
    }

    #[test]
    fn test_parse_ellipse() {
        let xml = r#"<a:sp xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">
            <a:spPr>
                <a:xfrm>
                    <a:off x="50000" y="75000"/>
                    <a:ext cx="150000" cy="100000"/>
                </a:xfrm>
                <a:prstGeom prst="ellipse"/>
            </a:spPr>
        </a:sp>"#;

        let result = parse_shape_from_string(xml);
        assert!(result.is_ok());
        let shape = result.unwrap().unwrap();
        assert_eq!(shape.shape_type, ShapeTypeEnum::Ellipse);
    }

    #[test]
    fn test_parse_arrow() {
        let xml = r#"<a:sp xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">
            <a:spPr>
                <a:prstGeom prst="rightArrow"/>
            </a:spPr>
        </a:sp>"#;

        let result = parse_shape_from_string(xml);
        assert!(result.is_ok());
        let shape = result.unwrap().unwrap();
        assert_eq!(shape.shape_type, ShapeTypeEnum::RightArrow);
    }

    #[test]
    fn test_empty_xml() {
        let xml = "";
        let result = parse_shape_from_string(xml);
        assert!(result.is_ok());
        assert!(result.unwrap().is_none());
    }
}
