import 'package:flutter/material.dart';

/// Defines reusable width values for editor workspace utility panels.
abstract final class DocumentWorkspacePanelWidthScale {
  static const compact = 320.0;
  static const comfortable = 360.0;
  static const expanded = 520.0;

  static double clamp(double width) {
    if (width.isNaN) return comfortable;
    return width.clamp(compact, expanded).toDouble();
  }
}

/// Describes a quick width preset for the side utility panel dock.
enum DocumentWorkspacePanelWidthPreset {
  compact(
    width: DocumentWorkspacePanelWidthScale.compact,
    label: 'Compact',
    description: 'More room for the document canvas',
    icon: Icons.vertical_split_outlined,
  ),
  comfortable(
    width: DocumentWorkspacePanelWidthScale.comfortable,
    label: 'Comfortable',
    description: 'Balanced panel and canvas space',
    icon: Icons.splitscreen_outlined,
  ),
  expanded(
    width: DocumentWorkspacePanelWidthScale.expanded,
    label: 'Wide',
    description: 'More room for panel controls',
    icon: Icons.view_sidebar_outlined,
  );

  final double width;
  final String label;
  final String description;
  final IconData icon;

  const DocumentWorkspacePanelWidthPreset({
    required this.width,
    required this.label,
    required this.description,
    required this.icon,
  });

  static DocumentWorkspacePanelWidthPreset closestTo(double width) {
    final normalizedWidth = DocumentWorkspacePanelWidthScale.clamp(width);
    return values.reduce((closest, preset) {
      final currentDistance = (preset.width - normalizedWidth).abs();
      final closestDistance = (closest.width - normalizedWidth).abs();
      return currentDistance < closestDistance ? preset : closest;
    });
  }
}
