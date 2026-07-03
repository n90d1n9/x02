import 'package:flutter/material.dart';

import '../../models/comment.dart';
import '../panel/document_panel_action_row.dart';
import '../panel/document_panel_composer_card.dart';
import '../panel/document_panel_empty_state.dart';
import '../panel/document_panel_filter_bar.dart';
import '../panel/document_panel_header.dart';
import '../panel/document_panel_item_card.dart';
import '../panel/document_panel_result_summary.dart';
import '../panel/document_panel_search_field.dart';
import '../panel/document_panel_shell.dart';
import '../panel/document_panel_status_chip.dart';
import '../review_hub/document_review_action_policy.dart';
import '../review_hub/document_review_locked_notice.dart';
import 'document_comment_search.dart';

/// Displays anchored document comments with add, resolve, reopen, and delete actions.
class CommentsPanel extends StatefulWidget {
  static const searchFieldKey = ValueKey('document-comments-search-field');
  static const clearSearchButtonKey = ValueKey(
    'document-comments-clear-search',
  );
  static const filteredEmptyStateKey = ValueKey(
    'document-comments-filtered-empty-state',
  );

  final List<Comment> comments;
  final ValueChanged<String> onAddComment;
  final ValueChanged<Comment> onJumpToComment;
  final ValueChanged<Comment> onResolveComment;
  final ValueChanged<Comment> onReopenComment;
  final ValueChanged<Comment> onDeleteComment;
  final VoidCallback? onClose;
  final DocumentReviewActionPolicy actionPolicy;
  final bool showHeader;
  final bool showFrame;

  const CommentsPanel({
    super.key,
    required this.comments,
    required this.onAddComment,
    required this.onJumpToComment,
    required this.onResolveComment,
    required this.onReopenComment,
    required this.onDeleteComment,
    this.onClose,
    this.actionPolicy = DocumentReviewActionPolicy.editing,
    this.showHeader = true,
    this.showFrame = true,
  });

  @override
  State<CommentsPanel> createState() => _CommentsPanelState();
}

class _CommentsPanelState extends State<CommentsPanel> {
  final _commentController = TextEditingController();
  final _searchController = TextEditingController();
  var _filter = CommentThreadFilter.open;
  var _query = '';
  var _hasDraft = false;

  @override
  void initState() {
    super.initState();
    _commentController.addListener(_syncDraftState);
  }

  @override
  void dispose() {
    _commentController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final openCount = widget.comments.where((comment) => comment.isOpen).length;
    final searchModel = CommentSearchModel(
      comments: widget.comments,
      query: _query,
      filter: _filter,
    );
    final visibleComments = searchModel.visibleComments;

    final content = Column(
      children: [
        if (widget.showHeader)
          _CommentsHeader(
            totalCount: widget.comments.length,
            openCount: openCount,
            onClose: widget.onClose,
          ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
            children: [
              if (widget.actionPolicy.showsLockedNotice)
                DocumentReviewLockedNotice(
                  title: 'View-only comments',
                  message: widget.actionPolicy.lockedReviewReason,
                )
              else
                _CommentComposer(
                  controller: _commentController,
                  hasDraft: _hasDraft,
                  onSubmit: _submitComment,
                ),
              const SizedBox(height: 14),
              DocumentPanelSearchField(
                fieldKey: CommentsPanel.searchFieldKey,
                clearButtonKey: CommentsPanel.clearSearchButtonKey,
                controller: _searchController,
                hintText: 'Search comments',
                hasQuery: searchModel.hasQuery,
                onChanged: (query) => setState(() => _query = query),
                onClear: _clearSearch,
                clearTooltip: 'Clear comment search',
                tone: DocumentPanelSearchFieldTone.container,
              ),
              const SizedBox(height: 12),
              _CommentFilterTabs(
                filter: _filter,
                openCount: searchModel.countFor(CommentThreadFilter.open),
                resolvedCount: searchModel.countFor(
                  CommentThreadFilter.resolved,
                ),
                onChanged: (filter) => setState(() => _filter = filter),
              ),
              if (widget.comments.isNotEmpty || searchModel.hasQuery) ...[
                const SizedBox(height: 10),
                _CommentResultSummary(
                  model: searchModel,
                  visibleCount: visibleComments.length,
                ),
              ],
              const SizedBox(height: 14),
              if (visibleComments.isEmpty)
                _EmptyCommentState(model: searchModel)
              else
                for (final comment in visibleComments) ...[
                  _CommentThreadCard(
                    comment: comment,
                    onJumpToComment: widget.onJumpToComment,
                    onResolveComment: widget.onResolveComment,
                    onReopenComment: widget.onReopenComment,
                    onDeleteComment: widget.onDeleteComment,
                    actionPolicy: widget.actionPolicy,
                  ),
                  const SizedBox(height: 10),
                ],
            ],
          ),
        ),
      ],
    );

