import 'package:flutter/material.dart';

/// A user-invokable editor command shown in the command palette.
class CommandPaletteAction {
  final String id;
  final String title;
  final String description;
  final String category;
  final IconData icon;
  final List<String> keywords;
  final String? shortcutLabel;
  final List<String> metadataLabels;
  final bool enabled;
  final VoidCallback onInvoke;

  const CommandPaletteAction({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.icon,
    required this.keywords,
    required this.onInvoke,
    this.shortcutLabel,
    this.metadataLabels = const [],
    this.enabled = true,
  });
}
