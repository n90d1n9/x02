//! Shape type definitions for Office documents.
//! 
//! This module provides a comprehensive set of shape types following the OOXML specification,
//! including basic shapes, block arrows, equation shapes, flowchart shapes, stars, and symbols.

use serde::{Deserialize, Serialize};

/// All supported shape types in Office documents.
/// 
/// This enum covers all standard OOXML shape types including:
/// - Basic Shapes (rectangle, ellipse, triangle, etc.)
/// - Block Arrows (various directional arrows)
/// - Equation Shapes (mathematical operators)
/// - Flowchart Shapes (process, decision, data, etc.)
/// - Stars and Banners
/// - Symbols and callouts
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum ShapeType {
    // Basic Shapes
    Rectangle,
    RoundRectangle,
    Ellipse,
    Triangle,
    RightTriangle,
    Parallelogram,
    Trapezoid,
    Diamond,
    Pentagon,
    Hexagon,
    Heptagon,
    Octagon,
    Decagon,
    Dodecagon,
    Star4,
    Star5,
    Star6,
    Star7,
    Star8,
    Star10,
    Star12,
    Star16,
    Star24,
    Star32,
    RoundRectangleCorner,
    RoundOneCorner,
    RoundTwoSameCorner,
    RoundTwoAdjacentCorner,
    SnipRoundRectangle,
    SnipOneCorner,
    SnipTwoSameCorner,
    SnipTwoAdjacentCorner,
    
    // Block Arrows
    RightArrow,
    StripedRightArrow,
    QuadArrow,
    LeftArrow,
    UpArrow,
    DownArrow,
    LeftRightArrow,
    UpDownArrow,
    LeftUpArrow,
    BentArrow,
    UTurnArrow,
    CircularArrow,
    LeftCircularArrow,
    RightCircularArrow,
    Chevron,
    DoubleChevron,
    NotchedRightArrow,
    NotchedLeftArrow,
    NotchedUpArrow,
    NotchedDownArrow,
    PentagonalArrow,
    HexagonalArrow,
    RoundedRectangularArrow,
    SwooshArrow,
    
    // Equation Shapes
    MathPlus,
    MathMinus,
    MathMultiply,
    MathDivide,
    MathEqual,
    MathNotEqual,
    MathLessThan,
    MathGreaterThan,
    MathLessThanOrEqual,
    MathGreaterThanOrEqual,
    MathPercent,
    MathInfinity,
    
    // Flowchart Shapes
    FlowchartProcess,
    FlowchartDecision,
    FlowchartData,
    FlowchartPredefinedProcess,
    FlowchartInternalStorage,
    FlowchartDocument,
    FlowchartMultidocument,
    FlowchartTerminator,
    FlowchartPreparation,
    FlowchartManualInput,
    FlowchartManualOperation,
    FlowchartConnector,
    FlowchartOffpageConnector,
    FlowchartCard,
    FlowchartPunchedTape,
    FlowchartSummingJunction,
    FlowchartOr,
    FlowchartExtract,
    FlowchartMerge,
    FlowchartCollate,
    FlowchartSort,
    FlowchartDelay,
    FlowchartSequentialAccessStorage,
    FlowchartMagneticDisk,
    FlowchartDirectAccessStorage,
    FlowchartDisplay,
    FlowchartOnlineStorage,
    
    // Stars and Banners
    Ribbon,
    Ribbon2,
    EllipseRibbon,
    EllipseRibbon2,
    LeftRightRibbon,
    VerticalScroll,
    HorizontalScroll,
    Wave,
    DoubleWave,
    Plus,
    Plaque,
    Can,
    Cube,
    Bevel,
    Frame,
    HalfFrame,
    NoSymbol,
    FoldedCorner,
    
    // Callouts
    RectangularCallout,
    RoundRectangularCallout,
    OvalCallout,
    CloudCallout,
    LineCallout1,
    LineCallout2,
    LineCallout3,
    LineCalloutWithBorder1,
    LineCalloutWithBorder2,
    LineCalloutWithBorder3,
    AccentCallout1,
    AccentCallout2,
    AccentCallout3,
    AccentBorderCallout1,
    AccentBorderCallout2,
    AccentBorderCallout3,
    WedgeRectangularCallout,
    WedgeRoundRectangularCallout,
    WedgeEllipseCallout,
    
    // Action Buttons
    ActionButtonBlank,
    ActionButtonHome,
    ActionButtonHelp,
    ActionButtonInformation,
    ActionButtonForwardNext,
    ActionButtonBackPrevious,
    ActionButtonEnd,
    ActionButtonBeginning,
    ActionButtonReturn,
    ActionButtonDocument,
    ActionButtonSound,
    ActionButtonMovie,
    
    // Miscellaneous
    Gear6,
    Gear9,
    Funnel,
    Pie,
    PieWedge,
    LeftBracket,
    RightBracket,
    LeftBrace,
    RightBrace,
    BracketPair,
    BracePair,
    StraightConnector1,
    BentConnector2,
    BentConnector3,
    BentConnector4,
    BentConnector5,
    CornerTabs,
    SquareTabs,
    PlaqueTabs,
    ChartX,
    ChartStar,
    ChartPlus,
    
    // Custom/Unknown
    #[serde(other)]
    Custom(String),
}

