import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/document_editor_action_policy.dart';
import '../../models/document_editing_mode.dart';
import '../../models/document_state.dart';
import '../../models/page_layout.dart';
import '../find_replace/find_replace_mode_policy.dart';
import '../review_hub/document_side_panel.dart';
import 'document_command.dart';

/// Builds the editor command palette actions from the current document state.
class DocumentEditorCommandCatalog {
  final DocumentState documentState;
  final DocumentEditingMode editingMode;
  final FutureOr<void> Function() onSave;
  final FutureOr<void> Function() onShowFindReplace;
  final ValueChanged<DocumentSidePanel> onOpenSidePanel;
  final ValueChanged<DocumentEditingMode> onSetEditingMode;
  final FutureOr<void> Function() onShowStatistics;
  final FutureOr<void> Function() onShowAIAssistant;
  final FutureOr<void> Function() onShowInsertPanel;
  final FutureOr<void> Function() onShowPageNavigator;
  final FutureOr<void> Function() onOpenCollaboration;
  final FutureOr<void> Function() onPrint;
  final FutureOr<void> Function() onCreateNewDocument;
  final ValueChanged<PageLayout> onSetPageLayout;

  const DocumentEditorCommandCatalog({
    required this.documentState,
    required this.editingMode,
    required this.onSave,
    required this.onShowFindReplace,
    required this.onOpenSidePanel,
    required this.onSetEditingMode,
    required this.onShowStatistics,
    required this.onShowAIAssistant,
    required this.onShowInsertPanel,
    required this.onShowPageNavigator,
    required this.onOpenCollaboration,
    required this.onPrint,
    required this.onCreateNewDocument,
    required this.onSetPageLayout,
  });

