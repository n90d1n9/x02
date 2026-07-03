import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/aiaction.dart';
import '../models/document_editor_action_policy.dart';
import '../models/document_editing_mode.dart';
import '../models/document_outline.dart';
import '../models/document_state.dart';
import '../services/document_outline_service.dart';
import '../services/document_statistics.dart';
import '../states/provider.dart';
import 'blank_document/blank_document_starter_host.dart';
import 'document_editor_canvas.dart';
import 'document_formatting_toolbar.dart';
import 'document_embedded_content_panel.dart';
import 'outline/outline_panel.dart';
import 'navigation/document_workspace_navigation_state.dart';
import 'page_navigation/document_page_navigation_model.dart';
import 'page_navigation/document_page_navigator_panel.dart';
import 'page_setting_dialog.dart';
import 'review_mode/document_editing_mode_banner.dart';
import 'review_mode/document_editing_mode_controller_binding.dart';
import 'review_hub/document_review_hub_panel.dart';
import 'review_hub/document_side_panel.dart';
import 'selection_toolbar/document_selection_toolbar_host.dart';
import 'workspace_activity/document_workspace_activity_bar.dart';
import 'workspace_activity/document_workspace_activity_item.dart';
import 'workspace_panel/document_workspace_panel_dock.dart';
import 'workspace_panel/document_workspace_panel_id.dart';
import 'workspace_panel/document_workspace_panel_policy.dart';

/// Composes the document editor shell, side panels, canvas, and editing chrome.
class DocumentEditorWorkspace extends ConsumerWidget {
  static const _outlineService = DocumentOutlineService();

  final DocumentState documentState;
  final DocumentTextStatistics statistics;
  final DocumentWorkspaceNavigationState navigationState;
  final DocumentSidePanel? activeSidePanel;
  final DocumentWorkspacePanelId? activeWorkspacePanel;
  final Widget? workspacePanel;
  final double workspacePanelWidth;
  final DocumentEditingMode editingMode;
  final double zoom;
  final FocusNode focusNode;
  final ValueChanged<DocumentSidePanel>? onSidePanelChanged;
  final ValueChanged<DocumentEditingMode>? onEditingModeChanged;
  final VoidCallback? onCloseSidePanel;
  final VoidCallback? onToggleStatistics;
  final VoidCallback? onToggleFindReplace;
  final VoidCallback? onToggleAIAssistant;
  final VoidCallback? onToggleInsertMenu;
  final ValueChanged<DocumentWorkspacePanelId>? onWorkspacePanelChanged;
  final ValueChanged<double>? onWorkspacePanelWidthChanged;
  final VoidCallback? onCloseWorkspacePanel;
  final VoidCallback? onToggleOutline;
  final VoidCallback? onTogglePageNavigator;
  final VoidCallback? onOpenWritingInsights;
  final VoidCallback? onOpenOutline;
  final VoidCallback? onOpenPageNavigator;
  final VoidCallback? onCloseNavigationPanel;

