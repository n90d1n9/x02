import 'package:flutter/material.dart';

import 'widget_gallery_item.dart';

class WidgetGalleryCategoryChip extends StatelessWidget {
  final WidgetGalleryCategory category;
  final bool selected;
  final ValueChanged<String> onSelected;

  const WidgetGalleryCategoryChip({
    super.key,
    required this.category,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        avatar: Icon(category.icon, size: 18),
        label: Text(category.label),
        selected: selected,
        onSelected: (_) => onSelected(category.id),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        selectedColor: Theme.of(context).colorScheme.primaryContainer,
      ),
    );
  }
}
