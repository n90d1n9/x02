//! Chart data models for Office documents.
//!
//! This module defines the core data structures for representing charts,
//! including series, axes, legends, and formatting options.

use serde::{Deserialize, Serialize};
use crate::types::chart_type::ChartType;

/// A chart embedded in an Office document (Excel, PowerPoint, Word).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Chart {
    /// The primary type of chart.
    pub chart_type: ChartType,
    /// All chart types detected (for combo charts).
    pub chart_types: Vec<ChartType>,
    /// Chart title text.
    pub title: Option<String>,
    /// Data series in the chart.
    pub series: Vec<ChartSeries>,
    /// Chart axes definitions.
    pub axes: Vec<ChartAxis>,
    /// Chart legend configuration.
    pub legend: Option<ChartLegend>,
    /// Plot area configuration.
    pub plot_area: PlotArea,
    /// Whether the chart has 3D perspective.
    pub is_3d: bool,
    /// Whether data labels are shown globally.
    pub show_data_labels: bool,
    /// Global data labels configuration.
    pub data_labels: Option<DataLabels>,
    /// Chart style index (1-48 in OOXML).
    pub style: Option<u8>,
    /// Whether to show grid lines.
    pub show_grid_lines: bool,
    /// Whether the chart includes a data table.
    pub data_table: bool,
    /// Chart background color (ARGB hex).
    pub chart_bg_color: Option<String>,
    /// Source path in the archive (e.g., "xl/charts/chart1.xml").
    pub source_path: Option<String>,
}

impl Chart {
    /// Create a new empty chart with the specified type.
    pub fn new(chart_type: ChartType) -> Self {
        Self {
            chart_type: chart_type.clone(),
            chart_types: vec![chart_type],
            title: None,
            series: Vec::new(),
            axes: Vec::new(),
            legend: None,
            plot_area: PlotArea::default(),
            is_3d: false,
            show_data_labels: false,
            data_labels: None,
            style: None,
            show_grid_lines: false,
            data_table: false,
            chart_bg_color: None,
            source_path: None,
        }
    }

    /// Extract all categories (X-axis labels) if available.
    pub fn categories(&self) -> Vec<String> {
        self.series.first()
            .and_then(|s| s.categories.as_ref())
            .cloned()
            .unwrap_or_default()
    }

    /// Get the number of data series.
    pub fn series_count(&self) -> usize {
        self.series.len()
    }

    /// Convert chart data to a 2D matrix for easy consumption.
    /// Rows = series, columns = data points.
    pub fn to_matrix(&self) -> Vec<Vec<f64>> {
        self.series.iter()
            .map(|s| s.values.iter().map(|v| v.unwrap_or(0.0)).collect())
            .collect()
    }

    /// Check if this is a combo chart (multiple chart types).
    pub fn is_combo(&self) -> bool {
        self.chart_types.len() > 1
    }

    /// Add a data series to the chart.
    pub fn add_series(&mut self, series: ChartSeries) {
        self.series.push(series);
    }

    /// Get series by name.
    pub fn get_series_by_name(&self, name: &str) -> Option<&ChartSeries> {
        self.series.iter().find(|s| {
            s.name.as_ref().map(|n| n == name).unwrap_or(false)
        })
    }
}

