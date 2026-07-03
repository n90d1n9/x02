import 'package:flutter/material.dart';

import '../state/sheet_sidebar_provider.dart';

enum SheetCommandCategory { file, edit, view, data, formula, review, tools }

enum SheetCommandAction {
  openSidebarPanel,
  undo,
  redo,
  zoomIn,
  zoomOut,
  quickActions,
}

class SheetCommand {
  const SheetCommand({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.action,
    required this.icon,
    this.shortcutLabel,
    this.sidebarPanel,
    this.keywords = const [],
  });

  final String id;
  final String title;
  final String description;
  final SheetCommandCategory category;
  final SheetCommandAction action;
  final IconData icon;
  final String? shortcutLabel;
  final SheetSidebarPanel? sidebarPanel;
  final List<String> keywords;

  String get categoryLabel {
    return switch (category) {
      SheetCommandCategory.file => 'File',
      SheetCommandCategory.edit => 'Edit',
      SheetCommandCategory.view => 'View',
      SheetCommandCategory.data => 'Data',
      SheetCommandCategory.formula => 'Formula',
      SheetCommandCategory.review => 'Review',
      SheetCommandCategory.tools => 'Tools',
    };
  }

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;

    final haystack = [
      id,
      title,
      description,
      categoryLabel,
      ?shortcutLabel,
      ...keywords,
    ].join(' ').toLowerCase();

    return normalized
        .split(RegExp(r'\s+'))
        .every((token) => haystack.contains(token));
  }
}

class SheetCommandAvailability {
  const SheetCommandAvailability({this.disabledReasons = const {}});

  final Map<String, String> disabledReasons;

  bool isEnabled(SheetCommand command) {
    return !disabledReasons.containsKey(command.id);
  }

  String? reasonFor(SheetCommand command) {
    return disabledReasons[command.id];
  }
}
