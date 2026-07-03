import 'package:flutter/material.dart';

import '../../models/enums.dart';
import '../previews/chart_preview_thumbnail.dart';
import 'toolbar_gallery_tile.dart';

/// Ribbon gallery for inserting common chart components.
class ToolbarChartGallery extends StatelessWidget {
  final List<Color> palette;
  final ValueChanged<ChartType> onCreateChart;
  final bool compact;

  const ToolbarChartGallery({
    super.key,
    required this.palette,
    required this.onCreateChart,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    const options = [
      _ChartOption(type: ChartType.line, label: 'Line'),
      _ChartOption(type: ChartType.bar, label: 'Bar'),
      _ChartOption(type: ChartType.pie, label: 'Pie'),
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final option in options)
          ToolbarGalleryTile(
            label: option.label,
            tooltip: 'Insert ${option.label} Chart',
            compact: compact,
            borderColor: _accentColor(palette).withValues(alpha: 0.28),
            preview: ChartPreviewThumbnail(type: option.type, colors: palette),
            onPressed: () => onCreateChart(option.type),
          ),
      ],
    );
  }
}

/// Toolbar chart option metadata.
class _ChartOption {
  final ChartType type;
  final String label;

  const _ChartOption({required this.type, required this.label});
}

Color _accentColor(List<Color> palette) {
  if (palette.isEmpty) return const Color(0xFF38BDF8);
  return palette[0];
}
