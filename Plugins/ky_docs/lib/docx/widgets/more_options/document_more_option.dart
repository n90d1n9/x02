import 'package:flutter/material.dart';

/// Identifies a command exposed from the document more-options sheet.
enum DocumentMoreOptionId {
  rename,
  findReplace,
  aiAssistant,
  insertTools,
  outline,
  pageNavigator,
  duplicate,
  pageSettings,
  theme,
  collaboration,
  statistics,
  spellCheck,
  footnotes,
  insertImage,
  exportAll,
  moveToFolder,
  tags,
  versionHistory,
  print,
  documentInfo,
  keyboardShortcuts,
}

/// Describes one command in the document more-options sheet.
class DocumentMoreOption {
  final DocumentMoreOptionId id;
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? shortcutLabel;
  final List<String> keywords;
  final bool highlighted;
  final bool enabled;
  final String? disabledReason;

  const DocumentMoreOption({
    required this.id,
    required this.icon,
    required this.title,
    this.subtitle,
    this.shortcutLabel,
    this.keywords = const [],
    this.highlighted = false,
    this.enabled = true,
    this.disabledReason,
  });
}

/// Groups related document commands for a scannable options surface.
class DocumentMoreOptionGroup {
  final String title;
  final IconData icon;
  final List<DocumentMoreOption> options;

  const DocumentMoreOptionGroup({
    required this.title,
    required this.icon,
    required this.options,
  });
}