  const DocumentEditorWorkspace({
    super.key,
    required this.documentState,
    required this.statistics,
    this.navigationState = const DocumentWorkspaceNavigationState.closed(),
    required this.activeSidePanel,
    this.activeWorkspacePanel,
    this.workspacePanel,
    this.workspacePanelWidth = DocumentWorkspacePanelDock.defaultSideWidth,
    this.editingMode = DocumentEditingMode.editing,
    this.zoom = 1.0,
    required this.focusNode,
    this.onSidePanelChanged,
    this.onEditingModeChanged,
    this.onCloseSidePanel,
    this.onToggleStatistics,
    this.onToggleFindReplace,
    this.onToggleAIAssistant,
    this.onToggleInsertMenu,
    this.onWorkspacePanelChanged,
    this.onWorkspacePanelWidthChanged,
    this.onCloseWorkspacePanel,
    this.onToggleOutline,
    this.onTogglePageNavigator,
    this.onOpenWritingInsights,
    this.onOpenOutline,
    this.onOpenPageNavigator,
    this.onCloseNavigationPanel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        if (editingMode.showsFormattingToolbar)
          DocumentFormattingToolbar(controller: documentState.controller),
        if (editingMode.showsWorkspaceBanner)
          DocumentEditingModeBanner(
            mode: editingMode,
            onPrimaryAction: _handleModeBannerAction,
          ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final showReviewHub = activeSidePanel != null;
              final showSideReviewHub =
                  showReviewHub && constraints.maxWidth >= 900;
              final showNavigationRail = navigationState.isOpen;
              final showActivityBar = constraints.maxWidth >= 760;
              final showWorkspacePanel =
                  activeWorkspacePanel != null && workspacePanel != null;
              final showSideWorkspacePanel =
                  showWorkspacePanel &&
                  constraints.maxWidth >= 980 &&
                  !showSideReviewHub;
              final actionPolicy = DocumentEditorActionPolicy(
                editingMode: editingMode,
              );
              final panelPolicy = DocumentWorkspacePanelPolicy(
                actionPolicy: actionPolicy,
              );
              final sideWorkspacePanelWidth =
                  DocumentWorkspacePanelDock.clampSideWidth(
                    workspacePanelWidth,
                  );

              return Row(
                children: [
                  if (showActivityBar)
                    DocumentWorkspaceActivityBar(
                      groups: _buildActivityGroups(actionPolicy),
                    ),
                  if (showNavigationRail)
                    SizedBox(
                      width: navigationState.railWidth,
                      child: navigationState.showsPages
                          ? DocumentPageNavigatorPanel(
                              model: DocumentPageNavigationModel(
                                currentPage: documentState.currentPage,
                                totalPages: documentState.totalPages,
                                pageSettings: documentState.pageSettings,
                              ),
                              onPageSelected: (pageNumber) {
                                ref
                                    .read(documentProvider.notifier)
                                    .selectPage(pageNumber);
                                _jumpToPage(pageNumber);
                              },
                              onOpenOutline: onOpenOutline,
                              onClose: onCloseNavigationPanel,
                            )
                          : DocxOutlinePanel(
                              outline: _generateOutline(),
                              onJumpToOffset: _jumpToOutlineOffset,
                              onOpenPageNavigator: onOpenPageNavigator,
                              onClose: onCloseNavigationPanel,
                            ),
                    ),
                  if (showNavigationRail)
                    VerticalDivider(
                      width: 1,
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  Expanded(
                    child: Column(
                      children: [
                        if (showWorkspacePanel && !showSideWorkspacePanel)
                          SizedBox(
                            width: double.infinity,
                            height: DocumentWorkspacePanelDock.stackedHeight,
                            child: DocumentWorkspacePanelDock(
                              activePanel: activeWorkspacePanel!,
                              sideBySide: false,
                              panels: _workspacePanelOptions(panelPolicy),
                              onPanelSelected: onWorkspacePanelChanged,
                              onClose: onCloseWorkspacePanel,
                              child: workspacePanel!,
                            ),
                          ),
                        if (showReviewHub && !showSideReviewHub)
                          SizedBox(
                            height: 360,
                            child: _buildReviewHubPanel(ref),
                          ),
                        if (showReviewHub && !showSideReviewHub)
                          Divider(
                            height: 1,
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withValues(alpha: 0.2),
                          ),
                        Expanded(
                          child: DocumentSelectionToolbarHost(
                            controller: documentState.controller,
                            editingMode: editingMode,
                            aiProcessing: documentState.isAIProcessing,
                            onOpenComments: () => onSidePanelChanged?.call(
                              DocumentSidePanel.comments,
                            ),
                            onImproveSelection: () => ref
                                .read(documentProvider.notifier)
                                .applyAIAction(AIAction.improve),
                            onOpenTrackChanges: () => onSidePanelChanged?.call(
                              DocumentSidePanel.trackChanges,
                            ),
                            onRequestEditorFocus: focusNode.requestFocus,
                            child: DocumentEditingModeControllerBinding(
                              controller: documentState.controller,
                              mode: editingMode,
                              child: DocumentEditorCanvas(
                                layout: documentState.currentLayout,
                                pageSettings: documentState.pageSettings,
                                currentPage: documentState.currentPage,
                                zoom: zoom,
                                onPageSettingsChanged: editingMode.isReadOnly
                                    ? null
                                    : (settings) {
                                        ref
                                            .read(documentProvider.notifier)
                                            .updatePageSettings(settings);
                                      },
                                onPageSettingsPressed: editingMode.isReadOnly
                                    ? null
                                    : () => _showPageSettingsDialog(context),
                                child: BlankDocumentStarterHost(
                                  controller: documentState.controller,
                                  onRequestEditorFocus: focusNode.requestFocus,
                                  child: quill.QuillEditor.basic(
                                    controller: documentState.controller,
                                    config: const quill.QuillEditorConfig(
                                      padding: EdgeInsets.all(16),
                                      autoFocus: false,
                                      expands: true,
                                      placeholder:
                                          'Start typing your document here...',
                                    ),
                                    focusNode: focusNode,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        DocumentEmbeddedContentPanel(
                          tables: documentState.tables,
                          charts: documentState.charts,
                          drawings: documentState.drawings,
                          onDeleteChart: (chartId) => ref
                              .read(documentProvider.notifier)
                              .deleteChart(chartId),
                        ),
                      ],
                    ),
                  ),
                  if (showSideWorkspacePanel)
                    SizedBox(
                      width: sideWorkspacePanelWidth,
                      child: DocumentWorkspacePanelDock(
                        activePanel: activeWorkspacePanel!,
                        sideBySide: true,
                        currentSideWidth: sideWorkspacePanelWidth,
                        panels: _workspacePanelOptions(panelPolicy),
                        onPanelSelected: onWorkspacePanelChanged,
                        onSideWidthChanged: onWorkspacePanelWidthChanged,
                        onClose: onCloseWorkspacePanel,
                        child: workspacePanel!,
                      ),
                    ),
                  if (showSideReviewHub)
                    SizedBox(width: 390, child: _buildReviewHubPanel(ref)),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReviewHubPanel(WidgetRef ref) {
    return DocumentReviewHubPanel(
      activePanel: activeSidePanel!,
      onPanelChanged: onSidePanelChanged ?? (_) {},
      statistics: statistics,
      comments: documentState.comments,
      trackedChanges: documentState.trackedChanges,
      editingMode: editingMode,
      onAddComment: (text) {
        ref.read(documentProvider.notifier).addComment(text);
      },
      onJumpToComment: (comment) => _jumpToOffset(comment.offset),
      onResolveComment: (comment) {
        ref.read(documentProvider.notifier).resolveComment(comment.id);
      },
      onReopenComment: (comment) {
        ref.read(documentProvider.notifier).reopenComment(comment.id);
      },
      onDeleteComment: (comment) {
        ref.read(documentProvider.notifier).deleteComment(comment.id);
      },
      onProposeChange: (replacementText) {
        ref
            .read(documentProvider.notifier)
            .proposeTrackedChange(replacementText);
      },
      onJumpToChange: (change) => _jumpToOffset(change.offset),
      onAcceptChange: (change) {
        ref.read(documentProvider.notifier).acceptTrackedChange(change.id);
      },
      onRejectChange: (change) {
        ref.read(documentProvider.notifier).rejectTrackedChange(change.id);
      },
      onDeleteChange: (change) {
        ref.read(documentProvider.notifier).deleteTrackedChange(change.id);
      },
      onClose: onCloseSidePanel,
      onOpenWritingInsights: onOpenWritingInsights,
    );
  }

  List<DocumentWorkspaceActivityGroup> _buildActivityGroups(
    DocumentEditorActionPolicy actionPolicy,
  ) {
    return [
      DocumentWorkspaceActivityGroup(
        semanticLabel: 'Navigation shortcuts',
        items: [
          DocumentWorkspaceActivityItem(
            id: DocumentWorkspaceActivityId.outline,
            icon: Icons.account_tree_outlined,
            selectedIcon: Icons.account_tree,
            tooltip: navigationState.showsOutline
                ? 'Close document outline'
                : 'Open document outline',
            active: navigationState.showsOutline,
            onPressed: _navigationToggle(
              active: navigationState.showsOutline,
              onToggle: onToggleOutline,
              onOpen: onOpenOutline,
            ),
          ),
          DocumentWorkspaceActivityItem(
            id: DocumentWorkspaceActivityId.pages,
            icon: Icons.view_agenda_outlined,
            selectedIcon: Icons.view_agenda,
            tooltip: navigationState.showsPages
                ? 'Close page navigator'
                : 'Open page navigator',
            active: navigationState.showsPages,
            onPressed: _navigationToggle(
              active: navigationState.showsPages,
              onToggle: onTogglePageNavigator,
              onOpen: onOpenPageNavigator,
            ),
          ),
        ],
      ),
      DocumentWorkspaceActivityGroup(
        semanticLabel: 'Review shortcuts',
        items: [
          DocumentWorkspaceActivityItem(
            id: DocumentWorkspaceActivityId.review,
            icon: Icons.rate_review_outlined,
            selectedIcon: Icons.rate_review,
            tooltip: activeSidePanel == null
                ? 'Open review hub'
                : 'Close review hub',
            active: activeSidePanel != null,
            onPressed: _reviewHubToggle,
          ),
          DocumentWorkspaceActivityItem(
            id: DocumentWorkspaceActivityId.statistics,
            icon: Icons.analytics_outlined,
            selectedIcon: Icons.analytics,
            tooltip: _activeUtilityPanel(DocumentWorkspacePanelId.statistics)
                ? 'Hide writing statistics'
                : 'Show writing statistics',
            active: _activeUtilityPanel(DocumentWorkspacePanelId.statistics),
            onPressed: onToggleStatistics,
          ),
          DocumentWorkspaceActivityItem(
            id: DocumentWorkspaceActivityId.findReplace,
            icon: Icons.find_replace_outlined,
            selectedIcon: Icons.find_replace,
            tooltip: _activeUtilityPanel(DocumentWorkspacePanelId.findReplace)
                ? 'Hide find and replace'
                : 'Show find and replace',
            active: _activeUtilityPanel(DocumentWorkspacePanelId.findReplace),
            onPressed: onToggleFindReplace,
          ),
        ],
      ),
      DocumentWorkspaceActivityGroup(
        semanticLabel: 'Creation shortcuts',
        items: [
          DocumentWorkspaceActivityItem(
            id: DocumentWorkspaceActivityId.aiAssistant,
            icon: Icons.psychology_outlined,
            selectedIcon: Icons.psychology,
            tooltip: _activeUtilityPanel(DocumentWorkspacePanelId.aiAssistant)
                ? 'Hide AI assistant'
                : 'Open AI assistant',
            disabledTooltip: actionPolicy.lockedMutationReason,
            active: _activeUtilityPanel(DocumentWorkspacePanelId.aiAssistant),
            enabled: actionPolicy.canUseAIAssistant,
            onPressed: onToggleAIAssistant,
          ),
          DocumentWorkspaceActivityItem(
            id: DocumentWorkspaceActivityId.insert,
            icon: Icons.add_box_outlined,
            selectedIcon: Icons.add_box,
            tooltip: _activeUtilityPanel(DocumentWorkspacePanelId.insert)
                ? 'Hide insert tools'
                : 'Open insert tools',
            disabledTooltip: actionPolicy.lockedMutationReason,
            active: _activeUtilityPanel(DocumentWorkspacePanelId.insert),
            enabled: actionPolicy.canInsertContent,
            onPressed: onToggleInsertMenu,
          ),
        ],
      ),
    ];
  }

  bool _activeUtilityPanel(DocumentWorkspacePanelId panel) {
    return activeWorkspacePanel == panel;
  }

  List<DocumentWorkspacePanelDockOption> _workspacePanelOptions(
    DocumentWorkspacePanelPolicy panelPolicy,
  ) {
    return [
      for (final panel in panelPolicy.panels)
        DocumentWorkspacePanelDockOption(
          id: panel.id,
          enabled: panel.enabled,
          disabledTooltip: panel.disabledReason,
        ),
    ];
  }

  VoidCallback? _navigationToggle({
    required bool active,
    required VoidCallback? onToggle,
    required VoidCallback? onOpen,
  }) {
    if (onToggle != null) return onToggle;
    if (active) return onCloseNavigationPanel;
    return onOpen;
  }

  VoidCallback? get _reviewHubToggle {
    if (activeSidePanel != null) return onCloseSidePanel;
    if (onSidePanelChanged == null) return null;
    return () => onSidePanelChanged?.call(DocumentSidePanel.review);
  }

  void _handleModeBannerAction() {
    switch (editingMode) {
      case DocumentEditingMode.editing:
        break;
      case DocumentEditingMode.suggesting:
        onSidePanelChanged?.call(DocumentSidePanel.trackChanges);
        break;
      case DocumentEditingMode.viewing:
        onEditingModeChanged?.call(DocumentEditingMode.editing);
        break;
    }
  }

  void _showPageSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const PageSettingDialog(),
    );
  }

  void _jumpToOutlineOffset(int offset) {
    _jumpToOffset(offset);
  }

  List<DocumentOutline> _generateOutline() {
    var nextId = 0;
    return _outlineService.generateOutline(
      text: documentState.controller.document.toPlainText(),
      createId: () => 'workspace-outline-${++nextId}',
    );
  }

  void _jumpToPage(int pageNumber) {
    final totalPages = documentState.totalPages.clamp(1, 9999).toInt();
    final normalizedPage = pageNumber.clamp(1, totalPages).toInt();
    final textLength = documentState.controller.document.toPlainText().length;
    final offset = totalPages == 1
        ? 0
        : (((normalizedPage - 1) / totalPages) * textLength).round();

    _jumpToOffset(offset.clamp(0, textLength).toInt());
  }

  void _jumpToOffset(int offset) {
    documentState.controller.updateSelection(
      TextSelection.collapsed(offset: offset),
      quill.ChangeSource.local,
    );
    focusNode.requestFocus();
  }
}
