import 'package:flutter/material.dart';

import '../../models/document_editing_mode.dart';

/// Defines contextual selection actions for each document editing mode.
class DocumentSelectionToolbarPolicy {
  final DocumentEditingMode editingMode;

  const DocumentSelectionToolbarPolicy({required this.editingMode});

  bool get showsModeBadge {
    return editingMode != DocumentEditingMode.editing;
  }

  bool get showsFormattingActions {
    return editingMode != DocumentEditingMode.viewing;
  }

  bool get showsReviewActions {
    return editingMode != DocumentEditingMode.viewing;
  }

  String get modeLabel {
    return switch (editingMode) {
      DocumentEditingMode.editing => 'Editing',
      DocumentEditingMode.suggesting => 'Suggesting',
      DocumentEditingMode.viewing => 'Viewing',
    };
  }

  String get modeTooltip {
    return switch (editingMode) {
      DocumentEditingMode.editing => 'Direct editing active',
      DocumentEditingMode.suggesting => 'Selection edits become review work',
      DocumentEditingMode.viewing => 'Selection editing is locked',
    };
  }

  IconData get modeIcon {
    return editingMode.icon;
  }
}