/// A single data series in a chart.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ChartSeries {
    /// Series display name.
    pub name: Option<String>,
    /// Series index in the chart.
    pub index: u32,
    /// Series order for plotting.
    pub order: u32,
    /// Category labels (X-axis, shared across series).
    pub categories: Option<Vec<String>>,
    /// Numeric data values (None = missing/empty cell).
    pub values: Vec<Option<f64>>,
    /// For bubble charts: bubble sizes.
    pub bubble_sizes: Option<Vec<Option<f64>>>,
    /// For scatter charts: X values.
    pub x_values: Option<Vec<Option<f64>>>,
    /// Series fill color.
    pub fill: Option<ColorSpec>,
    /// Series line/stroke color.
    pub line_color: Option<ColorSpec>,
    /// Data point marker style.
    pub marker: Option<DataMarker>,
    /// Series-specific data labels.
    pub data_labels: Option<DataLabels>,
    /// Whether to use smooth lines (for line/scatter charts).
    pub smooth: bool,
    /// Cell reference for the series name.
    pub name_ref: Option<String>,
    /// Cell reference for categories.
    pub categories_ref: Option<String>,
    /// Cell reference for values.
    pub values_ref: Option<String>,
    /// Trendline configuration.
    pub trendline: Option<Trendline>,
    /// Error bars configuration.
    pub error_bars: Option<ErrorBars>,
}

impl Default for ChartSeries {
    fn default() -> Self {
        Self {
            name: None,
            index: 0,
            order: 0,
            categories: None,
            values: Vec::new(),
            bubble_sizes: None,
            x_values: None,
            fill: None,
            line_color: None,
            marker: None,
            data_labels: None,
            smooth: false,
            name_ref: None,
            categories_ref: None,
            values_ref: None,
            trendline: None,
            error_bars: None,
        }
    }
}

impl ChartSeries {
    /// Create a new series with the given name.
    pub fn new(name: Option<String>) -> Self {
        Self {
            name,
            ..Default::default()
        }
    }

    /// Set the data values for this series.
    pub fn with_values(mut self, values: Vec<f64>) -> Self {
        self.values = values.into_iter().map(Some).collect();
        self
    }

    /// Set the category labels.
    pub fn with_categories(mut self, categories: Vec<String>) -> Self {
        self.categories = Some(categories);
        self
    }

    /// Get the count of data points.
    pub fn data_point_count(&self) -> usize {
        self.values.len()
    }
}

/// Color specification supporting various formats.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ColorSpec {
    /// ARGB hex value (e.g., "FF4472C4").
    pub argb: Option<String>,
    /// RGB hex value (e.g., "4472C4").
    pub rgb: Option<String>,
    /// Theme color reference.
    pub theme: Option<ThemeColor>,
    /// System color name.
    pub system: Option<String>,
    /// Transparency (0.0 = opaque, 1.0 = fully transparent).
    pub alpha: Option<f64>,
}

impl ColorSpec {
    /// Create a color from ARGB hex string.
    pub fn from_argb(argb: &str) -> Self {
        Self {
            argb: Some(argb.to_string()),
            rgb: None,
            theme: None,
            system: None,
            alpha: None,
        }
    }

    /// Create a theme color.
    pub fn from_theme(theme: ThemeColor) -> Self {
        Self {
            argb: None,
            rgb: None,
            theme: Some(theme),
            system: None,
            alpha: None,
        }
    }
}

/// Theme color enumeration matching Office theme colors.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum ThemeColor {
    Background1,
    Text1,
    Background2,
    Text2,
    Accent1,
    Accent2,
    Accent3,
    Accent4,
    Accent5,
    Accent6,
    Hyperlink,
    FollowedHyperlink,
    Unknown(String),
}

/// Data point marker configuration.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DataMarker {
    /// Marker symbol.
    pub symbol: MarkerSymbol,
    /// Marker size in points.
    pub size: u32,
    /// Marker fill color.
    pub fill: Option<ColorSpec>,
    /// Marker border color.
    pub line_color: Option<ColorSpec>,
    /// Marker border width.
    pub line_width: Option<f64>,
}

impl Default for DataMarker {
    fn default() -> Self {
        Self {
            symbol: MarkerSymbol::Auto,
            size: 5,
            fill: None,
            line_color: None,
            line_width: None,
        }
    }
}

/// Marker symbol types.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum MarkerSymbol {
    Circle,
    Square,
    Diamond,
    Triangle,
    TriangleDown,
    Star,
    X,
    Plus,
    Dash,
    Dot,
    Auto,
    None,
    Unknown(String),
}

