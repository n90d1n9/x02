//! Chart XML parser for Office Open XML documents.
//!
//! This module provides functionality to parse chart XML files from
//! Excel (.xlsx), PowerPoint (.pptx), and Word (.docx) documents.

use quick_xml::events::Event;
use quick_xml::Reader;
use std::str::FromStr;

use crate::models::chart::*;
use crate::types::chart_type::ChartType;

/// Parse a chart XML file content into a Chart model.
pub fn parse_chart_xml(xml: &str, source_path: Option<&str>) -> Result<Chart, ChartParseError> {
    let mut reader = Reader::from_str(xml);
    reader.trim_text(true);

    let mut chart = Chart::new(ChartType::Unknown("unknown".to_string()));
    chart.source_path = source_path.map(String::from);

    let mut buf = Vec::new();
    let mut state = ParserState::default();

    loop {
        match reader.read_event_into(&mut buf) {
            Ok(Event::Start(ref e)) => {
                let name = String::from_utf8_lossy(e.name().as_ref());
                handle_start_event(&name, e, &mut chart, &mut state);
            }
            Ok(Event::End(ref e)) => {
                let name = String::from_utf8_lossy(e.name().as_ref());
                handle_end_event(&name, &mut chart, &mut state);
            }
            Ok(Event::Empty(ref e)) => {
                let name = String::from_utf8_lossy(e.name().as_ref());
                handle_empty_event(&name, e, &mut chart, &mut state);
            }
            Ok(Event::Text(ref t)) => {
                if state.in_title {
                    state.title_buf.push_str(&t.unescape().unwrap_or_default());
                }
            }
            Ok(Event::Eof) => break,
            Err(e) => return Err(ChartParseError::XmlError(e.to_string())),
            _ => {}
        }
        buf.clear();
    }

    // Finalize any in-progress elements
    if state.in_series && !state.current_series.is_none() {
        if let Some(series) = state.current_series.take() {
            chart.series.push(series);
        }
    }
    if state.in_axis && !state.current_axis.is_none() {
        if let Some(axis) = state.current_axis.take() {
            chart.axes.push(axis);
        }
    }

    Ok(chart)
}

#[derive(Default)]
struct ParserState {
    in_title: bool,
    in_series: bool,
    in_axis: bool,
    in_legend: bool,
    in_plot_area: bool,
    title_buf: String,
    current_series: Option<ChartSeries>,
    current_axis: Option<ChartAxis>,
    current_legend: Option<ChartLegend>,
}

fn handle_start_event(name: &str, event: &quick_xml::events::BytesStart, chart: &mut Chart, state: &mut ParserState) {
    match name.as_ref() {
        "c:title" => {
            state.in_title = true;
        }
        "c:ser" => {
            state.in_series = true;
            state.current_series = Some(ChartSeries::default());
        }
        "c:catAx" | "c:valAx" | "c:dateAx" | "c:serAx" => {
            state.in_axis = true;
            let axis_type = match name.trim_start_matches("c:") {
                "catAx" => AxisType::Category,
                "valAx" => AxisType::Value,
                "dateAx" => AxisType::Date,
                _ => AxisType::Series,
            };
            state.current_axis = Some(ChartAxis {
                axis_type,
                visible: true,
                ..Default::default()
            });
        }
        "c:legend" => {
            state.in_legend = true;
            state.current_legend = Some(ChartLegend::default());
        }
        "c:plotArea" => {
            state.in_plot_area = true;
        }
        // Chart type detection
        n if is_chart_type_tag(n) => {
            let tag = n.trim_start_matches("c:");
            let chart_type = ChartType::from_xml_tag(tag);
            if chart.chart_types.is_empty() {
                chart.chart_type = chart_type.clone();
            }
            chart.chart_types.push(chart_type);
            if n.contains("3D") {
                chart.is_3d = true;
            }
        }
        // Series properties
        "c:tx" if state.in_series => {}
        "c:cat" if state.in_series => {}
        "c:val" if state.in_series => {}
        "c:xVal" if state.in_series => {}
        "c:yVal" if state.in_series => {}
        "c:bubbleSize" if state.in_series => {}
        // Axis properties
        "c:scaling" if state.in_axis => {}
        "c:tickLblPos" if state.in_axis => {}
        _ => {}
    }
}

fn handle_end_event(name: &str, chart: &mut Chart, state: &mut ParserState) {
    match name.as_ref() {
        "c:title" => {
            state.in_title = false;
            if !state.title_buf.is_empty() {
                chart.title = Some(std::mem::take(&mut state.title_buf));
            }
        }
        "c:ser" => {
            state.in_series = false;
            if let Some(series) = state.current_series.take() {
                chart.series.push(series);
            }
        }
        "c:catAx" | "c:valAx" | "c:dateAx" | "c:serAx" => {
            state.in_axis = false;
            if let Some(axis) = state.current_axis.take() {
                chart.axes.push(axis);
            }
        }
        "c:legend" => {
            state.in_legend = false;
            chart.legend = state.current_legend.take();
        }
        "c:plotArea" => {
            state.in_plot_area = false;
        }
        _ => {}
    }
}