    return DocumentPanelShell(showFrame: widget.showFrame, child: content);
  }

  void _syncDraftState() {
    final hasDraft = _commentController.text.trim().isNotEmpty;
    if (hasDraft == _hasDraft) return;
    setState(() => _hasDraft = hasDraft);
  }

  void _submitComment() {
    if (!widget.actionPolicy.canCreateComments) return;

    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    widget.onAddComment(text);
    _commentController.clear();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
  }
}

class _CommentsHeader extends StatelessWidget {
  final int totalCount;
  final int openCount;
  final VoidCallback? onClose;

  const _CommentsHeader({
    required this.totalCount,
    required this.openCount,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return DocumentPanelHeader(
      icon: Icons.mode_comment_outlined,
      title: 'Comments',
      subtitle: '$openCount open, $totalCount total',
      closeTooltip: 'Close comments',
      onClose: onClose,
    );
  }
}

class _CommentComposer extends StatelessWidget {
  final TextEditingController controller;
  final bool hasDraft;
  final VoidCallback onSubmit;

  const _CommentComposer({
    required this.controller,
    required this.hasDraft,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return DocumentPanelComposerCard(
      controller: controller,
      fieldLabel: 'Add a comment',
      actionLabel: 'Comment',
      actionIcon: Icons.send_outlined,
      hasDraft: hasDraft,
      onSubmit: onSubmit,
    );
  }
}

class _CommentFilterTabs extends StatelessWidget {
  final CommentThreadFilter filter;
  final int openCount;
  final int resolvedCount;
  final ValueChanged<CommentThreadFilter> onChanged;

  const _CommentFilterTabs({
    required this.filter,
    required this.openCount,
    required this.resolvedCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DocumentPanelFilterBar<CommentThreadFilter>(
      keyPrefix: 'document-comments-filter',
      selectedValue: filter,
      options: [
        for (final option in CommentThreadFilter.values)
          DocumentPanelFilterOption(
            value: option,
            keySuffix: option.keySuffix,
            label: option.label,
            count: switch (option) {
              CommentThreadFilter.open => openCount,
              CommentThreadFilter.resolved => resolvedCount,
            },
            tooltip: option.tooltip,
          ),
      ],
      onSelected: onChanged,
    );
  }
}

class _CommentResultSummary extends StatelessWidget {
  final CommentSearchModel model;
  final int visibleCount;

  const _CommentResultSummary({
    required this.model,
    required this.visibleCount,
  });

  @override
  Widget build(BuildContext context) {
    return DocumentPanelResultSummary(
      icon: model.hasQuery
          ? Icons.manage_search_outlined
          : Icons.filter_list_outlined,
      message: _summaryMessage,
    );
  }

  String get _summaryMessage {
    final statusLabel = model.filter.label.toLowerCase();
    final commentLabel = visibleCount == 1 ? 'comment' : 'comments';
    final query = model.query.trim();
    final base = '$visibleCount $statusLabel $commentLabel';

    if (query.isEmpty) return base;
    return '$base for "$query"';
  }
}

class _CommentThreadCard extends StatelessWidget {
  final Comment comment;
  final ValueChanged<Comment> onJumpToComment;
  final ValueChanged<Comment> onResolveComment;
  final ValueChanged<Comment> onReopenComment;
  final ValueChanged<Comment> onDeleteComment;
  final DocumentReviewActionPolicy actionPolicy;

