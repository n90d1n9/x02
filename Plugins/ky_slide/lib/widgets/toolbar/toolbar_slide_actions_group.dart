import 'package:flutter/material.dart';

import 'ribbon_icon_button.dart';

/// Ribbon group for creating, duplicating, and deleting slides.
class ToolbarSlideActionsGroup extends StatelessWidget {
  final bool canDeleteSlide;
  final VoidCallback onAddSlide;
  final VoidCallback onDuplicateSlide;
  final VoidCallback onDeleteSlide;
  final bool compact;

  const ToolbarSlideActionsGroup({
    super.key,
    required this.canDeleteSlide,
    required this.onAddSlide,
    required this.onDuplicateSlide,
    required this.onDeleteSlide,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RibbonIconButton(
          icon: Icons.add_to_photos_outlined,
          tooltip: 'New Slide',
          onPressed: onAddSlide,
          compact: compact,
        ),
        RibbonIconButton(
          icon: Icons.content_copy,
          tooltip: 'Duplicate Slide',
          onPressed: onDuplicateSlide,
          compact: compact,
        ),
        RibbonIconButton(
          icon: Icons.delete_outline,
          tooltip: 'Delete Slide',
          onPressed: canDeleteSlide ? onDeleteSlide : null,
          compact: compact,
        ),
      ],
    );
  }
}
