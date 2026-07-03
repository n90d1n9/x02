/// Display density options for slide thumbnails in the navigator rail.
enum SlideNavigatorDensity {
  compact(
    label: 'Compact',
    tooltip: 'Compact thumbnails',
    previewHeight: 58,
    cardVerticalMargin: 4,
    headerGap: 7,
  ),
  comfortable(
    label: 'Comfortable',
    tooltip: 'Comfortable thumbnails',
    previewHeight: 82,
    cardVerticalMargin: 5,
    headerGap: 9,
  );

  final String label;
  final String tooltip;
  final double previewHeight;
  final double cardVerticalMargin;
  final double headerGap;

  const SlideNavigatorDensity({
    required this.label,
    required this.tooltip,
    required this.previewHeight,
    required this.cardVerticalMargin,
    required this.headerGap,
  });
}
