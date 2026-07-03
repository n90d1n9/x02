import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/document_editor_action_policy.dart';
import '../../models/document_editing_mode.dart';
import '../../models/page_layout.dart';
import '../review_hub/document_side_panel.dart';

/// Groups secondary editor actions for compact document app-bar layouts.
class DocumentEditorOverflowMenu extends StatelessWidget {
  final bool showStatistics;
  final bool showFindReplace;
  final bool showAIAssistant;
  final bool showInsertMenu;
  final bool showOutline;
  final bool showPageNavigator;
  final DocumentSidePanel? activeSidePanel;
  final DocumentEditingMode editingMode;
  final DocumentEditorActionPolicy actionPolicy;
  final bool spellCheckEnabled;
  final bool canSave;
  final PageLayout currentLayout;
  final VoidCallback onToggleStatistics;
  final VoidCallback onToggleFindReplace;
  final VoidCallback onToggleAIAssistant;
  final VoidCallback onToggleInsertMenu;
  final VoidCallback onToggleOutline;
  final VoidCallback onTogglePageNavigator;
  final ValueChanged<DocumentSidePanel> onToggleSidePanel;
  final ValueChanged<DocumentEditingMode> onEditingModeChanged;
  final VoidCallback onToggleSpellCheck;
  final Future<void> Function() onSave;
  final ValueChanged<String> onImport;
  final ValueChanged<String> onExport;
  final ValueChanged<PageLayout> onSetPageLayout;
  final VoidCallback onMoreOptions;