impl ShapeType {
    /// Returns the OOXML shape type string for this variant.
    pub fn to_ooxml_string(&self) -> String {
        match self {
            ShapeType::Rectangle => "rect".to_string(),
            ShapeType::RoundRectangle => "roundRect".to_string(),
            ShapeType::Ellipse => "ellipse".to_string(),
            ShapeType::Triangle => "triangle".to_string(),
            ShapeType::RightTriangle => "rtTriangle".to_string(),
            ShapeType::Parallelogram => "parallelogram".to_string(),
            ShapeType::Trapezoid => "trapezoid".to_string(),
            ShapeType::Diamond => "diamond".to_string(),
            ShapeType::Pentagon => "pentagon".to_string(),
            ShapeType::Hexagon => "hexagon".to_string(),
            ShapeType::Heptagon => "heptagon".to_string(),
            ShapeType::Octagon => "octagon".to_string(),
            ShapeType::Decagon => "decagon".to_string(),
            ShapeType::Dodecagon => "dodecagon".to_string(),
            ShapeType::Star4 => "star4".to_string(),
            ShapeType::Star5 => "star5".to_string(),
            ShapeType::Star6 => "star6".to_string(),
            ShapeType::Star7 => "star7".to_string(),
            ShapeType::Star8 => "star8".to_string(),
            ShapeType::Star10 => "star10".to_string(),
            ShapeType::Star12 => "star12".to_string(),
            ShapeType::Star16 => "star16".to_string(),
            ShapeType::Star24 => "star24".to_string(),
            ShapeType::Star32 => "star32".to_string(),
            ShapeType::RightArrow => "rightArrow".to_string(),
            ShapeType::StripedRightArrow => "stripedRightArrow".to_string(),
            ShapeType::QuadArrow => "quadArrow".to_string(),
            ShapeType::LeftArrow => "leftArrow".to_string(),
            ShapeType::UpArrow => "upArrow".to_string(),
            ShapeType::DownArrow => "downArrow".to_string(),
            ShapeType::LeftRightArrow => "leftRightArrow".to_string(),
            ShapeType::UpDownArrow => "upDownArrow".to_string(),
            ShapeType::LeftUpArrow => "leftUpArrow".to_string(),
            ShapeType::BentArrow => "bentArrow".to_string(),
            ShapeType::UTurnArrow => "uturnArrow".to_string(),
            ShapeType::CircularArrow => "circularArrow".to_string(),
            ShapeType::Chevron => "chevron".to_string(),
            ShapeType::DoubleChevron => "doubleChevron".to_string(),
            ShapeType::FlowchartProcess => "flowChartProcess".to_string(),
            ShapeType::FlowchartDecision => "flowChartDecision".to_string(),
            ShapeType::FlowchartData => "flowChartData".to_string(),
            ShapeType::FlowchartTerminator => "flowChartTerminator".to_string(),
            ShapeType::FlowchartDocument => "flowChartDocument".to_string(),
            ShapeType::RectangularCallout => "callout1".to_string(),
            ShapeType::RoundRectangularCallout => "callout2".to_string(),
            ShapeType::OvalCallout => "callout3".to_string(),
            ShapeType::CloudCallout => "cloudCallout".to_string(),
            ShapeType::ActionButtonBlank => "actionButtonBlank".to_string(),
            ShapeType::ActionButtonHome => "actionButtonHome".to_string(),
            ShapeType::Gear6 => "gear6".to_string(),
            ShapeType::Gear9 => "gear9".to_string(),
            ShapeType::Funnel => "funnel".to_string(),
            ShapeType::Pie => "pie".to_string(),
            ShapeType::Cube => "cube".to_string(),
            ShapeType::Bevel => "bevel".to_string(),
            ShapeType::Frame => "frame".to_string(),
            ShapeType::HalfFrame => "halfFrame".to_string(),
            ShapeType::NoSymbol => "noSymbol".to_string(),
            ShapeType::Custom(s) => s.clone(),
            _ => "rect".to_string(), // Default fallback
        }
    }

