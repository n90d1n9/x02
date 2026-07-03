//! Chart type definitions for Office documents.
//! 
//! This module defines all chart types supported in Office Open XML (OOXML),
//! covering Excel, PowerPoint, and Word chart specifications.

use serde::{Deserialize, Serialize};

/// Chart type enumeration covering all DrawingML chart types.
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub enum ChartType {
    // ==================== Bar / Column Charts ====================
    /// Clustered bar chart (horizontal bars)
    BarClustered,
    /// Stacked bar chart
    BarStacked,
    /// 100% stacked bar chart
    BarStacked100,
    /// Clustered column chart (vertical bars)
    ColumnClustered,
    /// Stacked column chart
    ColumnStacked,
    /// 100% stacked column chart
    ColumnStacked100,
    
    // ==================== 3D Bar / Column Charts ====================
    /// 3D clustered bar chart
    Bar3DClustered,
    /// 3D stacked bar chart
    Bar3DStacked,
    /// 3D 100% stacked bar chart
    Bar3DStacked100,
    /// 3D clustered column chart
    Column3DClustered,
    /// 3D stacked column chart
    Column3DStacked,
    /// 3D 100% stacked column chart
    Column3DStacked100,
    
    // ==================== Line Charts ====================
    /// Simple line chart
    Line,
    /// Stacked line chart
    LineStacked,
    /// 100% stacked line chart
    LineStacked100,
    /// Line chart with markers
    LineMarker,
    /// Stacked line chart with markers
    LineMarkerStacked,
    /// 100% stacked line chart with markers
    LineMarkerStacked100,
    /// 3D line chart
    Line3D,
    
    // ==================== Pie Charts ====================
    /// Standard pie chart
    Pie,
    /// 3D pie chart
    Pie3D,
    /// Exploded pie chart
    PieExploded,
    /// 3D exploded pie chart
    PieExploded3D,
    /// Doughnut chart
    Doughnut,
    /// Exploded doughnut chart
    DoughnutExploded,
    
    // ==================== Area Charts ====================
    /// Standard area chart
    Area,
    /// Stacked area chart
    AreaStacked,
    /// 100% stacked area chart
    AreaStacked100,
    /// 3D area chart
    Area3D,
    /// 3D stacked area chart
    Area3DStacked,
    /// 3D 100% stacked area chart
    Area3DStacked100,
    
    // ==================== Scatter / Bubble Charts ====================
    /// Scatter chart with markers only
    ScatterMarkers,
    /// Scatter chart with straight lines
    ScatterStraightLines,
    /// Scatter chart with straight lines and markers
    ScatterStraightLinesMarkers,
    /// Scatter chart with smooth lines
    ScatterSmoothLines,
    /// Scatter chart with smooth lines and markers
    ScatterSmoothLinesMarkers,
    /// Bubble chart
    Bubble,
    /// 3D bubble chart
    Bubble3D,
    
    // ==================== Stock / Financial Charts ====================
    /// High-Low-Close stock chart
    StockHLC,
    /// Open-High-Low-Close stock chart
    StockOHLC,
    /// Volume-High-Low-Close stock chart
    StockVHLC,
    /// Volume-Open-High-Low-Close stock chart
    StockVOHLC,
    
    // ==================== Radar / Spider Charts ====================
    /// Standard radar chart
    Radar,
    /// Radar chart with markers
    RadarMarkers,
    /// Filled radar chart
    RadarFilled,
    
    // ==================== Surface Charts ====================
    /// 3D surface chart
    Surface3D,
    /// Surface wireframe chart
    SurfaceWireframe,
    /// 3D surface wireframe chart
    Surface3DWireframe,
    
    // ==================== Combo Charts ====================
    /// Combination chart (multiple chart types)
    Combo,
    
    // ==================== Sunburst / Treemap (Office 2016+) ====================
    /// Sunburst chart (hierarchical pie)
    Sunburst,
    /// Treemap chart (hierarchical rectangles)
    Treemap,
    /// Histogram chart
    Histogram,
    /// Box and whisker chart
    BoxWhisker,
    /// Waterfall chart
    Waterfall,
    /// Funnel chart
    Funnel,
    
    // ==================== Unknown ====================
    /// Unrecognized chart type with original tag name
    Unknown(String),
}

