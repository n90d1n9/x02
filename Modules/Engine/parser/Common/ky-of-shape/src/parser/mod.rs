//! Shape parser implementations.

pub mod xml_parser;

pub use xml_parser::{parse_shapes, parse_shape_from_string, ShapeParseError, ParseResult};
