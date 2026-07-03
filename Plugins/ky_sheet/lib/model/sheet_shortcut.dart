import 'package:flutter/material.dart';

/// Categories used to group supported spreadsheet keyboard shortcuts.
enum SheetShortcutCategory { editing, navigation, sheets, tools }

/// Human-readable category labels for shortcut guide sections.
extension SheetShortcutCategoryLabel on SheetShortcutCategory {
  String get label {
    return switch (this) {
      SheetShortcutCategory.editing => 'Editing',
      SheetShortcutCategory.navigation => 'Navigation',
      SheetShortcutCategory.sheets => 'Sheets',
      SheetShortcutCategory.tools => 'Tools',
    };
  }
}

/// Shared shortcut labels used by menus, command surfaces, and help panels.
class SheetShortcutLabels {
  const SheetShortcutLabels._();

  static const undo = 'Ctrl+Z';
  static const redo = 'Ctrl+Y';
  static const bold = 'Ctrl+B';
  static const italic = 'Ctrl+I';
  static const underline = 'Ctrl+U';
  static const editCell = 'F2';
  static const copy = 'Ctrl+C';
  static const cut = 'Ctrl+X';
  static const paste = 'Ctrl+V';
  static const clearSelection = 'Del';
  static const findReplace = 'Ctrl+F';
  static const replace = 'Ctrl+H';
  static const sortFilter = 'Ctrl+Shift+L';
  static const commandPalette = 'Ctrl+K';
  static const shortcuts = 'Ctrl+/';
  static const help = 'F1';
  static const closePanel = 'Esc';
  static const moveSelection = 'Arrow Keys';
  static const extendSelection = 'Shift+Arrow';
  static const moveDown = 'Enter';
  static const moveUp = 'Shift+Enter';
  static const moveRight = 'Tab';
  static const moveLeft = 'Shift+Tab';
  static const previousVisibleSheet = 'Ctrl+Page Up';
  static const nextVisibleSheet = 'Ctrl+Page Down';
  static const previousVisibleSheetMac = 'Cmd+Shift+[';
  static const nextVisibleSheetMac = 'Cmd+Shift+]';
}

/// Describes one supported spreadsheet keyboard shortcut.
class SheetShortcut {
  const SheetShortcut({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.icon,
    required this.shortcutLabel,
    this.keywords = const [],
  });

  final String id;
  final String title;
  final String description;
  final SheetShortcutCategory category;
  final IconData icon;
  final String shortcutLabel;
  final List<String> keywords;

  String get categoryLabel => category.label;

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;

    final haystack = [
      id,
      title,
      description,
      categoryLabel,
      shortcutLabel,
      ...keywords,
    ].join(' ').toLowerCase();

    return normalized
        .split(RegExp(r'\s+'))
        .every((token) => haystack.contains(token));
  }
}