    /// Creates a ShapeType from an OOXML shape type string.
    pub fn from_ooxml_string(s: &str) -> Self {
        match s {
            "rect" => ShapeType::Rectangle,
            "roundRect" => ShapeType::RoundRectangle,
            "ellipse" => ShapeType::Ellipse,
            "triangle" => ShapeType::Triangle,
            "rtTriangle" => ShapeType::RightTriangle,
            "parallelogram" => ShapeType::Parallelogram,
            "trapezoid" => ShapeType::Trapezoid,
            "diamond" => ShapeType::Diamond,
            "pentagon" => ShapeType::Pentagon,
            "hexagon" => ShapeType::Hexagon,
            "heptagon" => ShapeType::Heptagon,
            "octagon" => ShapeType::Octagon,
            "decagon" => ShapeType::Decagon,
            "dodecagon" => ShapeType::Dodecagon,
            "star4" => ShapeType::Star4,
            "star5" => ShapeType::Star5,
            "star6" => ShapeType::Star6,
            "star7" => ShapeType::Star7,
            "star8" => ShapeType::Star8,
            "star10" => ShapeType::Star10,
            "star12" => ShapeType::Star12,
            "star16" => ShapeType::Star16,
            "star24" => ShapeType::Star24,
            "star32" => ShapeType::Star32,
            "rightArrow" => ShapeType::RightArrow,
            "stripedRightArrow" => ShapeType::StripedRightArrow,
            "quadArrow" => ShapeType::QuadArrow,
            "leftArrow" => ShapeType::LeftArrow,
            "upArrow" => ShapeType::UpArrow,
            "downArrow" => ShapeType::DownArrow,
            "leftRightArrow" => ShapeType::LeftRightArrow,
            "upDownArrow" => ShapeType::UpDownArrow,
            "leftUpArrow" => ShapeType::LeftUpArrow,
            "bentArrow" => ShapeType::BentArrow,
            "uturnArrow" => ShapeType::UTurnArrow,
            "circularArrow" => ShapeType::CircularArrow,
            "chevron" => ShapeType::Chevron,
            "doubleChevron" => ShapeType::DoubleChevron,
            "flowChartProcess" => ShapeType::FlowchartProcess,
            "flowChartDecision" => ShapeType::FlowchartDecision,
            "flowChartData" => ShapeType::FlowchartData,
            "flowChartTerminator" => ShapeType::FlowchartTerminator,
            "flowChartDocument" => ShapeType::FlowchartDocument,
            "callout1" => ShapeType::RectangularCallout,
            "callout2" => ShapeType::RoundRectangularCallout,
            "callout3" => ShapeType::OvalCallout,
            "cloudCallout" => ShapeType::CloudCallout,
            "actionButtonBlank" => ShapeType::ActionButtonBlank,
            "actionButtonHome" => ShapeType::ActionButtonHome,
            "gear6" => ShapeType::Gear6,
            "gear9" => ShapeType::Gear9,
            "funnel" => ShapeType::Funnel,
            "pie" => ShapeType::Pie,
            "cube" => ShapeType::Cube,
            "bevel" => ShapeType::Bevel,
            "frame" => ShapeType::Frame,
            "halfFrame" => ShapeType::HalfFrame,
            "noSymbol" => ShapeType::NoSymbol,
            other => ShapeType::Custom(other.to_string()),
        }
    }

    /// Returns true if this shape type is a basic geometric shape.
    pub fn is_basic_shape(&self) -> bool {
        matches!(self, 
            ShapeType::Rectangle | ShapeType::RoundRectangle | ShapeType::Ellipse |
            ShapeType::Triangle | ShapeType::RightTriangle | ShapeType::Parallelogram |
            ShapeType::Trapezoid | ShapeType::Diamond | ShapeType::Pentagon |
            ShapeType::Hexagon | ShapeType::Heptagon | ShapeType::Octagon |
            ShapeType::Decagon | ShapeType::Dodecagon
        )
    }

    /// Returns true if this shape type is a star.
    pub fn is_star(&self) -> bool {
        matches!(self,
            ShapeType::Star4 | ShapeType::Star5 | ShapeType::Star6 |
            ShapeType::Star7 | ShapeType::Star8 | ShapeType::Star10 |
            ShapeType::Star12 | ShapeType::Star16 | ShapeType::Star24 |
            ShapeType::Star32
        )
    }

