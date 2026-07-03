/// A flat list of draw commands produced by the renderer.
/// A frontend (canvas, SVG, WebGPU) consumes these to paint the slide.
use crate::scene::{Point, Rect, Transform};
use crate::shape::{Color, Fill, Geometry, Shape, Stroke, TextAlign, VerticalAlign};
use crate::slide::Slide;
use serde::{Deserialize, Serialize};

// ── Draw commands ─────────────────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum DrawCommand {
    /// Push a transform onto the stack.
    PushTransform(Transform),
    /// Pop the most recently pushed transform.
    PopTransform,
    /// Set the global opacity for subsequent commands.
    SetOpacity(f64),
    /// Fill a rectangle.
    FillRect {
        rect: Rect,
        fill: Fill,
        corner_radius: f64,
    },
    /// Stroke a rectangle outline.
    StrokeRect {
        rect: Rect,
        stroke: Stroke,
        corner_radius: f64,
    },
    /// Fill an ellipse inscribed in `rect`.
    FillEllipse { rect: Rect, fill: Fill },
    /// Stroke an ellipse outline.
    StrokeEllipse { rect: Rect, stroke: Stroke },
    /// Draw a straight line.
    DrawLine {
        from: Point,
        to: Point,
        stroke: Stroke,
    },
    /// Draw a closed polygon (points are absolute slide coords).
    DrawPolygon {
        points: Vec<Point>,
        fill: Fill,
        stroke: Option<Stroke>,
    },
    /// Draw an SVG path string.
    DrawPath {
        path: String,
        fill: Fill,
        stroke: Option<Stroke>,
    },
    /// Draw a text run inside a bounding box.
    DrawText {
        rect: Rect,
        runs: Vec<TextRunCmd>,
        align: TextAlign,
        vertical_align: VerticalAlign,
        padding: f64,
    },
    /// Draw an image inside a bounding box.
    DrawImage {
        src: String,
        rect: Rect,
        fit: crate::shape::ImageFit,
    },
}

/// A single styled text span for the renderer.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TextRunCmd {
    pub text: String,
    pub bold: bool,
    pub italic: bool,
    pub underline: bool,
    pub font_size: f64,
    pub font_family: String,
    pub color: Color,
}

// ── Renderer ──────────────────────────────────────────────────────────────────

/// Walks the slide's scene graph and emits a flat `Vec<DrawCommand>`.
pub struct SlideRenderer;

impl SlideRenderer {
    pub fn new() -> Self {
        Self
    }

    /// Render a full slide into a list of draw commands.
    pub fn render(&self, slide: &Slide) -> Vec<DrawCommand> {
        let mut cmds: Vec<DrawCommand> = Vec::new();

        // 1. Background
        cmds.push(DrawCommand::FillRect {
            rect: Rect::new(0.0, 0.0, slide.size.width, slide.size.height),
            fill: slide.background.clone(),
            corner_radius: 0.0,
        });

        // 2. Shapes in z-order (bottom → top)
        for shape in slide.shapes_in_draw_order() {
            self.render_shape(shape, &mut cmds);
        }

        cmds
    }

