import 'package:flutter/material.dart';

import '../models/document_editor_action_policy.dart';
import '../models/document_editing_mode.dart';
import '../models/document_state.dart';
import '../models/page_layout.dart';
import 'editor_app_bar/command_palette_button.dart';
import 'editor_app_bar/collaborators_menu.dart';
import 'editor_app_bar/document_action_cluster.dart';
import 'editor_app_bar/document_title.dart';
import 'editor_app_bar/import_export_menus.dart';
import 'editor_app_bar/overflow_menu.dart';
import 'editor_app_bar/share_button.dart';
import 'editor_app_bar/sync_indicator.dart';
import 'editor_app_bar/toolbar_toggle_button.dart';
import 'editor_app_bar/view_menu.dart';
import 'review_mode/document_editing_mode_switcher.dart';
import 'review_hub/document_side_panel.dart';

/// Provides the top editor app bar and primary document action chrome.
class DocumentEditorAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final DocumentState documentState;
  final bool showStatistics;
  final bool showFindReplace;
  final bool showAIAssistant;
  final bool showInsertMenu;
  final bool showOutline;
  final bool showPageNavigator;
  final DocumentSidePanel? activeSidePanel;
  final DocumentEditingMode editingMode;
  final VoidCallback onEditTitle;
  final VoidCallback onToggleFavorite;
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
  final VoidCallback onOpenCommandPalette;
  final VoidCallback onOpenCollaboration;
  final VoidCallback onMoreOptions;

  const DocumentEditorAppBar({
    super.key,
    required this.documentState,
    required this.showStatistics,
    required this.showFindReplace,
    required this.showAIAssistant,
    required this.showInsertMenu,
    required this.showOutline,
    required this.showPageNavigator,
    required this.activeSidePanel,
    required this.editingMode,
    required this.onEditTitle,
    required this.onToggleFavorite,
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
    required this.onOpenCommandPalette,
    required this.onOpenCollaboration,
    required this.onMoreOptions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final useCompactActions = width < 1180;
    final showShareLabel = width >= 1320;
    final showModeSwitcher = width >= 1340;
    final actionPolicy = DocumentEditorActionPolicy(editingMode: editingMode);

    return AppBar(
      title: DocumentEditorTitle(
        title: documentState.metadata.title,
        onTap: actionPolicy.canEditMetadata ? onEditTitle : null,
        tooltip: actionPolicy.canEditMetadata
            ? 'Rename document'
            : actionPolicy.lockedMutationReason,
      ),
      actions: useCompactActions
          ? _compactActions(actionPolicy: actionPolicy)
          : _expandedActions(
              actionPolicy: actionPolicy,
              showShareLabel: showShareLabel,
              showModeSwitcher: showModeSwitcher,
            ),
    );
  }

  List<Widget> _expandedActions({
    required DocumentEditorActionPolicy actionPolicy,
    required bool showShareLabel,
    required bool showModeSwitcher,
  }) {
    return [
      if (documentState.hasUnsavedChanges) const DocumentUnsavedBadge(),
      IconButton(
        icon: Icon(
          documentState.metadata.isFavorite ? Icons.star : Icons.star_outline,
        ),
        tooltip: actionPolicy.canEditMetadata
            ? 'Toggle Favorite'
            : actionPolicy.lockedMutationReason,
        color: documentState.metadata.isFavorite ? Colors.amber : null,
        onPressed: actionPolicy.canEditMetadata ? onToggleFavorite : null,
      ),
      if (showModeSwitcher)
        DocumentActionCluster(
          groupId: 'mode',
          semanticLabel: 'Editing mode',
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: DocumentEditingModeSwitcher(
                currentMode: editingMode,
                onModeChanged: onEditingModeChanged,
              ),
            ),
          ],
        ),
      DocumentActionCluster(
        groupId: 'review',
        semanticLabel: 'Review and search actions',
        children: [
          DocumentToolbarToggleButton(
            active: showStatistics,
            activeIcon: Icons.analytics,
            inactiveIcon: Icons.analytics_outlined,
            tooltip: 'Statistics',
            onPressed: onToggleStatistics,
          ),
          DocumentToolbarToggleButton(
            active: activeSidePanel != null,
            activeIcon: Icons.rate_review,
            inactiveIcon: Icons.rate_review_outlined,
            tooltip: 'Review Hub',
            onPressed: () =>
                onToggleSidePanel(activeSidePanel ?? DocumentSidePanel.review),
          ),
          DocumentToolbarToggleButton(
            active: showFindReplace,
            activeIcon: Icons.search_off,
            inactiveIcon: Icons.search,
            tooltip: 'Find & Replace',
            onPressed: onToggleFindReplace,
          ),
          DocumentCommandPaletteButton(onPressed: onOpenCommandPalette),
        ],
      ),
      DocumentActionCluster(
        groupId: 'create',
        semanticLabel: 'Creation and assistive actions',
        children: [
          DocumentToolbarToggleButton(
            active: showAIAssistant,
            activeIcon: Icons.psychology,
            inactiveIcon: Icons.psychology_outlined,
            tooltip: actionPolicy.canUseAIAssistant
                ? 'AI Assistant'
                : actionPolicy.lockedMutationReason,
            onPressed: actionPolicy.canUseAIAssistant
                ? onToggleAIAssistant
                : null,
          ),
          DocumentToolbarToggleButton(
            active: showInsertMenu,
            activeIcon: Icons.add_box,
            inactiveIcon: Icons.add_box_outlined,
            tooltip: actionPolicy.canInsertContent
                ? 'Insert'
                : actionPolicy.lockedMutationReason,
            onPressed: actionPolicy.canInsertContent
                ? onToggleInsertMenu
                : null,
          ),
        ],
      ),
      DocumentActionCluster(
        groupId: 'collaboration',
        semanticLabel: 'Collaboration actions',
        children: [
          DocumentCollaboratorsMenu(documentState: documentState),
          DocumentShareButton(
            collaborationEnabled: documentState.isCollaborationEnabled,
            collaboratorCount: documentState.collaborators.length,
            showLabel: showShareLabel,
            onPressed: onOpenCollaboration,
          ),
        ],
      ),
      DocumentActionCluster(
        groupId: 'proofing',
        semanticLabel: 'Proofing and sync actions',
        children: [
          IconButton(
            icon: Icon(
              documentState.spellCheckEnabled
                  ? Icons.spellcheck
                  : Icons.spellcheck_outlined,
              color: documentState.spellCheckEnabled ? Colors.green : null,
            ),
            tooltip: 'Spell Check',
            onPressed: onToggleSpellCheck,
          ),
          DocumentSyncIndicator(documentState: documentState),
        ],
      ),
      DocumentActionCluster(
        groupId: 'file',
        semanticLabel: 'File and view actions',
        children: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save',
            onPressed: documentState.hasUnsavedChanges ? () => onSave() : null,
          ),
          DocumentImportMenu(
            enabled: actionPolicy.canImportContent,
            tooltip: actionPolicy.canImportContent
                ? 'Import'
                : actionPolicy.lockedMutationReason,
            onSelected: onImport,
          ),
          DocumentExportMenu(onSelected: onExport),
          DocumentViewMenu(
            currentLayout: documentState.currentLayout,
            showOutline: showOutline,
            showPageNavigator: showPageNavigator,
            onSetPageLayout: onSetPageLayout,
            onToggleOutline: onToggleOutline,
            onTogglePageNavigator: onTogglePageNavigator,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            tooltip: 'More options',
            onPressed: onMoreOptions,
          ),
        ],
      ),
    ];
  }

  List<Widget> _compactActions({
    required DocumentEditorActionPolicy actionPolicy,
  }) {
    return [
      if (documentState.hasUnsavedChanges) const DocumentUnsavedBadge(),
      IconButton(
        icon: Icon(
          documentState.metadata.isFavorite ? Icons.star : Icons.star_outline,
        ),
        tooltip: actionPolicy.canEditMetadata
            ? 'Toggle Favorite'
            : actionPolicy.lockedMutationReason,
        color: documentState.metadata.isFavorite ? Colors.amber : null,
        onPressed: actionPolicy.canEditMetadata ? onToggleFavorite : null,
      ),
      DocumentCommandPaletteButton(onPressed: onOpenCommandPalette),
      DocumentShareButton(
        collaborationEnabled: documentState.isCollaborationEnabled,
        collaboratorCount: documentState.collaborators.length,
        showLabel: false,
        onPressed: onOpenCollaboration,
      ),
      DocumentSyncIndicator(documentState: documentState),
      DocumentEditorOverflowMenu(
        showStatistics: showStatistics,
        showFindReplace: showFindReplace,
        showAIAssistant: showAIAssistant,
        showInsertMenu: showInsertMenu,
        showOutline: showOutline,
        showPageNavigator: showPageNavigator,
        activeSidePanel: activeSidePanel,
        editingMode: editingMode,
        actionPolicy: actionPolicy,
        spellCheckEnabled: documentState.spellCheckEnabled,
        canSave: documentState.hasUnsavedChanges,
        currentLayout: documentState.currentLayout,
        onToggleStatistics: onToggleStatistics,
        onToggleFindReplace: onToggleFindReplace,
        onToggleAIAssistant: onToggleAIAssistant,
        onToggleInsertMenu: onToggleInsertMenu,
        onToggleOutline: onToggleOutline,
        onTogglePageNavigator: onTogglePageNavigator,
        onToggleSidePanel: onToggleSidePanel,
        onEditingModeChanged: onEditingModeChanged,
        onToggleSpellCheck: onToggleSpellCheck,
        onSave: onSave,
        onImport: onImport,
        onExport: onExport,
        onSetPageLayout: onSetPageLayout,
        onMoreOptions: onMoreOptions,
      ),
    ];
  }
}
