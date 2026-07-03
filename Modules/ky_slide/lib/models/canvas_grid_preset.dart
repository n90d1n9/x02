/// Grid density presets shared by canvas rendering and snap-to-grid behavior.
enum CanvasGridPreset {
  compact(label: 'Compact', spacing: 10),
  comfortable(label: 'Comfortable', spacing: 20),
  spacious(label: 'Spacious', spacing: 40);

  final String label;
  final double spacing;

  const CanvasGridPreset({required this.label, required this.spacing});

  String get spacingLabel => '${spacing.round()} px';
}