  List<DocumentCommand> build() {
    final actionPolicy = DocumentEditorActionPolicy(editingMode: editingMode);
    final findReplacePolicy = DocxFindReplaceModePolicy(
      editingMode: editingMode,
    );

    return [
      DocumentCommand(
        id: 'save',
        title: 'Save document',
        subtitle: documentState.hasUnsavedChanges
            ? 'Save the latest document changes'
            : 'No unsaved changes right now',
        icon: Icons.save_outlined,
        category: 'File',
        shortcut: 'Ctrl S',
        enabled: documentState.hasUnsavedChanges,
        disabledLabel: 'Saved',
        disabledReason: 'No unsaved changes right now',
        disabledIcon: Icons.task_alt,
        keywords: const ['sync', 'persist'],
        onSelected: onSave,
      ),
      DocumentCommand(
        id: 'find',
        title: findReplacePolicy.commandTitle,
        subtitle: findReplacePolicy.modeDescription,
        icon: Icons.find_replace,
        category: 'Edit',
        shortcut: 'Ctrl H',
        keywords: [
          'search',
          if (findReplacePolicy.canReplace) 'replace' else 'find only',
          if (!findReplacePolicy.canReplace) 'read only',
        ],
        suggested: true,
        suggestionPriority: 90,
        onSelected: onShowFindReplace,
      ),
      DocumentCommand(
        id: 'review',
        title: 'Open review panel',
        subtitle: 'Show quality, suggestions, and focus areas',
        icon: Icons.rate_review_outlined,
        category: 'Review',
        keywords: const ['writing', 'quality', 'suggestions'],
        suggested: true,
        suggestionPriority: 80,
        onSelected: () => onOpenSidePanel(DocumentSidePanel.review),
      ),
      DocumentCommand(
        id: 'comments',
        title: 'Open comments panel',
        subtitle: 'Add and resolve anchored document discussions',
        icon: Icons.mode_comment_outlined,
        category: 'Review',
        keywords: const ['discussion', 'annotation', 'feedback'],
        suggested: true,
        suggestionPriority: 76,
        onSelected: () => onOpenSidePanel(DocumentSidePanel.comments),
      ),
      DocumentCommand(
        id: 'track-changes',
        title: 'Open track changes',
        subtitle: 'Suggest, accept, and reject document edits',
        icon: Icons.rule_folder_outlined,
        category: 'Review',
        keywords: const ['suggesting', 'edits', 'redline'],
        onSelected: () => onOpenSidePanel(DocumentSidePanel.trackChanges),
      ),
      DocumentCommand(
        id: 'mode-editing',
        title: 'Switch to editing mode',
        subtitle: DocumentEditingMode.editing.description,
        icon: DocumentEditingMode.editing.icon,
        category: 'Review',
        keywords: const ['mode', 'direct edits'],
        enabled: editingMode != DocumentEditingMode.editing,
        disabledLabel: 'Current',
        disabledReason: 'Editing mode is already active',
        disabledIcon: Icons.check_circle_outline,
        onSelected: () => onSetEditingMode(DocumentEditingMode.editing),
      ),
      DocumentCommand(
        id: 'mode-suggesting',
        title: 'Switch to suggesting mode',
        subtitle: DocumentEditingMode.suggesting.description,
        icon: DocumentEditingMode.suggesting.icon,
        category: 'Review',
        keywords: const ['mode', 'suggestions', 'track changes'],
        enabled: editingMode != DocumentEditingMode.suggesting,
        disabledLabel: 'Current',
        disabledReason: 'Suggesting mode is already active',
        disabledIcon: Icons.check_circle_outline,
        onSelected: () => onSetEditingMode(DocumentEditingMode.suggesting),
      ),
      DocumentCommand(
        id: 'mode-viewing',
        title: 'Switch to viewing mode',
        subtitle: DocumentEditingMode.viewing.description,
        icon: DocumentEditingMode.viewing.icon,
        category: 'Review',
        keywords: const ['mode', 'read only'],
        enabled: editingMode != DocumentEditingMode.viewing,
        disabledLabel: 'Current',
        disabledReason: 'Viewing mode is already active',
        disabledIcon: Icons.check_circle_outline,
        onSelected: () => onSetEditingMode(DocumentEditingMode.viewing),
      ),
      DocumentCommand(
        id: 'statistics',
        title: 'Show writing statistics',
        subtitle: 'Open word count, readability, and writing metrics',
        icon: Icons.analytics_outlined,
        category: 'Review',
        keywords: const ['word count', 'metrics'],
        onSelected: onShowStatistics,
      ),
      DocumentCommand(
        id: 'ai',
        title: 'Open AI assistant',
        subtitle: actionPolicy.canUseAIAssistant
            ? 'Draft, rewrite, summarize, or improve selected text'
            : actionPolicy.lockedMutationReason,
        icon: Icons.psychology_outlined,
        category: 'Assist',
        enabled: actionPolicy.canUseAIAssistant,
        disabledLabel: 'Locked',
        disabledReason: actionPolicy.lockedMutationReason,
        disabledIcon: Icons.lock_outline,
        keywords: const ['rewrite', 'summarize', 'assistant'],
        suggested: true,
        suggestionPriority: 70,
        onSelected: onShowAIAssistant,
      ),
      DocumentCommand(
        id: 'insert',
        title: 'Open insert tools',
        subtitle: actionPolicy.canInsertContent
            ? 'Insert tables, charts, shapes, references, and media'
            : actionPolicy.lockedMutationReason,
        icon: Icons.add_box_outlined,
        category: 'Insert',
        enabled: actionPolicy.canInsertContent,
        disabledLabel: 'Locked',
        disabledReason: actionPolicy.lockedMutationReason,
        disabledIcon: Icons.lock_outline,
        keywords: const ['table', 'chart', 'image', 'footnote'],
        suggested: true,
        suggestionPriority: 68,
        onSelected: onShowInsertPanel,
      ),
      DocumentCommand(
        id: 'share',
        title: 'Share document',
        subtitle: 'Open collaboration and sharing controls',
        icon: Icons.lock_open_outlined,
        category: 'Collaborate',
        keywords: const ['collaboration', 'people'],
        onSelected: onOpenCollaboration,
      ),
      DocumentCommand(
        id: 'print',
        title: 'Print document',
        subtitle: 'Send the current document to print',
        icon: Icons.print_outlined,
        category: 'File',
        shortcut: 'Ctrl P',
        keywords: const ['pdf'],
        onSelected: onPrint,
      ),
      DocumentCommand(
        id: 'new-document',
        title: 'New document',
        subtitle: 'Start a fresh blank document',
        icon: Icons.note_add_outlined,
        category: 'File',
        shortcut: 'Ctrl N',
        keywords: const ['create'],
        onSelected: onCreateNewDocument,
      ),
      DocumentCommand(
        id: 'page-navigator',
        title: 'Open page navigator',
        subtitle: 'Show page thumbnails and jump between document pages',
        icon: Icons.view_agenda_outlined,
        category: 'View',
        keywords: const ['pages', 'thumbnail', 'navigation'],
        suggested: true,
        suggestionPriority: 66,
        onSelected: onShowPageNavigator,
      ),
      DocumentCommand(
        id: 'layout-print',
        title: 'Switch to print layout',
        subtitle: 'Use a page-based editing canvas',
        icon: Icons.description_outlined,
        category: 'View',
        keywords: const ['page', 'view'],
        onSelected: () => onSetPageLayout(PageLayout.print),
      ),
      DocumentCommand(
        id: 'layout-web',
        title: 'Switch to web layout',
        subtitle: 'Use a wider continuous writing canvas',
        icon: Icons.web_asset_outlined,
        category: 'View',
        keywords: const ['view'],
        onSelected: () => onSetPageLayout(PageLayout.web),
      ),
      DocumentCommand(
        id: 'layout-outline',
        title: 'Switch to outline layout',
        subtitle: 'Use a structure-focused editing canvas',
        icon: Icons.account_tree_outlined,
        category: 'View',
        keywords: const ['view', 'structure'],
        onSelected: () => onSetPageLayout(PageLayout.outline),
      ),
    ];
  }
}
