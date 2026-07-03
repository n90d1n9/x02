import 'package:flutter/material.dart';

import '../../models/slide_layout.dart';
import '../previews/slide_layout_preview_thumbnail.dart';
import 'toolbar_gallery_tile.dart';

/// Ribbon gallery for creating slides from predefined layout recipes.
class ToolbarLayoutGallery extends StatelessWidget {
  final List<SlideLayoutRecipe> layouts;
  final Color accentColor;
  final ValueChanged<SlideLayoutType> onCreateLayout;
  final bool compact;

  const ToolbarLayoutGallery({
    super.key,
    required this.layouts,
    required this.accentColor,
    required this.onCreateLayout,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final layout in layouts)
          ToolbarGalleryTile(
            label: layout.name,
            tooltip: 'Create ${layout.name} layout slide',
            compact: compact,
            borderColor: Colors.white.withValues(alpha: 0.08),
            compactWidth: 74,
            width: 82,
            compactPreviewWidth: 54,
            previewWidth: 58,
            preview: SlideLayoutPreviewThumbnail(
              type: layout.type,
              accentColor: accentColor,
            ),
            onPressed: () => onCreateLayout(layout.type),
          ),
      ],
    );
  }
}
