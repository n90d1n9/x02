//! Chart model - embedded charts

use serde::{Deserialize, Serialize};

/// Chart - embedded chart in a slide
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Chart {
    /// Unique identifier
    pub id: String,
    /// Chart type
    pub chart_type: ChartType,
    /// Title
    pub title: Option<String>,
    /// Data series
    pub series: Vec<ChartSeries>,
    /// Categories (X-axis labels)
    pub categories: Vec<String>,
    /// Legend position
    pub legend_position: LegendPosition,
    /// Has data labels
    pub has_data_labels: bool,
}

impl Chart {
    pub fn new(id: &str, chart_type: ChartType) -> Self {
        Self {
            id: id.to_string(),
            chart_type,
            title: None,
            series: Vec::new(),
            categories: Vec::new(),
            legend_position: LegendPosition::Right,
            has_data_labels: false,
        }
    }
    
    pub fn add_series(&mut self, series: ChartSeries) {
        self.series.push(series);
    }
}

/// Chart Type
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum ChartType {
    Column,
    Bar,
    Line,
    Pie,
    Doughnut,
    Area,
    Scatter,
    Radar,
    Surface,
    Bubble,
    Stock,
    Combo,
}

impl Default for ChartType {
    fn default() -> Self {
        ChartType::Column
    }
}

/// Chart Series - a data series in a chart
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ChartSeries {
    /// Series name
    pub name: String,
    /// Data values
    pub values: Vec<f64>,
    /// Color
    pub color: Option<String>,
}

impl ChartSeries {
    pub fn new(name: &str, values: Vec<f64>) -> Self {
        Self {
            name: name.to_string(),
            values,
            color: None,
        }
    }
}

/// Legend Position
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum LegendPosition {
    None,
    Top,
    Bottom,
    Left,
    Right,
    Corner,
}

impl Default for LegendPosition {
    fn default() -> Self {
        LegendPosition::Right
    }
}
