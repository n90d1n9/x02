import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/document_editor_action_policy.dart';
import '../models/document_editing_mode.dart';
import '../models/document_state.dart';
import '../services/document_statistics.dart';
import '../states/provider.dart';
import 'ai_assistant_panel.dart';
import 'collaboration_dialog.dart';
import 'document_info_dialog.dart';
import 'document_statistics_panel.dart';
import 'document_title_dialog.dart';
import 'document_writing_insights_dialog.dart';
import 'find_replace/find_replace_mode_policy.dart';
import 'find_replace/find_replace_panel.dart';
import 'footnotes_dialog.dart';
import 'keyboard_shortcut_dialog.dart';
import 'insert_elements/insert_elements_panel.dart';
import 'more_options/document_more_option.dart';
import 'more_options/document_more_options_panel.dart';
import 'more_options/document_more_options_navigation_launcher.dart';
import 'move_to_folder_dialog.dart';
import 'page_setting_dialog.dart';
import 'spell_check_dialog.dart';
import 'tags_dialog.dart';
import 'theme_dialog.dart';
import 'version_history_dialog.dart';

/// Connects document state and editor actions to the reusable more-options panel.
class MoreOptions extends ConsumerWidget {
  static const _navigationLauncher = DocumentMoreOptionsNavigationLauncher();

  final DocumentEditingMode editingMode;
  final VoidCallback? onShowStatistics;
  final VoidCallback? onShowFindReplace;
  final VoidCallback? onShowAIAssistant;
  final VoidCallback? onShowInsertPanel;
  final VoidCallback? onShowOutline;
  final VoidCallback? onShowPageNavigator;

