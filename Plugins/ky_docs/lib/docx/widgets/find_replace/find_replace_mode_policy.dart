import '../../models/document_editing_mode.dart';

/// Defines find-and-replace capabilities for the active document editing mode.
class DocxFindReplaceModePolicy {
  final DocumentEditingMode editingMode;

  const DocxFindReplaceModePolicy({required this.editingMode});

  bool get canReplace {
    return editingMode != DocumentEditingMode.viewing;
  }

  bool get showsModeBadge {
    return editingMode != DocumentEditingMode.editing;
  }

  String get title {
    return canReplace ? 'Find & Replace' : 'Find';
  }

  String get commandTitle {
    return canReplace ? 'Find and replace' : 'Find';
  }

  String get modeLabel {
    return switch (editingMode) {
      DocumentEditingMode.editing => 'Editing',
      DocumentEditingMode.suggesting => 'Suggesting',
      DocumentEditingMode.viewing => 'Find only',
    };
  }

  String get modeDescription {
    return switch (editingMode) {
      DocumentEditingMode.editing => 'Find and replace document text',
      DocumentEditingMode.suggesting => 'Replacements are made in review mode',
      DocumentEditingMode.viewing => 'Viewing mode locks replacement actions',
    };
  }
}
