import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/document_editor_action_policy.dart';
import '../models/document_editing_mode.dart';
import '../models/document_state.dart';
import '../models/page_layout.dart';
import '../services/document_editor_commands.dart';
import '../services/document_editor_lifecycle.dart';
import '../services/document_statistics.dart';
import '../states/provider.dart';
import '../widgets/command_palette/document_command.dart';
import '../widgets/command_palette/document_editor_command_catalog.dart';
import '../widgets/command_palette/document_command_palette.dart';
import '../widgets/ai_assistant_panel.dart';
import '../widgets/document_editor_app_bar.dart';
import '../widgets/document_editor_shortcuts.dart';
import '../widgets/document_editor_workspace.dart';
import '../widgets/document_error_banner.dart';
import '../widgets/document_status_bar.dart';
import '../widgets/document_statistics_panel.dart';
import '../widgets/document_title_dialog.dart';
import '../widgets/document_writing_insights_dialog.dart';
import '../widgets/collaboration_dialog.dart';
import '../widgets/find_replace/find_replace_panel.dart';
import '../widgets/insert_elements/insert_elements_panel.dart';
import '../widgets/more_options.dart';
import '../widgets/navigation/document_navigation_panel_switcher.dart';
import '../widgets/navigation/document_workspace_navigation_state.dart';
import '../widgets/review_hub/document_side_panel.dart';
import '../widgets/workspace_panel/document_workspace_panel_dock.dart';
import '../widgets/workspace_panel/document_workspace_panel_id.dart';
import '../widgets/workspace_panel/document_workspace_panel_policy.dart';

/// Hosts the full document editing route and coordinates top-level panels.
class DocumentEditorPage extends ConsumerStatefulWidget {
  const DocumentEditorPage({super.key});

  @override
  ConsumerState<DocumentEditorPage> createState() => _DocumentEditorPageState();
}

class _DocumentEditorPageState extends ConsumerState<DocumentEditorPage> {
  static const _minZoom = 0.5;
  static const _maxZoom = 1.5;
  static const _zoomStep = 0.1;

  final _focusNode = FocusNode();
  DocumentWorkspacePanelId? _activeWorkspacePanel;
  var _navigationState = const DocumentWorkspaceNavigationState.closed();
  DocumentSidePanel? _activeSidePanel;
  DocumentEditingMode _editingMode = DocumentEditingMode.editing;
  double _zoom = 1.0;
  double _workspacePanelWidth = DocumentWorkspacePanelDock.defaultSideWidth;
  late final DocumentEditorLifecycle _lifecycle;

  bool get _showStatistics =>
      _activeWorkspacePanel == DocumentWorkspacePanelId.statistics;

  bool get _showFindReplace =>
      _activeWorkspacePanel == DocumentWorkspacePanelId.findReplace;

  bool get _showAIAssistant =>
      _activeWorkspacePanel == DocumentWorkspacePanelId.aiAssistant;

  bool get _showInsertMenu =>
      _activeWorkspacePanel == DocumentWorkspacePanelId.insert;