  const DocumentEditorOverflowMenu({
    super.key,
    required this.showStatistics,
    required this.showFindReplace,
    required this.showAIAssistant,
    required this.showInsertMenu,
    required this.showOutline,
    required this.showPageNavigator,
    required this.activeSidePanel,
    required this.editingMode,
    required this.actionPolicy,
    required this.spellCheckEnabled,
    required this.canSave,
    required this.currentLayout,
    required this.onToggleStatistics,
    required this.onToggleFindReplace,
    required this.onToggleAIAssistant,
    required this.onToggleInsertMenu,
    required this.onToggleOutline,
    required this.onTogglePageNavigator,
    required this.onToggleSidePanel,
    required this.onEditingModeChanged,
    required this.onToggleSpellCheck,
    required this.onSave,
    required this.onImport,
    required this.onExport,
    required this.onSetPageLayout,
    required this.onMoreOptions,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_OverflowAction>(
      icon: const Icon(Icons.more_horiz),
      tooltip: 'Document actions',
      onSelected: _handleAction,
      itemBuilder: (context) => [
        _toggleItem(
          action: _OverflowAction.statistics,
          icon: Icons.analytics_outlined,
          label: 'Statistics',
          selected: showStatistics,
        ),
        _toggleItem(
          action: _OverflowAction.reviewHub,
          icon: Icons.rate_review_outlined,
          label: 'Review Hub',
          selected: activeSidePanel != null,
        ),
        const PopupMenuDivider(),
        for (final mode in DocumentEditingMode.values)
          _modeItem(mode: mode, selected: editingMode == mode),
        const PopupMenuDivider(),
        _toggleItem(
          action: _OverflowAction.findReplace,
          icon: Icons.find_replace,
          label: 'Find & Replace',
          selected: showFindReplace,
        ),
        _toggleItem(
          action: _OverflowAction.aiAssistant,
          icon: Icons.psychology_outlined,
          label: 'AI Assistant',
          selected: showAIAssistant,
          enabled: actionPolicy.canUseAIAssistant,
        ),
        _toggleItem(
          action: _OverflowAction.insert,
          icon: Icons.add_box_outlined,
          label: 'Insert',
          selected: showInsertMenu,
          enabled: actionPolicy.canInsertContent,
        ),
        _toggleItem(
          action: _OverflowAction.spellCheck,
          icon: Icons.spellcheck,
          label: 'Spell Check',
          selected: spellCheckEnabled,
        ),
        const PopupMenuDivider(),
        _actionItem(
          action: _OverflowAction.save,
          icon: Icons.save_outlined,
          label: 'Save',
          enabled: canSave,
        ),
        _actionItem(
          action: _OverflowAction.importDocx,
          icon: Icons.file_upload_outlined,
          label: 'Import DOCX',
          enabled: actionPolicy.canImportContent,
        ),
        _actionItem(
          action: _OverflowAction.importPdf,
          icon: Icons.picture_as_pdf_outlined,
          label: 'Import PDF',
          enabled: actionPolicy.canImportContent,
        ),
        _actionItem(
          action: _OverflowAction.exportDocx,
          icon: Icons.description_outlined,
          label: 'Export to DOCX',
        ),
        _actionItem(
          action: _OverflowAction.exportPdf,
          icon: Icons.picture_as_pdf,
          label: 'Export to PDF',
        ),
        _actionItem(
          action: _OverflowAction.exportPdfAdvanced,
          icon: Icons.tune,
          label: 'Export PDF (Advanced)',
        ),
        const PopupMenuDivider(),
        _layoutItem(
          action: _OverflowAction.layoutPrint,
          icon: Icons.description_outlined,
          label: 'Print Layout',
          selected: currentLayout == PageLayout.print,
        ),
        _layoutItem(
          action: _OverflowAction.layoutWeb,
          icon: Icons.web_asset_outlined,
          label: 'Web Layout',
          selected: currentLayout == PageLayout.web,
        ),
        _layoutItem(
          action: _OverflowAction.pageNavigator,
          icon: Icons.view_agenda_outlined,
          label: 'Page Navigator',
          selected: showPageNavigator,
        ),
        _layoutItem(
          action: _OverflowAction.outline,
          icon: Icons.account_tree_outlined,
          label: 'Outline',
          selected: showOutline,
        ),
        const PopupMenuDivider(),
        _actionItem(
          action: _OverflowAction.moreOptions,
          icon: Icons.more_vert,
          label: 'More options',
        ),
      ],
    );
  }

  PopupMenuItem<_OverflowAction> _toggleItem({
    required _OverflowAction action,
    required IconData icon,
    required String label,
    required bool selected,
    bool enabled = true,
  }) {
    return PopupMenuItem(
      value: action,
      enabled: enabled,
      child: _OverflowItemContent(
        icon: selected ? Icons.check_circle : icon,
        label: label,
        selected: selected,
        enabled: enabled,
      ),
    );
  }

  PopupMenuItem<_OverflowAction> _layoutItem({
    required _OverflowAction action,
    required IconData icon,
    required String label,
    required bool selected,
  }) {
    return PopupMenuItem(
      value: action,
      child: _OverflowItemContent(
        icon: selected ? Icons.check_circle : icon,
        label: label,
        selected: selected,
      ),
    );
  }

  PopupMenuItem<_OverflowAction> _actionItem({
    required _OverflowAction action,
    required IconData icon,
    required String label,
    bool enabled = true,
  }) {
    return PopupMenuItem(
      value: action,
      enabled: enabled,
      child: _OverflowItemContent(icon: icon, label: label, enabled: enabled),
    );
  }

  void _handleAction(_OverflowAction action) {
    switch (action) {
      case _OverflowAction.statistics:
        onToggleStatistics();
      case _OverflowAction.reviewHub:
        onToggleSidePanel(activeSidePanel ?? DocumentSidePanel.review);
      case _OverflowAction.modeEditing:
        onEditingModeChanged(DocumentEditingMode.editing);
      case _OverflowAction.modeSuggesting:
        onEditingModeChanged(DocumentEditingMode.suggesting);
      case _OverflowAction.modeViewing:
        onEditingModeChanged(DocumentEditingMode.viewing);
      case _OverflowAction.findReplace:
        onToggleFindReplace();
      case _OverflowAction.aiAssistant:
        if (!actionPolicy.canUseAIAssistant) return;
        onToggleAIAssistant();
      case _OverflowAction.insert:
        if (!actionPolicy.canInsertContent) return;
        onToggleInsertMenu();
      case _OverflowAction.spellCheck:
        onToggleSpellCheck();
      case _OverflowAction.save:
        unawaited(onSave());
      case _OverflowAction.importDocx:
        if (!actionPolicy.canImportContent) return;
        onImport('docx');
      case _OverflowAction.importPdf:
        if (!actionPolicy.canImportContent) return;
        onImport('pdf');
      case _OverflowAction.exportDocx:
        onExport('docx');
      case _OverflowAction.exportPdf:
        onExport('pdf');
      case _OverflowAction.exportPdfAdvanced:
        onExport('pdf_advanced');
      case _OverflowAction.layoutPrint:
        onSetPageLayout(PageLayout.print);
      case _OverflowAction.layoutWeb:
        onSetPageLayout(PageLayout.web);
      case _OverflowAction.pageNavigator:
        onTogglePageNavigator();
      case _OverflowAction.outline:
        onToggleOutline();
      case _OverflowAction.moreOptions:
        onMoreOptions();
    }
  }

  PopupMenuItem<_OverflowAction> _modeItem({
    required DocumentEditingMode mode,
    required bool selected,
  }) {
    return PopupMenuItem(
      value: _actionForMode(mode),
      child: _OverflowItemContent(
        icon: selected ? Icons.check_circle : mode.icon,
        label: '${mode.label} mode',
        selected: selected,
      ),
    );
  }

  _OverflowAction _actionForMode(DocumentEditingMode mode) {
    return switch (mode) {
      DocumentEditingMode.editing => _OverflowAction.modeEditing,
      DocumentEditingMode.suggesting => _OverflowAction.modeSuggesting,
      DocumentEditingMode.viewing => _OverflowAction.modeViewing,
    };
  }
}

class _OverflowItemContent extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool enabled;

  const _OverflowItemContent({
    required this.icon,
    required this.label,
    this.selected = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = !enabled
        ? colorScheme.onSurface.withValues(alpha: 0.38)
        : selected
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;

    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

enum _OverflowAction {
  statistics,
  reviewHub,
  modeEditing,
  modeSuggesting,
  modeViewing,
  findReplace,
  aiAssistant,
  insert,
  spellCheck,
  save,
  importDocx,
  importPdf,
  exportDocx,
  exportPdf,
  exportPdfAdvanced,
  layoutPrint,
  layoutWeb,
  pageNavigator,
  outline,
  moreOptions,
}
