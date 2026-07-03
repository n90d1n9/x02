import 'package:flutter/material.dart';

import '../../models/document_editing_mode.dart';
import '../status_bar/document_status_chip.dart';
import '../status_bar/document_status_popover.dart';
import 'document_editing_mode_status_details.dart';

/// Shows the active document editing mode in the editor status bar.
class DocumentEditingModeStatusChip extends StatelessWidget {
  static const chipKey = ValueKey('document-editing-mode-status-chip');
  static const menuKey = ValueKey('document-editing-mode-status-menu');
  static const actionKey = ValueKey('document-editing-mode-status-action');

  final DocumentEditingMode mode;
  final VoidCallback? onPressed;

  const DocumentEditingModeStatusChip({
    super.key,
    required this.mode,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final details = DocumentEditingModeStatusDetails(mode);

    return PopupMenuButton<void>(
      tooltip: 'Show editing mode details',
      itemBuilder: (context) => [
        PopupMenuItem<void>(
          enabled: false,
          padding: EdgeInsets.zero,
          child: _DocumentEditingModeStatusMenu(
            details: details,
            onPressed: onPressed,
          ),
        ),
      ],
      child: DocumentStatusChip(
        key: chipKey,
        icon: mode.icon,
        label: mode.label,
        tooltip: mode.description,
        color: _modeColor(colorScheme),
      ),
    );
  }

  Color _modeColor(ColorScheme colorScheme) {
    return switch (mode) {
      DocumentEditingMode.editing => colorScheme.onSurfaceVariant,
      DocumentEditingMode.suggesting => colorScheme.primary,
      DocumentEditingMode.viewing => colorScheme.secondary,
    };
  }
}

/// Renders the active editing-mode rules in a compact status popover.
class _DocumentEditingModeStatusMenu extends StatelessWidget {
  final DocumentEditingModeStatusDetails details;
  final VoidCallback? onPressed;

  const _DocumentEditingModeStatusMenu({
    required this.details,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return DocumentStatusPopover(
      contentKey: DocumentEditingModeStatusChip.menuKey,
      icon: details.mode.icon,
      title: 'Editing mode',
      subtitle: details.description,
      width: 292,
      children: [
        DocumentStatusPopoverMetricLine(
          icon: details.mode.icon,
          label: 'Mode',
          value: details.modeLabel,
        ),
        DocumentStatusPopoverMetricLine(
          icon: Icons.edit_note_outlined,
          label: 'Document changes',
          value: details.editingAccessLabel,
        ),
        DocumentStatusPopoverMetricLine(
          icon: Icons.format_color_text_outlined,
          label: 'Formatting toolbar',
          value: details.toolbarLabel,
        ),
        DocumentStatusPopoverMetricLine(
          icon: Icons.info_outline,
          label: 'Mode banner',
          value: details.workspaceBannerLabel,
        ),
        DocumentStatusPopoverMetricLine(
          icon: Icons.lock_outline,
          label: 'Read only',
          value: details.readOnlyLabel,
        ),
        if (onPressed != null)
          DocumentStatusPopoverActionButton(
            actionKey: DocumentEditingModeStatusChip.actionKey,
            icon: Icons.tune_outlined,
            label: 'Change mode',
            onPressed: () => _runAction(context),
          ),
      ],
    );
  }

  void _runAction(BuildContext context) {
    Navigator.of(context).pop();
    onPressed?.call();
  }
}