  @override
  void initState() {
    super.initState();
    _lifecycle = DocumentEditorLifecycle(ref)..start(context);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final docState = ref.watch(documentProvider);
    final stats = ref.watch(statisticsProvider);
    final commands = DocumentEditorCommands(ref);

    return DocumentEditorShortcuts(
      canSave: docState.hasUnsavedChanges,
      onSave: () => commands.saveFromShortcut(context),
      onToggleFindReplace: () =>
          _toggleWorkspacePanel(DocumentWorkspacePanelId.findReplace),
      onShowFindReplace: _showFindReplacePanel,
      onOpenCommandPalette: () => _showCommandPalette(context, commands),
      onPrint: () => commands.print(context),
      onCreateNewDocument: commands.createNewDocument,
      child: Scaffold(
        appBar: DocumentEditorAppBar(
          documentState: docState,
          showStatistics: _showStatistics,
          showFindReplace: _showFindReplace,
          showAIAssistant: _showAIAssistant,
          showInsertMenu: _showInsertMenu,
          showOutline: _navigationState.showsOutline,
          showPageNavigator: _navigationState.showsPages,
          activeSidePanel: _activeSidePanel,
          editingMode: _editingMode,
          onEditTitle: () => _showTitleDialog(context),
          onToggleFavorite: _toggleFavorite,
          onToggleStatistics: _toggleStatistics,
          onToggleFindReplace: () =>
              _toggleWorkspacePanel(DocumentWorkspacePanelId.findReplace),
          onToggleAIAssistant: _toggleAIAssistant,
          onToggleInsertMenu: _toggleInsertMenu,
          onToggleOutline: _toggleOutline,
          onTogglePageNavigator: _togglePageNavigator,
          onToggleSidePanel: _toggleSidePanel,
          onEditingModeChanged: _setEditingMode,
          onToggleSpellCheck: () {
            ref.read(documentProvider.notifier).toggleSpellCheck();
          },
          onSave: () => commands.save(context),
          onImport: (value) => commands.import(context, value),
          onExport: (value) => commands.export(context, value),
          onSetPageLayout: _setPageLayout,
          onOpenCommandPalette: () => _showCommandPalette(context, commands),
          onOpenCollaboration: () => _showCollaborationDialog(context),
          onMoreOptions: () => _showMoreOptions(context),
        ),
        body: docState.isLoading
            ? _DocumentLoadingView(
                message: docState.importStatus.isActive
                    ? docState.importStatus.message
                    : 'Working...',
              )
            : Column(
                children: [
                  if (docState.errorMessage != null)
                    DocumentErrorBanner(
                      message: docState.errorMessage!,
                      onDismiss: () {
                        ref.read(documentProvider.notifier).clearError();
                      },
                    ),
                  Expanded(
                    child: DocumentEditorWorkspace(
                      documentState: docState,
                      statistics: stats.snapshot,
                      navigationState: _navigationState,
                      activeSidePanel: _activeSidePanel,
                      activeWorkspacePanel: _activeWorkspacePanel,
                      workspacePanel: _buildWorkspacePanel(docState, stats),
                      workspacePanelWidth: _workspacePanelWidth,
                      editingMode: _editingMode,
                      zoom: _zoom,
                      focusNode: _focusNode,
                      onSidePanelChanged: _openSidePanel,
                      onEditingModeChanged: _setEditingMode,
                      onCloseSidePanel: _closeSidePanel,
                      onToggleStatistics: _toggleStatistics,
                      onToggleFindReplace: () => _toggleWorkspacePanel(
                        DocumentWorkspacePanelId.findReplace,
                      ),
                      onToggleAIAssistant: _toggleAIAssistant,
                      onToggleInsertMenu: _toggleInsertMenu,
                      onWorkspacePanelChanged: _openWorkspacePanel,
                      onWorkspacePanelWidthChanged: _setWorkspacePanelWidth,
                      onCloseWorkspacePanel: _closeWorkspacePanel,
                      onToggleOutline: _toggleOutline,
                      onTogglePageNavigator: _togglePageNavigator,
                      onOpenOutline: _showOutlinePanel,
                      onOpenPageNavigator: _showPageNavigatorPanel,
                      onCloseNavigationPanel: _closeNavigationPanel,
                      onOpenWritingInsights: () {
                        DocumentWritingInsightsDialog.show(
                          context,
                          insights: stats.writingInsights,
                        );
                      },
                    ),
                  ),
                  DocumentStatusBar(
                    documentState: docState,
                    statistics: stats,
                    editingMode: _editingMode,
                    zoom: _zoom,
                    onZoomOut: _zoomOut,
                    onZoomIn: _zoomIn,
                    onResetZoom: _resetZoom,
                    onZoomChanged: _setZoom,
                    onSetPageLayout: _setPageLayout,
                    onOpenPageNavigator: _showPageNavigatorPanel,
                  ),
                ],
              ),
      ),
    );
  }

