import 'package:flutter/material.dart';

import '../../models/document_change.dart';
import '../panel/document_panel_action_row.dart';
import '../panel/document_panel_composer_card.dart';
import '../panel/document_panel_empty_state.dart';
import '../panel/document_panel_filter_bar.dart';
import '../panel/document_panel_header.dart';
import '../panel/document_panel_item_card.dart';
import '../panel/document_panel_result_summary.dart';
import '../panel/document_panel_shell.dart';
import '../panel/document_panel_status_chip.dart';
import '../review_hub/document_review_action_policy.dart';
import '../review_hub/document_review_locked_notice.dart';

/// Displays document edit suggestions with accept, reject, and jump actions.
class DocumentTrackChangesPanel extends StatefulWidget {
  final List<DocumentChange> changes;
  final ValueChanged<String> onProposeChange;
  final ValueChanged<DocumentChange> onJumpToChange;
  final ValueChanged<DocumentChange> onAcceptChange;
  final ValueChanged<DocumentChange> onRejectChange;
  final ValueChanged<DocumentChange> onDeleteChange;
  final VoidCallback? onClose;
  final DocumentReviewActionPolicy actionPolicy;
  final bool showHeader;
  final bool showFrame;

  const DocumentTrackChangesPanel({
    super.key,
    required this.changes,
    required this.onProposeChange,
    required this.onJumpToChange,
    required this.onAcceptChange,
    required this.onRejectChange,
    required this.onDeleteChange,
    this.onClose,
    this.actionPolicy = DocumentReviewActionPolicy.editing,
    this.showHeader = true,
    this.showFrame = true,
  });

  @override
  State<DocumentTrackChangesPanel> createState() =>
      _DocumentTrackChangesPanelState();
}

class _DocumentTrackChangesPanelState extends State<DocumentTrackChangesPanel> {
  final _replacementController = TextEditingController();
  var _filter = _TrackChangesFilter.pending;
  var _hasDraft = false;

  @override
  void initState() {
    super.initState();
    _replacementController.addListener(_syncDraftState);
  }

