/// Direction of a smart alignment guide line on the slide canvas.
enum AlignmentGuideAxis { horizontal, vertical }

/// Origin category for a smart alignment guide.
enum AlignmentGuideSource { slide, object }

/// Visual guide emitted when the selected object aligns with slide or object anchors.
class AlignmentGuide {
  final AlignmentGuideAxis axis;
  final AlignmentGuideSource source;
  final double position;
  final String label;

  const AlignmentGuide({
    required this.axis,
    required this.source,
    required this.position,
    required this.label,
  });
}