/// Chart axis definition.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ChartAxis {
    /// Unique axis ID.
    pub axis_id: u32,
    /// Type of axis.
    pub axis_type: AxisType,
    /// Axis position (for category axes).
    pub axis_position: Option<AxisPosition>,
    /// Axis title text.
    pub title: Option<String>,
    /// Minimum scale value.
    pub min: Option<f64>,
    /// Maximum scale value.
    pub max: Option<f64>,
    /// Major unit (interval between major tick marks).
    pub major_unit: Option<f64>,
    /// Minor unit (interval between minor tick marks).
    pub minor_unit: Option<f64>,
    /// Number format code (e.g., "0.00", "$#,##0").
    pub number_format: Option<String>,
    /// Position of the axis.
    pub position: AxisPosition,
    /// Where the axis crosses.
    pub crosses: AxisCrosses,
    /// Whether the axis is reversed.
    pub reverse_order: bool,
    /// Logarithmic scale base (None = linear).
    pub log_scale: Option<f64>,
    /// Whether major grid lines are shown.
    pub major_grid_lines: bool,
    /// Whether minor grid lines are shown.
    pub minor_grid_lines: bool,
    /// Whether the axis is visible.
    pub visible: bool,
    /// Title font properties.
    pub title_font: Option<FontProperties>,
    /// Tick label properties.
    pub tick_labels: Option<TickLabels>,
}

impl Default for ChartAxis {
    fn default() -> Self {
        Self {
            axis_id: 0,
            axis_type: AxisType::Value,
            axis_position: None,
            title: None,
            min: None,
            max: None,
            major_unit: None,
            minor_unit: None,
            number_format: None,
            position: AxisPosition::Bottom,
            crosses: AxisCrosses::AutoZero,
            reverse_order: false,
            log_scale: None,
            major_grid_lines: false,
            minor_grid_lines: false,
            visible: true,
            title_font: None,
            tick_labels: None,
        }
    }
}

/// Axis type enumeration.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum AxisType {
    /// Category axis (discrete values).
    Category,
    /// Value axis (numeric scale).
    Value,
    /// Date axis (time scale).
    Date,
    /// Series axis (for 3D charts).
    Series,
}

/// Axis position enumeration.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum AxisPosition {
    Left,
    Right,
    Top,
    Bottom,
}

/// Where an axis crosses.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum AxisCrosses {
    /// Crosses at zero or minimum.
    AutoZero,
    /// Crosses at maximum.
    Max,
    /// Crosses at minimum.
    Min,
    /// Crosses at specific value.
    CrossesAt(f64),
}

/// Tick label configuration.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TickLabels {
    /// Label position.
    pub position: TickLabelPosition,
    /// Number format.
    pub number_format: Option<String>,
    /// Font properties.
    pub font: Option<FontProperties>,
    /// Whether to show.
    pub visible: bool,
    /// Angle of rotation.
    pub angle: Option<i32>,
}

impl Default for TickLabels {
    fn default() -> Self {
        Self {
            position: TickLabelPosition::NextTo,
            number_format: None,
            font: None,
            visible: true,
            angle: None,
        }
    }
}

/// Tick label position.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum TickLabelPosition {
    NextTo,
    Low,
    High,
    None,
}

/// Chart legend configuration.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ChartLegend {
    /// Legend position.
    pub position: LegendPosition,
    /// Whether the legend overlays the plot area.
    pub overlay: bool,
    /// Whether the legend is visible.
    pub visible: bool,
    /// Legend layout (horizontal/vertical).
    pub layout: Option<LegendLayout>,
}

impl Default for ChartLegend {
    fn default() -> Self {
        Self {
            position: LegendPosition::Right,
            overlay: false,
            visible: true,
            layout: None,
        }
    }
}

/// Legend position enumeration.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum LegendPosition {
    Bottom,
    Left,
    Right,
    Top,
    TopRight,
    Custom,
}