  @override
  void dispose() {
    _replacementController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = widget.changes
        .where((change) => change.isPending)
        .length;
    final resolvedCount = widget.changes.length - pendingCount;
    final visibleChanges = _visibleChanges;

    final content = Column(
      children: [
        if (widget.showHeader)
          _TrackChangesHeader(
            totalCount: widget.changes.length,
            pendingCount: pendingCount,
            onClose: widget.onClose,
          ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
            children: [
              if (widget.actionPolicy.showsLockedNotice)
                DocumentReviewLockedNotice(
                  title: 'View-only changes',
                  message: widget.actionPolicy.lockedReviewReason,
                )
              else
                _SuggestionComposer(
                  controller: _replacementController,
                  hasDraft: _hasDraft,
                  onSubmit: _submitSuggestion,
                ),
              const SizedBox(height: 14),
              _TrackChangesFilterTabs(
                filter: _filter,
                pendingCount: pendingCount,
                resolvedCount: resolvedCount,
                onChanged: (filter) => setState(() => _filter = filter),
              ),
              if (widget.changes.isNotEmpty) ...[
                const SizedBox(height: 10),
                _TrackChangesResultSummary(
                  filter: _filter,
                  visibleCount: visibleChanges.length,
                ),
              ],
              const SizedBox(height: 14),
              if (visibleChanges.isEmpty)
                _EmptyTrackChangesState(filter: _filter)
              else
                for (final change in visibleChanges) ...[
                  _TrackedChangeCard(
                    change: change,
                    onJumpToChange: widget.onJumpToChange,
                    onAcceptChange: widget.onAcceptChange,
                    onRejectChange: widget.onRejectChange,
                    onDeleteChange: widget.onDeleteChange,
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

  List<DocumentChange> get _visibleChanges {
    return widget.changes.where((change) {
      return switch (_filter) {
        _TrackChangesFilter.pending => change.isPending,
        _TrackChangesFilter.resolved => change.isResolved,
      };
    }).toList();
  }

  void _syncDraftState() {
    final hasDraft = _replacementController.text.trim().isNotEmpty;
    if (hasDraft == _hasDraft) return;
    setState(() => _hasDraft = hasDraft);
  }

  void _submitSuggestion() {
    if (!widget.actionPolicy.canProposeChanges) return;

    final text = _replacementController.text.trim();
    if (text.isEmpty) return;

    widget.onProposeChange(text);
    _replacementController.clear();
  }
}

class _TrackChangesHeader extends StatelessWidget {
  final int totalCount;
  final int pendingCount;
  final VoidCallback? onClose;

  const _TrackChangesHeader({
    required this.totalCount,
    required this.pendingCount,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return DocumentPanelHeader(
      icon: Icons.rule_folder_outlined,
      title: 'Track Changes',
      subtitle: '$pendingCount pending, $totalCount total',
      closeTooltip: 'Close track changes',
      onClose: onClose,
    );
  }
}

class _SuggestionComposer extends StatelessWidget {
  final TextEditingController controller;
  final bool hasDraft;
  final VoidCallback onSubmit;

  const _SuggestionComposer({
    required this.controller,
    required this.hasDraft,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return DocumentPanelComposerCard(
      controller: controller,
      fieldLabel: 'Suggested text',
      actionLabel: 'Suggest',
      actionIcon: Icons.add_task_outlined,
      hasDraft: hasDraft,
      onSubmit: onSubmit,
    );
  }
}

class _TrackChangesFilterTabs extends StatelessWidget {
  final _TrackChangesFilter filter;
  final int pendingCount;
  final int resolvedCount;
  final ValueChanged<_TrackChangesFilter> onChanged;

  const _TrackChangesFilterTabs({
    required this.filter,
    required this.pendingCount,
    required this.resolvedCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DocumentPanelFilterBar<_TrackChangesFilter>(
      keyPrefix: 'track-changes-filter',
      selectedValue: filter,
      options: [
        for (final option in _TrackChangesFilter.values)
          DocumentPanelFilterOption(
            value: option,
            keySuffix: option.keySuffix,
            label: option.label,
            count: switch (option) {
              _TrackChangesFilter.pending => pendingCount,
              _TrackChangesFilter.resolved => resolvedCount,
            },
            tooltip: option.tooltip,
          ),
      ],
      onSelected: onChanged,
    );
  }
}

class _TrackChangesResultSummary extends StatelessWidget {
  final _TrackChangesFilter filter;
  final int visibleCount;

  const _TrackChangesResultSummary({
    required this.filter,
    required this.visibleCount,
  });

  @override
  Widget build(BuildContext context) {
    return DocumentPanelResultSummary(
      icon: Icons.filter_list_outlined,
      message: _summaryMessage,
    );
  }

  String get _summaryMessage {
    final label = filter.label.toLowerCase();
    final changeLabel = visibleCount == 1 ? 'change' : 'changes';
    return '$visibleCount $label $changeLabel';
  }
}

class _TrackedChangeCard extends StatelessWidget {
  final DocumentChange change;
  final ValueChanged<DocumentChange> onJumpToChange;
  final ValueChanged<DocumentChange> onAcceptChange;
  final ValueChanged<DocumentChange> onRejectChange;
  final ValueChanged<DocumentChange> onDeleteChange;
  final DocumentReviewActionPolicy actionPolicy;

  const _TrackedChangeCard({
    required this.change,
    required this.onJumpToChange,
    required this.onAcceptChange,
    required this.onRejectChange,
    required this.onDeleteChange,
    required this.actionPolicy,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isPending = change.isPending;

    return DocumentPanelItemCard(
      backgroundColor: isPending
          ? colorScheme.surface
          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.30),
      borderColor: isPending
          ? colorScheme.primary.withValues(alpha: 0.26)
          : colorScheme.outlineVariant,
      leading: Icon(
        _iconForChange(change),
        size: 19,
        color: colorScheme.primary,
      ),
      title: Text(
        _titleForChange(change),
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        '${change.userName} - ${_formatTimestamp(change.timestamp)}',
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
      ),
      trailing: _ChangeStatusChip(status: change.status),
      body: _ChangePreview(change: change),
      actions: _TrackedChangeActions(
        change: change,
        actionPolicy: actionPolicy,
        onJumpToChange: onJumpToChange,
        onAcceptChange: onAcceptChange,
        onRejectChange: onRejectChange,
        onDeleteChange: onDeleteChange,
      ),
    );
  }

  IconData _iconForChange(DocumentChange change) {
    if (change.isInsertion) return Icons.add_circle_outline;
    return Icons.compare_arrows_outlined;
  }

  String _titleForChange(DocumentChange change) {
    if (change.isInsertion) return 'Insert suggestion';
    return 'Replacement suggestion';
  }

  String _formatTimestamp(DateTime timestamp) {
    final month = timestamp.month.toString().padLeft(2, '0');
    final day = timestamp.day.toString().padLeft(2, '0');
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '${timestamp.year}-$month-$day $hour:$minute';
  }
}

/// Renders the action controls available for a single tracked change.
class _TrackedChangeActions extends StatelessWidget {
  final DocumentChange change;
  final ValueChanged<DocumentChange> onJumpToChange;
  final ValueChanged<DocumentChange> onAcceptChange;
  final ValueChanged<DocumentChange> onRejectChange;
  final ValueChanged<DocumentChange> onDeleteChange;
  final DocumentReviewActionPolicy actionPolicy;

  const _TrackedChangeActions({
    required this.change,
    required this.onJumpToChange,
    required this.onAcceptChange,
    required this.onRejectChange,
    required this.onDeleteChange,
    required this.actionPolicy,
  });

  @override
  Widget build(BuildContext context) {
    return DocumentPanelActionRow(
      children: [
        OutlinedButton.icon(
          onPressed: () => onJumpToChange(change),
          icon: const Icon(Icons.center_focus_strong_outlined, size: 17),
          label: const Text('Jump'),
        ),
        if (change.isPending && actionPolicy.canManageTrackedChanges) ...[
          FilledButton.tonalIcon(
            onPressed: () => onAcceptChange(change),
            icon: const Icon(Icons.check, size: 17),
            label: const Text('Accept'),
          ),
          OutlinedButton.icon(
            onPressed: () => onRejectChange(change),
            icon: const Icon(Icons.close, size: 17),
            label: const Text('Reject'),
          ),
        ],
        if (actionPolicy.canManageTrackedChanges)
          IconButton(
            tooltip: 'Delete tracked change ${change.id}',
            onPressed: () => onDeleteChange(change),
            icon: const Icon(Icons.delete_outline),
          ),
      ],
    );
  }
}

class _ChangePreview extends StatelessWidget {
  final DocumentChange change;

  const _ChangePreview({required this.change});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (change.originalText != null) ...[
          _PreviewLabel(label: 'Original'),
          const SizedBox(height: 4),
          _PreviewBox(
            text: change.originalText!,
            color: colorScheme.error,
            decoration: TextDecoration.lineThrough,
          ),
          const SizedBox(height: 8),
        ],
        _PreviewLabel(label: 'Suggested'),
        const SizedBox(height: 4),
        _PreviewBox(text: change.replacementText, color: colorScheme.primary),
      ],
    );
  }
}

class _PreviewLabel extends StatelessWidget {
  final String label;

  const _PreviewLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _PreviewBox extends StatelessWidget {
  final String text;
  final Color color;
  final TextDecoration? decoration;

  const _PreviewBox({required this.text, required this.color, this.decoration});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        text,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          decoration: decoration,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ChangeStatusChip extends StatelessWidget {
  final DocumentChangeStatus status;

  const _ChangeStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return DocumentPanelStatusChip(
      label: _statusLabel(status),
      tone: _statusTone(status),
    );
  }

  String _statusLabel(DocumentChangeStatus status) {
    return switch (status) {
      DocumentChangeStatus.pending => 'Pending',
      DocumentChangeStatus.accepted => 'Accepted',
      DocumentChangeStatus.rejected => 'Rejected',
    };
  }

  DocumentPanelStatusTone _statusTone(DocumentChangeStatus status) {
    return switch (status) {
      DocumentChangeStatus.pending => DocumentPanelStatusTone.warning,
      DocumentChangeStatus.accepted => DocumentPanelStatusTone.primary,
      DocumentChangeStatus.rejected => DocumentPanelStatusTone.danger,
    };
  }
}

class _EmptyTrackChangesState extends StatelessWidget {
  final _TrackChangesFilter filter;

  const _EmptyTrackChangesState({required this.filter});

  @override
  Widget build(BuildContext context) {
    return DocumentPanelEmptyState(
      icon: filter.emptyIcon,
      title: filter.emptyTitle,
      message: filter.emptyMessage,
    );
  }
}

enum _TrackChangesFilter { pending, resolved }

extension _TrackChangesFilterPresentation on _TrackChangesFilter {
  String get keySuffix {
    return switch (this) {
      _TrackChangesFilter.pending => 'pending',
      _TrackChangesFilter.resolved => 'resolved',
    };
  }

  String get label {
    return switch (this) {
      _TrackChangesFilter.pending => 'Pending',
      _TrackChangesFilter.resolved => 'Resolved',
    };
  }

  String get tooltip {
    return switch (this) {
      _TrackChangesFilter.pending => 'Show suggestions waiting for review',
      _TrackChangesFilter.resolved => 'Show accepted and rejected suggestions',
    };
  }

  IconData get emptyIcon {
    return switch (this) {
      _TrackChangesFilter.pending => Icons.rule_folder_outlined,
      _TrackChangesFilter.resolved => Icons.done_all,
    };
  }

  String get emptyTitle {
    return switch (this) {
      _TrackChangesFilter.pending => 'No pending changes',
      _TrackChangesFilter.resolved => 'No resolved changes',
    };
  }

  String get emptyMessage {
    return switch (this) {
      _TrackChangesFilter.pending =>
        'Suggest a replacement or insertion from the editor.',
      _TrackChangesFilter.resolved =>
        'Accepted and rejected suggestions will appear here.',
    };
  }
}
