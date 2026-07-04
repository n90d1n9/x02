import 'package:flutter/material.dart';

import '../../models/document_change.dart';
import '../../models/comment.dart';
import '../../models/document_editing_mode.dart';
import '../../services/document_statistics.dart';

import '../comments/document_comments_panel.dart';
import '../document_review_panel.dart';
import '../panel/document_panel_header.dart';
import '../panel/document_panel_shell.dart';
import '../panel/document_panel_tab_strip.dart';
import '../track_changes/document_revision_panel.dart';
//import '../widgets/comment_panel.dart';
import 'document_review_action_policy.dart';
import 'document_side_panel.dart';

/// Hosts review, comments, and tracked changes inside one document side rail.
class DocumentReviewHubPanel extends StatelessWidget {
  final DocumentSidePanel activePanel;
  final ValueChanged<DocumentSidePanel> onPanelChanged;
  final DocumentTextStatistics statistics;
  final List<Comment> comments;
  final List<DocumentChange> trackedChanges;
  final DocumentEditingMode editingMode;
  final ValueChanged<String> onAddComment;
  final ValueChanged<Comment> onJumpToComment;
  final ValueChanged<Comment> onResolveComment;
  final ValueChanged<Comment> onReopenComment;
  final ValueChanged<Comment> onDeleteComment;
  final ValueChanged<String> onProposeChange;
  final ValueChanged<DocumentChange> onJumpToChange;
  final ValueChanged<DocumentChange> onAcceptChange;
  final ValueChanged<DocumentChange> onRejectChange;
  final ValueChanged<DocumentChange> onDeleteChange;
  final VoidCallback? onClose;
  final VoidCallback? onOpenWritingInsights;

  const DocumentReviewHubPanel({
    super.key,
    required this.activePanel,
    required this.onPanelChanged,
    required this.statistics,
    required this.comments,
    required this.trackedChanges,
    this.editingMode = DocumentEditingMode.editing,
    required this.onAddComment,
    required this.onJumpToComment,
    required this.onResolveComment,
    required this.onReopenComment,
    required this.onDeleteComment,
    required this.onProposeChange,
    required this.onJumpToChange,
    required this.onAcceptChange,
    required this.onRejectChange,
    required this.onDeleteChange,
    this.onClose,
    this.onOpenWritingInsights,
  });

  @override
  Widget build(BuildContext context) {
    final issueCount = _issueCount;
    final openCommentCount = _openCommentCount;
    final pendingChangeCount = _pendingChangeCount;
    final activeItemCount = _activeItemCount;

    return DocumentPanelShell(
      child: Column(
        children: [
          DocumentPanelHeader(
            icon: Icons.rate_review_outlined,
            title: 'Review Hub',
            subtitle: activeItemCount == 0
                ? 'No active review items'
                : '$activeItemCount active item${activeItemCount == 1 ? '' : 's'}',
            closeTooltip: 'Close review hub',
            onClose: onClose,
          ),
          DocumentPanelTabStrip<DocumentSidePanel>(
            keyPrefix: 'document-review-hub-tab',
            selectedValue: activePanel,
            options: [
              for (final panel in DocumentSidePanel.values)
                DocumentPanelTabOption(
                  value: panel,
                  keySuffix: panel.name,
                  label: panel.label,
                  icon: panel.icon,
                  count: switch (panel) {
                    DocumentSidePanel.review => issueCount,
                    DocumentSidePanel.comments => openCommentCount,
                    DocumentSidePanel.trackChanges => pendingChangeCount,
                  },
                  tooltip: panel.tooltip,
                ),
            ],
            onSelected: onPanelChanged,
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(
              height: 1,
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: 0.54),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _activePanelContent()),
        ],
      ),
    );
  }

  int get _issueCount => statistics.writingInsights.recommendations.length;

  int get _openCommentCount {
    return comments.where((comment) => comment.isOpen).length;
  }

  int get _pendingChangeCount {
    return trackedChanges.where((change) => change.isPending).length;
  }

  int get _activeItemCount {
    return _issueCount + _openCommentCount + _pendingChangeCount;
  }

  Widget _activePanelContent() {
    final actionPolicy = DocumentReviewActionPolicy(editingMode: editingMode);

    return switch (activePanel) {
      DocumentSidePanel.review => DocumentReviewPanel(
        statistics: statistics,
        onOpenWritingInsights: onOpenWritingInsights,
        showHeader: false,
        showFrame: false,
      ),
      DocumentSidePanel.comments => CommentsPanel(
        comments: comments,
        onAddComment: onAddComment,
        onJumpToComment: onJumpToComment,
        onResolveComment: onResolveComment,
        onReopenComment: onReopenComment,
        onDeleteComment: onDeleteComment,
        actionPolicy: actionPolicy,
        showHeader: false,
        showFrame: false,
      ),
      DocumentSidePanel.trackChanges => DocumentRevisionPanel(
        onClose: null,
        showHeader: false,
        showFrame: false,
      ),
    };
  }
}