impl ChartType {
    /// Parse from XML element name used inside `<c:plotArea>`.
    pub fn from_xml_tag(tag: &str) -> Self {
        match tag {
            "barChart" => Self::BarClustered,
            "bar3DChart" => Self::Bar3DClustered,
            "colChart" => Self::ColumnClustered,
            "col3DChart" => Self::Column3DClustered,
            "lineChart" => Self::Line,
            "line3DChart" => Self::Line3D,
            "pieChart" => Self::Pie,
            "pie3DChart" => Self::Pie3D,
            "doughnutChart" => Self::Doughnut,
            "areaChart" => Self::Area,
            "area3DChart" => Self::Area3D,
            "scatterChart" => Self::ScatterMarkers,
            "bubbleChart" => Self::Bubble,
            "stockChart" => Self::StockHLC,
            "radarChart" => Self::Radar,
            "surfaceChart" => Self::SurfaceWireframe,
            "surface3DChart" => Self::Surface3D,
            "sunburstChart" => Self::Sunburst,
            "treemapChart" => Self::Treemap,
            "histogramChart" => Self::Histogram,
            "boxwhiskerChart" => Self::BoxWhisker,
            "waterfallChart" => Self::Waterfall,
            "funnelChart" => Self::Funnel,
            other => Self::Unknown(other.to_owned()),
        }
    }

    /// Get the human-readable display name.
    pub fn display_name(&self) -> &str {
        match self {
            Self::BarClustered => "Clustered Bar",
            Self::BarStacked => "Stacked Bar",
            Self::BarStacked100 => "100% Stacked Bar",
            Self::ColumnClustered => "Clustered Column",
            Self::ColumnStacked => "Stacked Column",
            Self::ColumnStacked100 => "100% Stacked Column",
            Self::Bar3DClustered => "3D Clustered Bar",
            Self::Bar3DStacked => "3D Stacked Bar",
            Self::Bar3DStacked100 => "3D 100% Stacked Bar",
            Self::Column3DClustered => "3D Clustered Column",
            Self::Column3DStacked => "3D Stacked Column",
            Self::Column3DStacked100 => "3D 100% Stacked Column",
            Self::Line => "Line",
            Self::LineStacked => "Stacked Line",
            Self::LineStacked100 => "100% Stacked Line",
            Self::LineMarker => "Line with Markers",
            Self::LineMarkerStacked => "Stacked Line with Markers",
            Self::LineMarkerStacked100 => "100% Stacked Line with Markers",
            Self::Line3D => "3D Line",
            Self::Pie => "Pie",
            Self::Pie3D => "3D Pie",
            Self::PieExploded => "Exploded Pie",
            Self::PieExploded3D => "3D Exploded Pie",
            Self::Doughnut => "Doughnut",
            Self::DoughnutExploded => "Exploded Doughnut",
            Self::Area => "Area",
            Self::AreaStacked => "Stacked Area",
            Self::AreaStacked100 => "100% Stacked Area",
            Self::Area3D => "3D Area",
            Self::Area3DStacked => "3D Stacked Area",
            Self::Area3DStacked100 => "3D 100% Stacked Area",
            Self::ScatterMarkers => "Scatter",
            Self::ScatterStraightLines => "Scatter with Straight Lines",
            Self::ScatterStraightLinesMarkers => "Scatter with Straight Lines and Markers",
            Self::ScatterSmoothLines => "Scatter with Smooth Lines",
            Self::ScatterSmoothLinesMarkers => "Scatter with Smooth Lines and Markers",
            Self::Bubble => "Bubble",
            Self::Bubble3D => "3D Bubble",
            Self::StockHLC => "High-Low-Close",
            Self::StockOHLC => "Open-High-Low-Close",
            Self::StockVHLC => "Volume-High-Low-Close",
            Self::StockVOHLC => "Volume-Open-High-Low-Close",
            Self::Radar => "Radar",
            Self::RadarMarkers => "Radar with Markers",
            Self::RadarFilled => "Filled Radar",
            Self::Surface3D => "3D Surface",
            Self::SurfaceWireframe => "Surface Wireframe",
            Self::Surface3DWireframe => "3D Surface Wireframe",
            Self::Combo => "Combo",
            Self::Sunburst => "Sunburst",
            Self::Treemap => "Treemap",
            Self::Histogram => "Histogram",
            Self::BoxWhisker => "Box and Whisker",
            Self::Waterfall => "Waterfall",
            Self::Funnel => "Funnel",
            Self::Unknown(s) => s,
        }
    }

