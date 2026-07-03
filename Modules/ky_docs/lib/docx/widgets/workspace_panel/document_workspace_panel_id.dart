import 'package:flutter/material.dart';

/// Identifies utility panels that can be docked beside the document canvas.
enum DocumentWorkspacePanelId {
  statistics,
  findReplace,
  aiAssistant,
  insert;

  String get label {
    return switch (this) {
      DocumentWorkspacePanelId.statistics => 'Writing statistics',
      DocumentWorkspacePanelId.findReplace => 'Find and replace',
      DocumentWorkspacePanelId.aiAssistant => 'AI assistant',
      DocumentWorkspacePanelId.insert => 'Insert tools',
    };
  }

  IconData get icon {
    return switch (this) {
      DocumentWorkspacePanelId.statistics => Icons.analytics_outlined,
      DocumentWorkspacePanelId.findReplace => Icons.find_replace_outlined,
      DocumentWorkspacePanelId.aiAssistant => Icons.psychology_outlined,
      DocumentWorkspacePanelId.insert => Icons.add_box_outlined,
    };
  }
}