    /// Returns true if this shape type is an arrow.
    pub fn is_arrow(&self) -> bool {
        matches!(self,
            ShapeType::RightArrow | ShapeType::StripedRightArrow |
            ShapeType::LeftArrow | ShapeType::UpArrow | ShapeType::DownArrow |
            ShapeType::LeftRightArrow | ShapeType::UpDownArrow |
            ShapeType::LeftUpArrow | ShapeType::BentArrow | ShapeType::UTurnArrow |
            ShapeType::CircularArrow | ShapeType::QuadArrow
        )
    }

    /// Returns true if this shape type is a flowchart shape.
    pub fn is_flowchart(&self) -> bool {
        matches!(self,
            ShapeType::FlowchartProcess | ShapeType::FlowchartDecision |
            ShapeType::FlowchartData | ShapeType::FlowchartPredefinedProcess |
            ShapeType::FlowchartInternalStorage | ShapeType::FlowchartDocument |
            ShapeType::FlowchartMultidocument | ShapeType::FlowchartTerminator |
            ShapeType::FlowchartPreparation | ShapeType::FlowchartManualInput |
            ShapeType::FlowchartManualOperation | ShapeType::FlowchartConnector |
            ShapeType::FlowchartOffpageConnector | ShapeType::FlowchartCard |
            ShapeType::FlowchartPunchedTape | ShapeType::FlowchartSummingJunction |
            ShapeType::FlowchartOr | ShapeType::FlowchartExtract |
            ShapeType::FlowchartMerge | ShapeType::FlowchartCollate |
            ShapeType::FlowchartSort | ShapeType::FlowchartDelay |
            ShapeType::FlowchartSequentialAccessStorage | ShapeType::FlowchartMagneticDisk |
            ShapeType::FlowchartDirectAccessStorage | ShapeType::FlowchartDisplay |
            ShapeType::FlowchartOnlineStorage
        )
    }

    /// Returns true if this shape type is a callout.
    pub fn is_callout(&self) -> bool {
        matches!(self,
            ShapeType::RectangularCallout | ShapeType::RoundRectangularCallout |
            ShapeType::OvalCallout | ShapeType::CloudCallout |
            ShapeType::LineCallout1 | ShapeType::LineCallout2 | ShapeType::LineCallout3 |
            ShapeType::LineCalloutWithBorder1 | ShapeType::LineCalloutWithBorder2 |
            ShapeType::LineCalloutWithBorder3 | ShapeType::AccentCallout1 |
            ShapeType::AccentCallout2 | ShapeType::AccentCallout3 |
            ShapeType::AccentBorderCallout1 | ShapeType::AccentBorderCallout2 |
            ShapeType::AccentBorderCallout3 | ShapeType::WedgeRectangularCallout |
            ShapeType::WedgeRoundRectangularCallout | ShapeType::WedgeEllipseCallout
        )
    }

    /// Returns true if this shape type is an action button.
    pub fn is_action_button(&self) -> bool {
        matches!(self,
            ShapeType::ActionButtonBlank | ShapeType::ActionButtonHome |
            ShapeType::ActionButtonHelp | ShapeType::ActionButtonInformation |
            ShapeType::ActionButtonForwardNext | ShapeType::ActionButtonBackPrevious |
            ShapeType::ActionButtonEnd | ShapeType::ActionButtonBeginning |
            ShapeType::ActionButtonReturn | ShapeType::ActionButtonDocument |
            ShapeType::ActionButtonSound | ShapeType::ActionButtonMovie
        )
    }
}

impl std::fmt::Display for ShapeType {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{:?}", self)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_rectangle_conversion() {
        let shape = ShapeType::Rectangle;
        assert_eq!(shape.to_ooxml_string(), "rect");
        assert_eq!(ShapeType::from_ooxml_string("rect"), ShapeType::Rectangle);
    }

    #[test]
    fn test_star_detection() {
        assert!(ShapeType::Star5.is_star());
        assert!(!ShapeType::Rectangle.is_star());
    }

    #[test]
    fn test_arrow_detection() {
        assert!(ShapeType::RightArrow.is_arrow());
        assert!(ShapeType::LeftRightArrow.is_arrow());
        assert!(!ShapeType::Ellipse.is_arrow());
    }

    #[test]
    fn test_flowchart_detection() {
        assert!(ShapeType::FlowchartProcess.is_flowchart());
        assert!(ShapeType::FlowchartDecision.is_flowchart());
        assert!(!ShapeType::Rectangle.is_flowchart());
    }

    #[test]
    fn test_custom_shape() {
        let custom = ShapeType::Custom("myCustomShape".to_string());
        assert_eq!(custom.to_ooxml_string(), "myCustomShape");
        assert_eq!(ShapeType::from_ooxml_string("unknownShape"), 
                   ShapeType::Custom("unknownShape".to_string()));
    }
}