    fn render_shape(&self, shape: &Shape, cmds: &mut Vec<DrawCommand>) {
        // Push per-shape transform
        cmds.push(DrawCommand::PushTransform(shape.transform));

        // Opacity
        if shape.opacity < 1.0 {
            cmds.push(DrawCommand::SetOpacity(shape.opacity));
        }

        match &shape.geometry {
            Geometry::Rectangle { corner_radius } => {
                cmds.push(DrawCommand::FillRect {
                    rect: shape.bounds,
                    fill: shape.fill.clone(),
                    corner_radius: *corner_radius,
                });
                if let Some(stroke) = &shape.stroke {
                    cmds.push(DrawCommand::StrokeRect {
                        rect: shape.bounds,
                        stroke: stroke.clone(),
                        corner_radius: *corner_radius,
                    });
                }
            }

            Geometry::Ellipse => {
                cmds.push(DrawCommand::FillEllipse {
                    rect: shape.bounds,
                    fill: shape.fill.clone(),
                });
                if let Some(stroke) = &shape.stroke {
                    cmds.push(DrawCommand::StrokeEllipse {
                        rect: shape.bounds,
                        stroke: stroke.clone(),
                    });
                }
            }

            Geometry::Line => {
                let from = shape.bounds.origin;
                let to = crate::scene::Point::new(
                    shape.bounds.origin.x + shape.bounds.size.width,
                    shape.bounds.origin.y + shape.bounds.size.height,
                );
                if let Some(stroke) = &shape.stroke {
                    cmds.push(DrawCommand::DrawLine {
                        from,
                        to,
                        stroke: stroke.clone(),
                    });
                }
            }

            Geometry::Polygon { points } => {
                // Convert relative (0..1) points to absolute slide coords
                let abs_pts: Vec<Point> = points
                    .iter()
                    .map(|(rx, ry)| {
                        Point::new(
                            shape.bounds.origin.x + rx * shape.bounds.size.width,
                            shape.bounds.origin.y + ry * shape.bounds.size.height,
                        )
                    })
                    .collect();
                cmds.push(DrawCommand::DrawPolygon {
                    points: abs_pts,
                    fill: shape.fill.clone(),
                    stroke: shape.stroke.clone(),
                });
            }

            Geometry::Path(svg_path) => {
                cmds.push(DrawCommand::DrawPath {
                    path: svg_path.clone(),
                    fill: shape.fill.clone(),
                    stroke: shape.stroke.clone(),
                });
            }
        }

        // Overlay text if present
        if let Some(text) = &shape.text {
            let runs = text
                .runs
                .iter()
                .map(|r| TextRunCmd {
                    text: r.text.clone(),
                    bold: r.bold,
                    italic: r.italic,
                    underline: r.underline,
                    font_size: r.font_size,
                    font_family: r.font_family.clone(),
                    color: r.color.clone(),
                })
                .collect();

            cmds.push(DrawCommand::DrawText {
                rect: shape.bounds,
                runs,
                align: text.align.clone(),
                vertical_align: text.vertical_align.clone(),
                padding: text.padding,
            });
        }

        // Handle image fill separately (image fit)
        if let Fill::Image { src, fit } = &shape.fill {
            cmds.push(DrawCommand::DrawImage {
                src: src.clone(),
                rect: shape.bounds,
                fit: fit.clone(),
            });
        }

        // Restore opacity
        if shape.opacity < 1.0 {
            cmds.push(DrawCommand::SetOpacity(1.0));
        }

        cmds.push(DrawCommand::PopTransform);
    }
}

impl Default for SlideRenderer {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::scene::Rect;
    use crate::shape::{Shape, TextBox};

    #[test]
    fn render_slide_includes_background_and_shape_commands() {
        let mut slide = Slide::new("slide-1");
        let mut shape = Shape::rect("shape-1", Rect::new(10.0, 20.0, 30.0, 40.0), "#ff0000");
        shape.text = Some(TextBox::plain("Hello"));
        slide.add_shape(shape);

        let commands = SlideRenderer::new().render(&slide);

        assert!(matches!(
            commands.first(),
            Some(DrawCommand::FillRect { .. })
        ));
        assert!(commands.iter().any(|cmd| matches!(
            cmd,
            DrawCommand::DrawText { runs, .. } if runs[0].text == "Hello"
        )));
        assert!(matches!(commands.last(), Some(DrawCommand::PopTransform)));
    }

    #[test]
    fn render_polygon_converts_relative_points_to_slide_space() {
        let mut slide = Slide::new("slide-1");
        slide.add_shape(Shape::new(
            "triangle",
            Geometry::Polygon {
                points: vec![(0.0, 0.0), (1.0, 0.0), (0.5, 1.0)],
            },
            Rect::new(10.0, 20.0, 100.0, 50.0),
        ));

        let commands = SlideRenderer::new().render(&slide);
        let polygon = commands
            .iter()
            .find_map(|cmd| match cmd {
                DrawCommand::DrawPolygon { points, .. } => Some(points),
                _ => None,
            })
            .unwrap();

        assert_eq!(polygon[0], Point::new(10.0, 20.0));
        assert_eq!(polygon[1], Point::new(110.0, 20.0));
        assert_eq!(polygon[2], Point::new(60.0, 70.0));
    }
}