    /// Check if this is a 3D chart type.
    pub fn is_3d(&self) -> bool {
        matches!(
            self,
            Self::Bar3DClustered
                | Self::Bar3DStacked
                | Self::Bar3DStacked100
                | Self::Column3DClustered
                | Self::Column3DStacked
                | Self::Column3DStacked100
                | Self::Line3D
                | Self::Pie3D
                | Self::PieExploded3D
                | Self::Area3D
                | Self::Area3DStacked
                | Self::Area3DStacked100
                | Self::Bubble3D
                | Self::Surface3D
                | Self::Surface3DWireframe
        )
    }

    /// Check if this is a variation of bar/column charts.
    pub fn is_bar_or_column(&self) -> bool {
        matches!(
            self,
            Self::BarClustered
                | Self::BarStacked
                | Self::BarStacked100
                | Self::ColumnClustered
                | Self::ColumnStacked
                | Self::ColumnStacked100
                | Self::Bar3DClustered
                | Self::Bar3DStacked
                | Self::Bar3DStacked100
                | Self::Column3DClustered
                | Self::Column3DStacked
                | Self::Column3DStacked100
        )
    }

    /// Check if this is a pie-type chart.
    pub fn is_pie(&self) -> bool {
        matches!(
            self,
            Self::Pie | Self::Pie3D | Self::PieExploded | Self::PieExploded3D | Self::Doughnut | Self::DoughnutExploded
        )
    }

    /// Check if this is a line-type chart.
    pub fn is_line(&self) -> bool {
        matches!(
            self,
            Self::Line
                | Self::LineStacked
                | Self::LineStacked100
                | Self::LineMarker
                | Self::LineMarkerStacked
                | Self::LineMarkerStacked100
                | Self::Line3D
        )
    }

    /// Get the base chart family (e.g., Bar, Line, Pie).
    pub fn family(&self) -> &str {
        match self {
            Self::BarClustered | Self::BarStacked | Self::BarStacked100 |
            Self::Bar3DClustered | Self::Bar3DStacked | Self::Bar3DStacked100 => "Bar",
            Self::ColumnClustered | Self::ColumnStacked | Self::ColumnStacked100 |
            Self::Column3DClustered | Self::Column3DStacked | Self::Column3DStacked100 => "Column",
            Self::Line | Self::LineStacked | Self::LineStacked100 |
            Self::LineMarker | Self::LineMarkerStacked | Self::LineMarkerStacked100 | Self::Line3D => "Line",
            Self::Pie | Self::Pie3D | Self::PieExploded | Self::PieExploded3D => "Pie",
            Self::Doughnut | Self::DoughnutExploded => "Doughnut",
            Self::Area | Self::AreaStacked | Self::AreaStacked100 |
            Self::Area3D | Self::Area3DStacked | Self::Area3DStacked100 => "Area",
            Self::ScatterMarkers | Self::ScatterStraightLines | Self::ScatterStraightLinesMarkers |
            Self::ScatterSmoothLines | Self::ScatterSmoothLinesMarkers => "Scatter",
            Self::Bubble | Self::Bubble3D => "Bubble",
            Self::StockHLC | Self::StockOHLC | Self::StockVHLC | Self::StockVOHLC => "Stock",
            Self::Radar | Self::RadarMarkers | Self::RadarFilled => "Radar",
            Self::Surface3D | Self::SurfaceWireframe | Self::Surface3DWireframe => "Surface",
            Self::Sunburst => "Sunburst",
            Self::Treemap => "Treemap",
            Self::Histogram => "Histogram",
            Self::BoxWhisker => "BoxWhisker",
            Self::Waterfall => "Waterfall",
            Self::Funnel => "Funnel",
            Self::Combo => "Combo",
            Self::Unknown(_) => "Unknown",
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_from_xml_tag() {
        assert_eq!(ChartType::from_xml_tag("barChart"), ChartType::BarClustered);
        assert_eq!(ChartType::from_xml_tag("pie3DChart"), ChartType::Pie3D);
        assert_eq!(ChartType::from_xml_tag("unknownChart"), ChartType::Unknown("unknownChart".to_string()));
    }

    #[test]
    fn test_is_3d() {
        assert!(ChartType::Pie3D.is_3d());
        assert!(!ChartType::Pie.is_3d());
    }

    #[test]
    fn test_display_name() {
        assert_eq!(ChartType::ColumnClustered.display_name(), "Clustered Column");
    }
}
