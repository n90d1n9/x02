import 'dart:async';

import 'package:flutter/material.dart';

/// Describes one executable action shown in the document command palette.
class DocumentCommand {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final FutureOr<void> Function() onSelected;
  final String category;
  final String? shortcut;
  final List<String> keywords;
  final bool enabled;
  final String? disabledLabel;
  final String? disabledReason;
  final IconData? disabledIcon;
  final bool suggested;
  final int suggestionPriority;

  const DocumentCommand({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onSelected,
    this.category = 'General',
    this.shortcut,
    this.keywords = const [],
    this.enabled = true,
    this.disabledLabel,
    this.disabledReason,
    this.disabledIcon,
    this.suggested = false,
    this.suggestionPriority = 0,
  });

  bool matches(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return true;

    return _searchableText.contains(normalizedQuery);
  }

  String get _searchableText {
    return [
      title,
      subtitle,
      category,
      ?shortcut,
      ?disabledLabel,
      ?disabledReason,
      ...keywords,
    ].join(' ').toLowerCase();
  }
}
