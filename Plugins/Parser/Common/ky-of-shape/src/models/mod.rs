//! Shape model definitions for Office documents.

pub mod shape;

pub use shape::{
    Shape, ShapeGeometry, ShapeText, TextRun, FontProperties, 
    ShapeFill, ShapeOutline, ShapeEffects, Shape3D,
    ColorRef, SolidFill, GradientFill, PatternFill, PictureFill,
};
