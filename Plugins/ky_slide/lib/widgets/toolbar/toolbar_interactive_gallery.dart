import 'package:flutter/material.dart';

import '../../models/enums.dart';
import '../previews/interactive_preview_thumbnail.dart';
import 'toolbar_gallery_tile.dart';

/// Ribbon gallery for inserting interactive presentation components.
class ToolbarInteractiveGallery extends StatelessWidget {
  final Color accentColor;
  final Color secondaryColor;
  final ValueChanged<InteractiveType> onCreateInteractive;
  final bool compact;

  const ToolbarInteractiveGallery({
    super.key,
    required this.accentColor,
    required this.secondaryColor,
    required this.onCreateInteractive,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final options = [
      _InteractiveOption(
        type: InteractiveType.hotspot,
        label: 'Hotspot',
        color: accentColor,
      ),
      _InteractiveOption(
        type: InteractiveType.poll,
        label: 'Poll',
        color: secondaryColor,
      ),
      const _InteractiveOption(
        type: InteractiveType.quiz,
        label: 'Quiz',
        color: Color(0xFFF59E0B),
      ),
      const _InteractiveOption(
        type: InteractiveType.countdown,
        label: 'Timer',
        color: Color(0xFFEC4899),
      ),
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final option in options)
          ToolbarGalleryTile(
            label: option.label,
            tooltip: 'Insert ${option.label} interactive',
            compact: compact,
            borderColor: option.color.withValues(alpha: 0.28),
            preview: InteractivePreviewThumbnail(
              type: option.type,
              accentColor: option.color,
              secondaryColor: secondaryColor,
            ),
            onPressed: () => onCreateInteractive(option.type),
          ),
      ],
    );
  }
}

/// Toolbar interactive option metadata.
class _InteractiveOption {
  final InteractiveType type;
  final String label;
  final Color color;

  const _InteractiveOption({
    required this.type,
    required this.label,
    required this.color,
  });
}
