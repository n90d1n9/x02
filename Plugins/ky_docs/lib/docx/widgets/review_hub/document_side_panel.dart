import 'package:flutter/material.dart';

/// Identifies the active document review side-panel tab.
enum DocumentSidePanel {
  review,
  comments,
  trackChanges;

  String get label {
    return switch (this) {
      DocumentSidePanel.review => 'Review',
      DocumentSidePanel.comments => 'Comments',
      DocumentSidePanel.trackChanges => 'Changes',
    };
  }

  IconData get icon {
    return switch (this) {
      DocumentSidePanel.review => Icons.rate_review_outlined,
      DocumentSidePanel.comments => Icons.mode_comment_outlined,
      DocumentSidePanel.trackChanges => Icons.rule_folder_outlined,
    };
  }

  String get tooltip {
    return switch (this) {
      DocumentSidePanel.review => 'Show writing review insights',
      DocumentSidePanel.comments => 'Show open and resolved comments',
      DocumentSidePanel.trackChanges => 'Show tracked document changes',
    };
  }
}