/// Legend layout orientation.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum LegendLayout {
    Horizontal,
    Vertical,
}

/// Data labels configuration.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DataLabels {
    /// Show value.
    pub show_value: bool,
    /// Show series name.
    pub show_series_name: bool,
    /// Show category name.
    pub show_category_name: bool,
    /// Show percentage.
    pub show_percentage: bool,
    /// Show leader lines.
    pub show_leader_lines: bool,
    /// Show bubble size.
    pub show_bubble_size: bool,
    /// Label position.
    pub position: DataLabelPosition,
    /// Number format.
    pub number_format: Option<String>,
    /// Separator between multiple fields.
    pub separator: Option<String>,
    /// Font properties.
    pub font: Option<FontProperties>,
    /// Fill color.
    pub fill: Option<ColorSpec>,
    /// Border color.
    pub border: Option<ColorSpec>,
}

impl Default for DataLabels {
    fn default() -> Self {
        Self {
            show_value: true,
            show_series_name: false,
            show_category_name: false,
            show_percentage: false,
            show_leader_lines: false,
            show_bubble_size: false,
            position: DataLabelPosition::BestFit,
            number_format: None,
            separator: None,
            font: None,
            fill: None,
            border: None,
        }
    }
}

/// Data label position.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum DataLabelPosition {
    BestFit,
    Center,
    InsideBase,
    InsideEnd,
    Left,
    OutsideEnd,
    Right,
    Top,
    Bottom,
}

/// Chart plot area configuration.
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct PlotArea {
    /// Background fill.
    pub fill: Option<FillType>,
    /// Border properties.
    pub border: Option<LineProperties>,
    /// Left offset (percentage).
    pub left: Option<f64>,
    /// Top offset (percentage).
    pub top: Option<f64>,
    /// Width (percentage).
    pub width: Option<f64>,
    /// Height (percentage).
    pub height: Option<f64>,
}

/// Fill type for chart elements.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum FillType {
    /// Solid color fill.
    Solid(ColorSpec),
    /// Gradient fill.
    Gradient(GradientFill),
    /// Pattern fill.
    Pattern(PatternFill),
    /// No fill.
    None,
}

/// Gradient fill definition.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GradientFill {
    /// Gradient type.
    pub gradient_type: GradientType,
    /// Gradient stops.
    pub stops: Vec<GradientStop>,
    /// Angle in degrees.
    pub angle: Option<f64>,
}

/// Gradient type.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum GradientType {
    Linear,
    Radial,
    Rectangular,
    Path,
}

/// Gradient stop.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GradientStop {
    /// Position (0.0 to 1.0).
    pub position: f64,
    /// Color at this stop.
    pub color: ColorSpec,
}

/// Pattern fill definition.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PatternFill {
    /// Pattern type.
    pub pattern_type: PatternType,
    /// Foreground color.
    pub foreground: Option<ColorSpec>,
    /// Background color.
    pub background: Option<ColorSpec>,
}

/// Pattern type enumeration.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum PatternType {
    Solid,
    Gray50,
    Gray25,
    Gray75,
    Horz,
    Vert,
    ReverseDiag,
    Diag,
    Cross,
    DarkCross,
    DarkDown,
    DarkGray,
    DarkGrid,
    DarkHorz,
    DarkUp,
    DarkVert,
    Down,
    LightDown,
    LightGray,
    LightGrid,
    LightHorz,
    LightUp,
    LightVert,
    NarrowCross,
    NarrowHorz,
    NarrowVert,
    SemiGray75,
    Up,
    WideDown,
    WideGrid,
    WideHorz,
    WideUp,
    WideVert,
}

/// Line properties for borders and strokes.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LineProperties {
    /// Line color.
    pub color: Option<ColorSpec>,
    /// Line width in points.
    pub width: Option<f64>,
    /// Line style (solid, dash, etc.).
    pub style: LineStyle,
    /// Cap type (flat, round, square).
    pub cap: LineCap,
    /// Join type (miter, round, bevel).
    pub join: LineJoin,
}

