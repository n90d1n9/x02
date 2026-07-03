import 'package:flutter/material.dart';

import '../../models/component.dart';
import '../previews/shape_preview_thumbnail.dart';
import 'toolbar_gallery_tile.dart';

/// Ribbon gallery for inserting shape components with visual previews.
class ToolbarShapeGallery extends StatelessWidget {
  final Color accentColor;
  final Color secondaryColor;
  final ValueChanged<ComponentType> onCreateShape;
  final bool compact;

  const ToolbarShapeGallery({
    super.key,
    required this.accentColor,
    required this.secondaryColor,
    required this.onCreateShape,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final options = [
      _ShapeOption(
        type: ComponentType.shape,
        label: 'Rectangle',
        color: accentColor,
      ),
      _ShapeOption(
        type: ComponentType.circle,
        label: 'Circle',
        color: secondaryColor,
      ),
      const _ShapeOption(
        type: ComponentType.triangle,
        label: 'Triangle',
        color: Color(0xFFF59E0B),
      ),
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final option in options)
          ToolbarGalleryTile(
            label: option.label,
            tooltip: 'Insert ${option.label} shape',
            compact: compact,
            borderColor: option.color.withValues(alpha: 0.28),
            preview: ShapePreviewThumbnail(
              type: option.type,
              accentColor: option.color,
            ),
            onPressed: () => onCreateShape(option.type),
          ),
      ],
    );
  }
}

/// Toolbar shape option metadata.
class _ShapeOption {
  final ComponentType type;
  final String label;
  final Color color;

  const _ShapeOption({
    required this.type,
    required this.label,
    required this.color,
  });
}