fn handle_empty_event(name: &str, event: &quick_xml::events::BytesStart, chart: &mut Chart, state: &mut ParserState) {
    let get_attr = |key: &str| -> Option<String> {
        event.attributes().find_map(|a| {
            if let Ok(attr) = a {
                if attr.key.as_ref() == key.as_bytes() {
                    return String::from_utf8(attr.value.to_vec()).ok();
                }
            }
            None
        })
    };

    match name.as_ref() {
        // Series attributes
        "c:idx" if state.in_series => {
            if let Some(ref mut series) = state.current_series {
                if let Some(val) = get_attr("val") {
                    series.index = val.parse().unwrap_or(0);
                }
            }
        }
        "c:order" if state.in_series => {
            if let Some(ref mut series) = state.current_series {
                if let Some(val) = get_attr("val") {
                    series.order = val.parse().unwrap_or(0);
                }
            }
        }
        "c:smooth" if state.in_series => {
            if let Some(ref mut series) = state.current_series {
                series.smooth = get_attr("val").as_deref() != Some("0");
            }
        }
        // Axis attributes
        "c:axId" if state.in_axis => {
            if let Some(ref mut axis) = state.current_axis {
                if let Some(val) = get_attr("val") {
                    axis.axis_id = val.parse().unwrap_or(0);
                }
            }
        }
        "c:axPos" if state.in_axis => {
            if let Some(ref mut axis) = state.current_axis {
                axis.position = match get_attr("val").as_deref() {
                    Some("l") => AxisPosition::Left,
                    Some("r") => AxisPosition::Right,
                    Some("t") => AxisPosition::Top,
                    _ => AxisPosition::Bottom,
                };
            }
        }
        "c:delete" if state.in_axis => {
            if let Some(ref mut axis) = state.current_axis {
                axis.visible = get_attr("val").as_deref() != Some("1");
            }
        }
        "c:majorGridlines" if state.in_axis => {
            if let Some(ref mut axis) = state.current_axis {
                axis.major_grid_lines = true;
            }
        }
        "c:minorGridlines" if state.in_axis => {
            if let Some(ref mut axis) = state.in_axis.then(|| &mut state.current_axis).flatten() {
                axis.minor_grid_lines = true;
            }
        }
        // Legend attributes
        "c:legendPos" if state.in_legend => {
            if let Some(ref mut legend) = state.current_legend {
                legend.position = match get_attr("val").as_deref() {
                    Some("b") => LegendPosition::Bottom,
                    Some("t") => LegendPosition::Top,
                    Some("l") => LegendPosition::Left,
                    Some("tr") => LegendPosition::TopRight,
                    _ => LegendPosition::Right,
                };
            }
        }
        "c:overlay" if state.in_legend => {
            if let Some(ref mut legend) = state.current_legend {
                legend.overlay = get_attr("val").as_deref() == Some("1");
            }
        }
        // Chart-level attributes
        "c:dTable" => {
            chart.data_table = true;
        }
        "c:showGridLines" => {
            chart.show_grid_lines = get_attr("val").as_deref() != Some("0");
        }
        _ => {}
    }
}

fn is_chart_type_tag(name: &str) -> bool {
    matches!(
        name,
        "c:barChart"
            | "c:bar3DChart"
            | "c:colChart"
            | "c:col3DChart"
            | "c:lineChart"
            | "c:line3DChart"
            | "c:pieChart"
            | "c:pie3DChart"
            | "c:doughnutChart"
            | "c:areaChart"
            | "c:area3DChart"
            | "c:scatterChart"
            | "c:bubbleChart"
            | "c:stockChart"
            | "c:radarChart"
            | "c:surfaceChart"
            | "c:surface3DChart"
            | "c:sunburstChart"
            | "c:treemapChart"
            | "c:histogramChart"
            | "c:boxwhiskerChart"
            | "c:waterfallChart"
            | "c:funnelChart"
    )
}

/// Chart parsing error types.
#[derive(Debug, Clone)]
pub enum ChartParseError {
    /// XML parsing error.
    XmlError(String),
    /// Missing required element.
    MissingElement(String),
    /// Invalid attribute value.
    InvalidAttribute(String),
    /// Unsupported chart format.
    UnsupportedFormat(String),
}

impl std::fmt::Display for ChartParseError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::XmlError(s) => write!(f, "XML error: {}", s),
            Self::MissingElement(s) => write!(f, "Missing element: {}", s),
            Self::InvalidAttribute(s) => write!(f, "Invalid attribute: {}", s),
            Self::UnsupportedFormat(s) => write!(f, "Unsupported format: {}", s),
        }
    }
}

impl std::error::Error for ChartParseError {}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_minimal_chart() {
        let xml = r#"<?xml version="1.0" encoding="UTF-8"?>
<c:chartSpace xmlns:c="http://schemas.openxmlformats.org/drawingml/2006/chart">
  <c:chart>
    <c:plotArea>
      <c:barChart>
        <c:barDir val="col"/>
        <c:grouping val="clustered"/>
      </c:barChart>
    </c:plotArea>
  </c:chart>
</c:chartSpace>"#;

        let chart = parse_chart_xml(xml, Some("test.xml")).unwrap();
        assert!(matches!(chart.chart_type, ChartType::BarClustered | ChartType::ColumnClustered));
    }
}