  Widget? _buildWorkspacePanel(
    DocumentState docState,
    DocumentStatistics stats,
  ) {
    return switch (_activeWorkspacePanel) {
      DocumentWorkspacePanelId.statistics => DocumentStatisticsPanel(
        statistics: stats,
        onOpenWritingInsights: () => _showWritingInsights(stats),
      ),
      DocumentWorkspacePanelId.findReplace => DocxFindReplacePanel(
        controller: docState.controller,
        editingMode: _editingMode,
        showHeader: false,
      ),
      DocumentWorkspacePanelId.aiAssistant => const AIAssistantPanel(
        showHeader: false,
      ),
      DocumentWorkspacePanelId.insert => const InsertElementsPanel(
        showHeader: false,
      ),
      null => null,
    };
  }

  void _showWritingInsights(DocumentStatistics stats) {
    DocumentWritingInsightsDialog.show(
      context,
      insights: stats.writingInsights,
    );
  }

  void _showFindReplacePanel() {
    _openWorkspacePanel(DocumentWorkspacePanelId.findReplace);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) FocusScope.of(context).requestFocus(FocusNode());
    });
  }

  void _toggleStatistics() {
    _toggleWorkspacePanel(DocumentWorkspacePanelId.statistics);
  }

  void _showStatisticsPanel() {
    _openWorkspacePanel(DocumentWorkspacePanelId.statistics);
  }

  Future<void> _showTitleDialog(BuildContext context) async {
    final actionPolicy = DocumentEditorActionPolicy(editingMode: _editingMode);
    if (!actionPolicy.canEditMetadata) return;

    final title = await DocumentTitleDialog.show(
      context,
      title: ref.read(documentProvider).metadata.title,
    );
    if (title == null) return;
    ref.read(documentProvider.notifier).updateTitle(title);
  }

  void _toggleFavorite() {
    final actionPolicy = DocumentEditorActionPolicy(editingMode: _editingMode);
    if (!actionPolicy.canEditMetadata) return;
    ref.read(documentProvider.notifier).toggleFavorite();
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => MoreOptions(
        editingMode: _editingMode,
        onShowStatistics: _showStatisticsPanel,
        onShowFindReplace: _showFindReplacePanel,
        onShowAIAssistant: _showAIAssistantPanel,
        onShowInsertPanel: _showInsertPanel,
        onShowOutline: _showOutlinePanel,
        onShowPageNavigator: _showPageNavigatorPanel,
      ),
    );
  }

  void _showCollaborationDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => CollaborationDialog());
  }

  Future<void> _showCommandPalette(
    BuildContext context,
    DocumentEditorCommands commands,
  ) async {
    final selectedCommand = await DocumentCommandPalette.show(
      context,
      commands: _buildCommands(context, commands),
    );
    if (selectedCommand == null) return;
    await selectedCommand.onSelected();
  }

  List<DocumentCommand> _buildCommands(
    BuildContext context,
    DocumentEditorCommands commands,
  ) {
    final docState = ref.read(documentProvider);
    return DocumentEditorCommandCatalog(
      documentState: docState,
      editingMode: _editingMode,
      onSave: () => commands.save(context),
      onShowFindReplace: _showFindReplacePanel,
      onOpenSidePanel: _openSidePanel,
      onSetEditingMode: _setEditingMode,
      onShowStatistics: _showStatisticsPanel,
      onShowAIAssistant: _showAIAssistantPanel,
      onShowInsertPanel: _showInsertPanel,
      onShowPageNavigator: _showPageNavigatorPanel,
      onOpenCollaboration: () => _showCollaborationDialog(context),
      onPrint: () => commands.print(context),
      onCreateNewDocument: commands.createNewDocument,
      onSetPageLayout: _setPageLayout,
    ).build();
  }

  void _setPageLayout(PageLayout layout) {
    ref.read(documentProvider.notifier).setPageLayout(layout);
  }

  void _setEditingMode(DocumentEditingMode mode) {
    setState(() {
      _editingMode = mode;
      final panelPolicy = DocumentWorkspacePanelPolicy(
        actionPolicy: DocumentEditorActionPolicy(editingMode: mode),
      );
      if (_activeWorkspacePanel != null &&
          !panelPolicy.canOpen(_activeWorkspacePanel!)) {
        _activeWorkspacePanel = null;
      }
    });
  }

  void _toggleAIAssistant() {
    final actionPolicy = DocumentEditorActionPolicy(editingMode: _editingMode);
    if (!actionPolicy.canUseAIAssistant) return;
    _toggleWorkspacePanel(DocumentWorkspacePanelId.aiAssistant);
  }

  void _showAIAssistantPanel() {
    final actionPolicy = DocumentEditorActionPolicy(editingMode: _editingMode);
    if (!actionPolicy.canUseAIAssistant) return;
    _openWorkspacePanel(DocumentWorkspacePanelId.aiAssistant);
  }

  void _toggleInsertMenu() {
    final actionPolicy = DocumentEditorActionPolicy(editingMode: _editingMode);
    if (!actionPolicy.canInsertContent) return;
    _toggleWorkspacePanel(DocumentWorkspacePanelId.insert);
  }

  void _toggleOutline() {
    setState(() {
      _navigationState = _navigationState.toggle(
        DocumentNavigationPanelMode.outline,
      );
    });
  }

  void _togglePageNavigator() {
    setState(() {
      _navigationState = _navigationState.toggle(
        DocumentNavigationPanelMode.pages,
      );
    });
  }

  void _showOutlinePanel() {
    setState(() {
      _navigationState = const DocumentWorkspaceNavigationState.outline();
    });
  }

  void _showPageNavigatorPanel() {
    setState(() {
      _navigationState = const DocumentWorkspaceNavigationState.pages();
    });
  }

  void _closeNavigationPanel() {
    setState(() {
      _navigationState = _navigationState.close();
    });
  }

  void _showInsertPanel() {
    final actionPolicy = DocumentEditorActionPolicy(editingMode: _editingMode);
    if (!actionPolicy.canInsertContent) return;
    _openWorkspacePanel(DocumentWorkspacePanelId.insert);
  }

  void _openWorkspacePanel(DocumentWorkspacePanelId panel) {
    if (!_canOpenWorkspacePanel(panel)) return;
    setState(() => _activeWorkspacePanel = panel);
  }

  void _toggleWorkspacePanel(DocumentWorkspacePanelId panel) {
    if (!_canOpenWorkspacePanel(panel)) return;
    setState(() {
      _activeWorkspacePanel = _activeWorkspacePanel == panel ? null : panel;
    });
  }

  void _closeWorkspacePanel() {
    setState(() => _activeWorkspacePanel = null);
  }

  void _setWorkspacePanelWidth(double width) {
    setState(() {
      _workspacePanelWidth = DocumentWorkspacePanelDock.clampSideWidth(width);
    });
  }

  bool _canOpenWorkspacePanel(DocumentWorkspacePanelId panel) {
    return DocumentWorkspacePanelPolicy(
      actionPolicy: DocumentEditorActionPolicy(editingMode: _editingMode),
    ).canOpen(panel);
  }

  void _toggleSidePanel(DocumentSidePanel panel) {
    setState(() {
      _activeSidePanel = _activeSidePanel == panel ? null : panel;
    });
  }

  void _openSidePanel(DocumentSidePanel panel) {
    setState(() => _activeSidePanel = panel);
  }

  void _closeSidePanel() {
    setState(() => _activeSidePanel = null);
  }

  void _zoomOut() {
    setState(() {
      _zoom = (_zoom - _zoomStep).clamp(_minZoom, _maxZoom).toDouble();
    });
  }

  void _zoomIn() {
    setState(() {
      _zoom = (_zoom + _zoomStep).clamp(_minZoom, _maxZoom).toDouble();
    });
  }

  void _resetZoom() {
    setState(() => _zoom = 1.0);
  }

  void _setZoom(double zoom) {
    setState(() {
      _zoom = zoom.clamp(_minZoom, _maxZoom).toDouble();
    });
  }
}

class _DocumentLoadingView extends StatelessWidget {
  final String message;

  const _DocumentLoadingView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
