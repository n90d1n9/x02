import 'package:flutter/material.dart';

class DocumentKeyboardShortcut {
  final String label;
  final List<String> keys;
  final List<String> keywords;

  const DocumentKeyboardShortcut({
    required this.label,
    required this.keys,
    this.keywords = const [],
  });

  bool matches(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return true;

    return _searchableText.contains(normalizedQuery);
  }

  String get _searchableText {
    return [label, keys.join(' '), ...keywords].join(' ').toLowerCase();
  }
}

class DocumentKeyboardShortcutGroup {
  final String title;
  final IconData icon;
  final List<DocumentKeyboardShortcut> shortcuts;

  const DocumentKeyboardShortcutGroup({
    required this.title,
    required this.icon,
    required this.shortcuts,
  });

  DocumentKeyboardShortcutGroup filtered(String query) {
    return DocumentKeyboardShortcutGroup(
      title: title,
      icon: icon,
      shortcuts: shortcuts
          .where((shortcut) => shortcut.matches(query))
          .toList(),
    );
  }
}
