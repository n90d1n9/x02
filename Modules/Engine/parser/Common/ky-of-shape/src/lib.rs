//! Shape module for Office Parser and Engine.

pub mod types;
pub mod models;
pub mod parser;

pub use types::shape_type::ShapeType;
pub use models::shape::{Shape, ShapeGeometry, ShapeText, ShapeFill, ShapeOutline};
pub use parser::xml_parser::{parse_shapes, parse_shape_from_string, ShapeParseError};
