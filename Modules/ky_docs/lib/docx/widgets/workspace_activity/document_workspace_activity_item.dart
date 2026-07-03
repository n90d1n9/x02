import 'package:flutter/material.dart';

/// Identifies a shortcut rendered in the document workspace activity rail.
enum DocumentWorkspaceActivityId {
  outline,
  pages,
  review,
  statistics,
  findReplace,
  aiAssistant,
  insert,
}

/// Describes one workspace-level action surfaced beside the document canvas.
class DocumentWorkspaceActivityItem {
  final DocumentWorkspaceActivityId id;
  final IconData icon;
  final IconData selectedIcon;
  final String tooltip;
  final String? disabledTooltip;
  final bool active;
  final bool enabled;
  final VoidCallback? onPressed;

  const DocumentWorkspaceActivityItem({
    required this.id,
    required this.icon,
    required this.selectedIcon,
    required this.tooltip,
    this.disabledTooltip,
    this.active = false,
    this.enabled = true,
    this.onPressed,
  });
}

/// Groups related activity rail shortcuts with a shared semantic label.
class DocumentWorkspaceActivityGroup {
  final String semanticLabel;
  final List<DocumentWorkspaceActivityItem> items;

  const DocumentWorkspaceActivityGroup({
    required this.semanticLabel,
    required this.items,
  });
}