  const _CommentThreadCard({
    required this.comment,
    required this.onJumpToComment,
    required this.onResolveComment,
    required this.onReopenComment,
    required this.onDeleteComment,
    required this.actionPolicy,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DocumentPanelItemCard(
      backgroundColor: comment.resolved
          ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.30)
          : colorScheme.surface,
      borderColor: comment.resolved
          ? colorScheme.outlineVariant
          : colorScheme.primary.withValues(alpha: 0.26),
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: colorScheme.primaryContainer,
        child: Text(
          _initials(comment.author),
          style: TextStyle(
            color: colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      title: Text(
        comment.author,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        _formatTimestamp(comment.createdAt),
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
      ),
      trailing: _CommentStatusChip(resolved: comment.resolved),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (comment.anchorText != null) ...[
            _AnchorPreview(anchorText: comment.anchorText!),
            const SizedBox(height: 10),
          ],
          Text(comment.text, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
      actions: DocumentPanelActionRow(
        children: [
          OutlinedButton.icon(
            onPressed: () => onJumpToComment(comment),
            icon: const Icon(Icons.center_focus_strong_outlined, size: 17),
            label: const Text('Jump'),
          ),
          if (actionPolicy.canManageComments) ...[
            if (comment.resolved)
              OutlinedButton.icon(
                onPressed: () => onReopenComment(comment),
                icon: const Icon(Icons.undo, size: 17),
                label: const Text('Reopen'),
              )
            else
              FilledButton.tonalIcon(
                onPressed: () => onResolveComment(comment),
                icon: const Icon(Icons.check, size: 17),
                label: const Text('Resolve'),
              ),
            IconButton(
              tooltip: 'Delete comment ${comment.id}',
              onPressed: () => onDeleteComment(comment),
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ],
      ),
    );
  }

  String _initials(String author) {
    final parts = author
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'Y';
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  String _formatTimestamp(DateTime timestamp) {
    final month = timestamp.month.toString().padLeft(2, '0');
    final day = timestamp.day.toString().padLeft(2, '0');
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '${timestamp.year}-$month-$day $hour:$minute';
  }
}

class _AnchorPreview extends StatelessWidget {
  final String anchorText;

  const _AnchorPreview({required this.anchorText});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        anchorText,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CommentStatusChip extends StatelessWidget {
  final bool resolved;

  const _CommentStatusChip({required this.resolved});

  @override
  Widget build(BuildContext context) {
    return DocumentPanelStatusChip(
      label: resolved ? 'Resolved' : 'Open',
      tone: resolved
          ? DocumentPanelStatusTone.primary
          : DocumentPanelStatusTone.warning,
    );
  }
}

class _EmptyCommentState extends StatelessWidget {
  final CommentSearchModel model;

  const _EmptyCommentState({required this.model});

  @override
  Widget build(BuildContext context) {
    final isResolved = model.filter == CommentThreadFilter.resolved;
    final hasQuery = model.hasQuery;

    return DocumentPanelEmptyState(
      key: hasQuery ? CommentsPanel.filteredEmptyStateKey : null,
      icon: hasQuery
          ? Icons.manage_search_outlined
          : (isResolved ? Icons.task_alt : Icons.mode_comment_outlined),
      title: model.emptyTitle,
      message: model.emptyMessage,
    );
  }
}

extension _CommentThreadFilterPresentation on CommentThreadFilter {
  String get keySuffix {
    return switch (this) {
      CommentThreadFilter.open => 'open',
      CommentThreadFilter.resolved => 'resolved',
    };
  }

  String get label {
    return switch (this) {
      CommentThreadFilter.open => 'Open',
      CommentThreadFilter.resolved => 'Resolved',
    };
  }

  String get tooltip {
    return switch (this) {
      CommentThreadFilter.open => 'Show active comment threads',
      CommentThreadFilter.resolved => 'Show resolved comment threads',
    };
  }
}