impl Default for LineProperties {
    fn default() -> Self {
        Self {
            color: None,
            width: Some(1.0),
            style: LineStyle::Solid,
            cap: LineCap::Flat,
            join: LineJoin::Miter,
        }
    }
}

/// Line style enumeration.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum LineStyle {
    Solid,
    Dash,
    Dot,
    DashDot,
    DashDotDot,
    RoundDot,
    SysDash,
    SysDot,
    SysDashDot,
}

/// Line cap type.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum LineCap {
    Flat,
    Round,
    Square,
}

/// Line join type.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum LineJoin {
    Miter,
    Round,
    Bevel,
}

/// Font properties for text elements.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FontProperties {
    /// Font family name.
    pub family: Option<String>,
    /// Font size in points.
    pub size: Option<f64>,
    /// Whether bold.
    pub bold: bool,
    /// Whether italic.
    pub italic: bool,
    /// Whether underlined.
    pub underline: bool,
    /// Font color.
    pub color: Option<ColorSpec>,
    /// Rotation angle.
    pub rotation: Option<i32>,
}

impl Default for FontProperties {
    fn default() -> Self {
        Self {
            family: None,
            size: None,
            bold: false,
            italic: false,
            underline: false,
            color: None,
            rotation: None,
        }
    }
}

/// Trendline configuration.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Trendline {
    /// Trendline type.
    pub trendline_type: TrendlineType,
    /// Display equation on chart.
    pub display_equation: bool,
    /// Display R-squared value.
    pub display_r_squared: bool,
    /// Forward period.
    pub forward: Option<u32>,
    /// Backward period.
    pub backward: Option<u32>,
    /// Intercept value.
    pub intercept: Option<f64>,
    /// Period for moving average.
    pub period: Option<u32>,
    /// Trendline name.
    pub name: Option<String>,
}

/// Trendline type enumeration.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum TrendlineType {
    Linear,
    Logarithmic,
    Exponential,
    Power,
    Polynomial(u32), // Order
    MovingAverage(u32), // Period
}

/// Error bars configuration.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ErrorBars {
    /// Error bar type.
    pub error_bar_type: ErrorBarType,
    /// Direction.
    pub direction: ErrorBarDirection,
    /// End style.
    pub end_style: ErrorBarEndStyle,
    /// Error amount.
    pub error_amount: ErrorAmount,
}

/// Error bar type.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum ErrorBarType {
    Fixed,
    Percentage,
    StandardDeviation,
    StandardError,
    Custom,
}

/// Error bar direction.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum ErrorBarDirection {
    Both,
    Plus,
    Minus,
}

/// Error bar end style.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum ErrorBarEndStyle {
    Cap,
    NoCap,
}

/// Error amount specification.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum ErrorAmount {
    /// Fixed value.
    Fixed(f64),
    /// Percentage.
    Percentage(f64),
    /// Standard deviations.
    StandardDeviation(f64),
    /// Custom values.
    Custom {
        plus_values: Vec<f64>,
        minus_values: Vec<f64>,
    },
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_chart_creation() {
        let chart = Chart::new(ChartType::ColumnClustered);
        assert_eq!(chart.series_count(), 0);
        assert!(!chart.is_combo());
    }

    #[test]
    fn test_chart_series() {
        let series = ChartSeries::new(Some("Series 1".to_string()))
            .with_values(vec![1.0, 2.0, 3.0])
            .with_categories(vec!["A".to_string(), "B".to_string(), "C".to_string()]);
        
        assert_eq!(series.data_point_count(), 3);
        assert_eq!(series.name, Some("Series 1".to_string()));
    }

    #[test]
    fn test_color_spec() {
        let color = ColorSpec::from_argb("FF4472C4");
        assert_eq!(color.argb, Some("FF4472C4".to_string()));
    }
}
