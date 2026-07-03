import 'package:flutter/material.dart';

class WidgetGalleryCategory {
  final String id;
  final String label;
  final IconData icon;

  const WidgetGalleryCategory({
    required this.id,
    required this.label,
    required this.icon,
  });
}

class WidgetGalleryItem {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final String category;
  final Color color;

  const WidgetGalleryItem({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    required this.color,
  });
}

const widgetGalleryCategories = <WidgetGalleryCategory>[
  WidgetGalleryCategory(id: 'all', label: 'All', icon: Icons.apps),
  WidgetGalleryCategory(id: 'basic', label: 'Basic', icon: Icons.text_fields),
  WidgetGalleryCategory(id: 'media', label: 'Media', icon: Icons.image),
  WidgetGalleryCategory(id: 'embed', label: 'Embeds', icon: Icons.language),
  WidgetGalleryCategory(id: 'chart', label: 'Charts', icon: Icons.bar_chart),
  WidgetGalleryCategory(
    id: 'advanced',
    label: 'Advanced',
    icon: Icons.auto_awesome,
  ),
];