  const MoreOptions({
    super.key,
    this.editingMode = DocumentEditingMode.editing,
    this.onShowStatistics,
    this.onShowFindReplace,
    this.onShowAIAssistant,
    this.onShowInsertPanel,
    this.onShowOutline,
    this.onShowPageNavigator,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docState = ref.watch(documentProvider);
    final statisticsSnapshot = ref.watch(statisticsProvider).snapshot;
    final outline = _navigationLauncher.generateOutline(docState);
    final actionPolicy = DocumentEditorActionPolicy(editingMode: editingMode);

    return DocumentMoreOptionsPanel(
      groups: _buildGroups(
        docState,
        editingMode,
        actionPolicy,
        statisticsSnapshot,
        outlineCount: outline.length,
      ),
      onClose: () => Navigator.pop(context),
      onOptionSelected: (option) {
        _handleOption(context, ref, option);
      },
    );
  }

  List<DocumentMoreOptionGroup> _buildGroups(
    DocumentState docState,
    DocumentEditingMode editingMode,
    DocumentEditorActionPolicy actionPolicy,
    DocumentTextStatistics statistics, {
    required int outlineCount,
  }) {
    final findReplacePolicy = DocxFindReplaceModePolicy(
      editingMode: editingMode,
    );

    return [
      DocumentMoreOptionGroup(
        title: 'Document',
        icon: Icons.description_outlined,
        options: [
          DocumentMoreOption(
            id: DocumentMoreOptionId.rename,
            icon: Icons.drive_file_rename_outline,
            title: 'Rename document',
            subtitle: docState.metadata.title,
            keywords: const ['title', 'file name'],
          ),
          const DocumentMoreOption(
            id: DocumentMoreOptionId.duplicate,
            icon: Icons.content_copy,
            title: 'Duplicate document',
            keywords: ['copy'],
          ),
          const DocumentMoreOption(
            id: DocumentMoreOptionId.documentInfo,
            icon: Icons.info_outline,
            title: 'Document info',
            keywords: ['metadata', 'properties'],
          ),
          DocumentMoreOption(
            id: DocumentMoreOptionId.versionHistory,
            icon: Icons.history,
            title: 'Version history',
            subtitle: '${docState.versions.length} versions',
            keywords: const ['restore', 'revisions'],
          ),
        ],
      ),
      DocumentMoreOptionGroup(
        title: 'Edit',
        icon: Icons.edit_note_outlined,
        options: [
          DocumentMoreOption(
            id: DocumentMoreOptionId.findReplace,
            icon: Icons.find_replace,
            title: findReplacePolicy.commandTitle,
            subtitle: findReplacePolicy.modeDescription,
            shortcutLabel: findReplacePolicy.canReplace ? 'Ctrl H' : 'Ctrl F',
            keywords: const ['search', 'replace'],
          ),
        ],
      ),
      DocumentMoreOptionGroup(
        title: 'Create',
        icon: Icons.add_box_outlined,
        options: [
          DocumentMoreOption(
            id: DocumentMoreOptionId.aiAssistant,
            icon: Icons.psychology_outlined,
            title: 'AI assistant',
            subtitle: actionPolicy.canUseAIAssistant
                ? 'Draft, rewrite, summarize, improve'
                : actionPolicy.lockedMutationReason,
            keywords: const ['ai', 'rewrite', 'summarize', 'draft'],
            enabled: actionPolicy.canUseAIAssistant,
            disabledReason: actionPolicy.lockedMutationReason,
          ),
          DocumentMoreOption(
            id: DocumentMoreOptionId.insertTools,
            icon: Icons.add_box_outlined,
            title: 'Insert tools',
            subtitle: actionPolicy.canInsertContent
                ? 'Tables, charts, shapes, footnotes'
                : actionPolicy.lockedMutationReason,
            keywords: const ['table', 'chart', 'shape', 'media'],
            enabled: actionPolicy.canInsertContent,
            disabledReason: actionPolicy.lockedMutationReason,
          ),
        ],
      ),
      DocumentMoreOptionGroup(
        title: 'Navigate',
        icon: Icons.explore_outlined,
        options: [
          DocumentMoreOption(
            id: DocumentMoreOptionId.outline,
            icon: Icons.account_tree_outlined,
            title: 'Document outline',
            subtitle: _navigationLauncher.outlineSubtitle(outlineCount),
            keywords: const ['headings', 'toc', 'table of contents'],
          ),
          DocumentMoreOption(
            id: DocumentMoreOptionId.pageNavigator,
            icon: Icons.view_agenda_outlined,
            title: 'Page navigator',
            subtitle: _navigationLauncher.pageNavigatorSubtitle(docState),
            keywords: const ['pages', 'thumbnails'],
          ),
        ],
      ),
      DocumentMoreOptionGroup(
        title: 'Layout',
        icon: Icons.view_quilt_outlined,
        options: [
          const DocumentMoreOption(
            id: DocumentMoreOptionId.pageSettings,
            icon: Icons.settings_outlined,
            title: 'Page settings',
            subtitle: 'Headers, footers, page size',
            keywords: ['margins', 'paper', 'layout'],
          ),
          DocumentMoreOption(
            id: DocumentMoreOptionId.theme,
            icon: Icons.palette_outlined,
            title: 'Document theme',
            subtitle: docState.currentTheme?.name ?? 'Default theme',
            keywords: const ['colors', 'style'],
          ),
          DocumentMoreOption(
            id: DocumentMoreOptionId.footnotes,
            icon: Icons.notes_outlined,
            title: 'Footnotes',
            subtitle: '${docState.footnotes.length} notes',
            keywords: const ['references', 'notes'],
          ),
        ],
      ),
      DocumentMoreOptionGroup(
        title: 'Review',
        icon: Icons.rate_review_outlined,
        options: [
          DocumentMoreOption(
            id: DocumentMoreOptionId.collaboration,
            icon: docState.isCollaborationEnabled
                ? Icons.people
                : Icons.people_outline,
            title: 'Collaboration',
            subtitle: docState.isCollaborationEnabled
                ? '${docState.collaborators.length} active'
                : 'Enable sharing',
            keywords: const ['share', 'people'],
            highlighted: docState.isCollaborationEnabled,
          ),
          DocumentMoreOption(
            id: DocumentMoreOptionId.statistics,
            icon: Icons.analytics_outlined,
            title: 'Writing statistics',
            subtitle:
                '${statistics.wordCount} words - ${statistics.readingTimeLabel} read',
            keywords: const ['word count', 'read time', 'metrics'],
          ),
          DocumentMoreOption(
            id: DocumentMoreOptionId.spellCheck,
            icon: Icons.spellcheck,
            title: 'Spell check',
            subtitle: '${docState.spellErrors.length} issues found',
            keywords: const ['proofing', 'grammar'],
            highlighted: docState.spellCheckEnabled,
          ),
          const DocumentMoreOption(
            id: DocumentMoreOptionId.keyboardShortcuts,
            icon: Icons.keyboard,
            title: 'Keyboard shortcuts',
            shortcutLabel: 'Ctrl /',
            keywords: ['hotkeys', 'commands'],
          ),
        ],
      ),
      const DocumentMoreOptionGroup(
        title: 'Organize',
        icon: Icons.folder_outlined,
        options: [
          DocumentMoreOption(
            id: DocumentMoreOptionId.moveToFolder,
            icon: Icons.drive_file_move_outlined,
            title: 'Move to folder',
            keywords: ['organize', 'folder'],
          ),
          DocumentMoreOption(
            id: DocumentMoreOptionId.tags,
            icon: Icons.label_outline,
            title: 'Manage tags',
            keywords: ['labels'],
          ),
        ],
      ),
      const DocumentMoreOptionGroup(
        title: 'Output',
        icon: Icons.ios_share_outlined,
        options: [
          DocumentMoreOption(
            id: DocumentMoreOptionId.insertImage,
            icon: Icons.image_outlined,
            title: 'Insert image',
            subtitle: 'Add image to document',
            keywords: ['photo', 'media'],
          ),
          DocumentMoreOption(
            id: DocumentMoreOptionId.exportAll,
            icon: Icons.send_outlined,
            title: 'Export all formats',
            subtitle: 'DOCX, PDF, and TXT',
            keywords: ['download', 'share'],
          ),
          DocumentMoreOption(
            id: DocumentMoreOptionId.print,
            icon: Icons.print_outlined,
            title: 'Print',
            shortcutLabel: 'Ctrl P',
            keywords: ['paper', 'pdf'],
          ),
        ],
      ),
    ];
  }

  Future<void> _handleOption(
    BuildContext context,
    WidgetRef ref,
    DocumentMoreOptionId option,
  ) async {
    final rootContext = Navigator.of(context, rootNavigator: true).context;
    final messenger = ScaffoldMessenger.of(context);
    final currentDocState = ref.read(documentProvider);
    final documentNotifier = ref.read(documentProvider.notifier);
    final statistics = ref.read(statisticsProvider);
    final actionPolicy = DocumentEditorActionPolicy(editingMode: editingMode);
    Navigator.pop(context);

    switch (option) {
      case DocumentMoreOptionId.rename:
        await _renameDocument(
          rootContext,
          currentTitle: currentDocState.metadata.title,
          onRename: documentNotifier.updateTitle,
          messenger: messenger,
        );
      case DocumentMoreOptionId.findReplace:
        await _showFindReplace(
          rootContext,
          docState: currentDocState,
          editingMode: editingMode,
          onShowFindReplace: onShowFindReplace,
        );
      case DocumentMoreOptionId.aiAssistant:
        await _showAIAssistant(
          rootContext,
          actionPolicy: actionPolicy,
          onShowAIAssistant: onShowAIAssistant,
        );
      case DocumentMoreOptionId.insertTools:
        await _showInsertTools(
          rootContext,
          actionPolicy: actionPolicy,
          onShowInsertPanel: onShowInsertPanel,
        );
      case DocumentMoreOptionId.outline:
        await _navigationLauncher.showOutline(
          rootContext,
          docState: currentDocState,
          onShowOutline: onShowOutline,
        );
      case DocumentMoreOptionId.pageNavigator:
        await _navigationLauncher.showPageNavigator(
          rootContext,
          docState: currentDocState,
          onSelectPage: documentNotifier.selectPage,
          onShowPageNavigator: onShowPageNavigator,
        );
      case DocumentMoreOptionId.duplicate:
        await _duplicateDocument(rootContext, ref, messenger);
      case DocumentMoreOptionId.pageSettings:
        _showPageSettingsDialog(rootContext);
      case DocumentMoreOptionId.theme:
        _showThemeDialog(rootContext);
      case DocumentMoreOptionId.collaboration:
        _showCollaborationDialog(rootContext);
      case DocumentMoreOptionId.statistics:
        await _showStatistics(
          rootContext,
          statistics: statistics,
          onShowStatistics: onShowStatistics,
        );
      case DocumentMoreOptionId.spellCheck:
        _handleSpellCheck(rootContext, ref, messenger);
      case DocumentMoreOptionId.footnotes:
        _showFootnotesDialog(rootContext);
      case DocumentMoreOptionId.insertImage:
        await _insertImage(rootContext, ref, messenger);
      case DocumentMoreOptionId.exportAll:
        await _exportAllFormats(rootContext, ref, messenger);
      case DocumentMoreOptionId.moveToFolder:
        _showMoveToFolderDialog(rootContext, ref);
      case DocumentMoreOptionId.tags:
        _showTagsDialog(rootContext);
      case DocumentMoreOptionId.versionHistory:
        _showVersionHistory(rootContext);
      case DocumentMoreOptionId.print:
        await _printDocument(rootContext, ref, messenger);
      case DocumentMoreOptionId.documentInfo:
        _showDocumentInfo(rootContext);
      case DocumentMoreOptionId.keyboardShortcuts:
        _showKeyboardShortcuts(rootContext);
    }
  }

  Future<void> _duplicateDocument(
    BuildContext context,
    WidgetRef ref,
    ScaffoldMessengerState messenger,
  ) async {
    await ref.read(documentProvider.notifier).duplicateDocument();
    if (!context.mounted) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('Document duplicated successfully')),
    );
  }

  Future<void> _renameDocument(
    BuildContext context, {
    required String currentTitle,
    required ValueChanged<String> onRename,
    required ScaffoldMessengerState messenger,
  }) async {
    final nextTitle = await DocumentTitleDialog.show(
      context,
      title: currentTitle,
    );
    if (nextTitle == null) return;

    onRename(nextTitle);
    messenger.showSnackBar(const SnackBar(content: Text('Document renamed')));
  }

  Future<void> _showFindReplace(
    BuildContext context, {
    required DocumentState docState,
    required DocumentEditingMode editingMode,
    required VoidCallback? onShowFindReplace,
  }) async {
    if (onShowFindReplace != null) {
      onShowFindReplace();
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: DocxFindReplacePanel(
            controller: docState.controller,
            editingMode: editingMode,
            onClose: () => Navigator.pop(context),
          ),
        );
      },
    );
  }

  Future<void> _showAIAssistant(
    BuildContext context, {
    required DocumentEditorActionPolicy actionPolicy,
    required VoidCallback? onShowAIAssistant,
  }) async {
    if (!actionPolicy.canUseAIAssistant) return;
    if (onShowAIAssistant != null) {
      onShowAIAssistant();
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: AIAssistantPanel(onClose: () => Navigator.pop(sheetContext)),
        );
      },
    );
  }

  Future<void> _showInsertTools(
    BuildContext context, {
    required DocumentEditorActionPolicy actionPolicy,
    required VoidCallback? onShowInsertPanel,
  }) async {
    if (!actionPolicy.canInsertContent) return;
    if (onShowInsertPanel != null) {
      onShowInsertPanel();
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: InsertElementsPanel(
            onClose: () => Navigator.pop(sheetContext),
          ),
        );
      },
    );
  }

  Future<void> _showStatistics(
    BuildContext context, {
    required DocumentStatistics statistics,
    required VoidCallback? onShowStatistics,
  }) async {
    if (onShowStatistics != null) {
      onShowStatistics();
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: DocumentStatisticsPanel(
            statistics: statistics,
            onOpenWritingInsights: () {
              Navigator.pop(sheetContext);
              DocumentWritingInsightsDialog.show(
                context,
                insights: statistics.writingInsights,
              );
            },
          ),
        );
      },
    );
  }

  void _handleSpellCheck(
    BuildContext context,
    WidgetRef ref,
    ScaffoldMessengerState messenger,
  ) {
    if (ref.read(documentProvider).spellCheckEnabled) {
      _showSpellCheckDialog(context);
      return;
    }

    ref.read(documentProvider.notifier).toggleSpellCheck();
    messenger.showSnackBar(
      const SnackBar(content: Text('Spell check enabled')),
    );
  }

  Future<void> _insertImage(
    BuildContext context,
    WidgetRef ref,
    ScaffoldMessengerState messenger,
  ) async {
    await ref.read(documentProvider.notifier).insertImage();
    if (!context.mounted) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('Image insertion is a placeholder feature')),
    );
  }

  Future<void> _exportAllFormats(
    BuildContext context,
    WidgetRef ref,
    ScaffoldMessengerState messenger,
  ) async {
    final paths = await ref
        .read(documentProvider.notifier)
        .exportToMultipleFormats();
    if (!context.mounted || paths.isEmpty) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text('Exported to ${paths.length} formats'),
        action: SnackBarAction(
          label: 'Share',
          onPressed: () {
            SharePlus.instance.share(
              ShareParams(files: paths.map((path) => XFile(path)).toList()),
            );
          },
        ),
      ),
    );
  }

  Future<void> _printDocument(
    BuildContext context,
    WidgetRef ref,
    ScaffoldMessengerState messenger,
  ) async {
    try {
      final docState = ref.read(documentProvider);
      final text = docState.controller.document.toPlainText();
      await Printing.layoutPdf(
        onLayout: (format) async {
          final pdf = pw.Document();
          final font = await PdfGoogleFonts.robotoRegular();
          pdf.addPage(
            pw.Page(
              build: (context) =>
                  pw.Text(text, style: pw.TextStyle(font: font)),
            ),
          );
          return pdf.save();
        },
      );
    } catch (error) {
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Print error: $error')));
    }
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => ThemeDialog());
  }

  void _showDocumentInfo(BuildContext context) {
    showDialog(context: context, builder: (context) => DocumentInfoDialog());
  }

  void _showKeyboardShortcuts(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => KeyboardShortcutDialog(),
    );
  }

  void _showCollaborationDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => CollaborationDialog());
  }

  void _showSpellCheckDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => SpellCheckDialog());
  }

  void _showPageSettingsDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => PageSettingDialog());
  }

  void _showFootnotesDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => FootnotesDialog());
  }

  void _showMoveToFolderDialog(BuildContext context, WidgetRef ref) {
    final foldersAsync = ref.read(foldersProvider);
    foldersAsync.whenData((folders) {
      showDialog(
        context: context,
        builder: (context) => MoveToFolderDialog(folders: folders),
      );
    });
  }

  void _showTagsDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => TagsDialog());
  }

  void _showVersionHistory(BuildContext context) {
    showDialog(context: context, builder: (context) => VersionHistoryDialog());
  }
}
