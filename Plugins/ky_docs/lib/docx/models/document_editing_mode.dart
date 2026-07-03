import 'package:flutter/material.dart';

/// Describes how the editor should treat document changes in review workflows.
enum DocumentEditingMode {
  editing,
  suggesting,
  viewing;

  String get label {
    return switch (this) {
      DocumentEditingMode.editing => 'Editing',
      DocumentEditingMode.suggesting => 'Suggesting',
      DocumentEditingMode.viewing => 'Viewing',
    };
  }

  String get description {
    return switch (this) {
      DocumentEditingMode.editing => 'Direct edits update the document',
      DocumentEditingMode.suggesting => 'Changes are prepared for review',
      DocumentEditingMode.viewing => 'Read without changing the document',
    };
  }

  IconData get icon {
    return switch (this) {
      DocumentEditingMode.editing => Icons.edit_outlined,
      DocumentEditingMode.suggesting => Icons.rate_review_outlined,
      DocumentEditingMode.viewing => Icons.visibility_outlined,
    };
  }

  bool get isReadOnly {
    return this == DocumentEditingMode.viewing;
  }

  bool get showsFormattingToolbar {
    return this != DocumentEditingMode.viewing;
  }

  bool get showsWorkspaceBanner {
    return this != DocumentEditingMode.editing;
  }
}
