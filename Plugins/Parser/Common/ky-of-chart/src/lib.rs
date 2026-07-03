//! Chart types and utilities for Office documents.
//!
//! This crate provides comprehensive chart support for Office Open XML documents,
//! including Excel, PowerPoint, and Word. It supports all OOXML chart types,
//! formatting options, and data configurations.
//!
//! # Module Structure
//!
//! - `types`: Core type definitions (ChartType, etc.)
//! - `models`: Data models (Chart, ChartSeries, Axis, etc.)
//! - `parser`: XML parsing functionality
//!
//! # Features
//!
//! - `serde-support`: Enable serialization/deserialization with serde
//!
//! # Example
//!
//! ```rust,no_run
//! use ky_of_chart::models::chart::{Chart, ChartSeries};
//! use ky_of_chart::types::chart_type::ChartType;
//!
//! let mut chart = Chart::new(ChartType::ColumnClustered);
//! chart.title = Some("Sales Data".to_string());
//!
//! let series = ChartSeries::new(Some("Q1".to_string()))
//!     .with_values(vec![100.0, 200.0, 150.0])
//!     .with_categories(vec!["Jan".to_string(), "Feb".to_string(), "Mar".to_string()]);
//!
//! chart.add_series(series);
//! ```

pub mod types;
pub mod models;
pub mod parser;

// Re-export commonly used types
pub use types::chart_type::ChartType;
pub use models::chart::*;
pub use parser::xml_parser::{parse_chart_xml, ChartParseError};
