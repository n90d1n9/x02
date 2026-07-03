import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/comment.dart';
import '../../states/provider.dart';
import '../comments/document_comments_panel.dart';

/// Toolbar button that opens the comments panel in a bottom sheet.
///
/// The badge reflects the number of **open** (unresolved) comments.
/// All panel callbacks are wired to the [documentProvider] notifier so
/// that add / resolve / reopen / delete actions are reflected in state.
class CommentsButton extends ConsumerWidget {
  const CommentsButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final openCount = ref.watch(
      documentProvider.select(
        (s) => s.comments.where((c) => c.isOpen).length,
      ),
    );

    return IconButton(
      icon: Badge(
        label: Text('$openCount'),
        isLabelVisible: openCount > 0,
        child: const Icon(Icons.comment_outlined, size: 20),
      ),
      tooltip: 'Comments',
      onPressed: () => _showCommentsPanel(context, ref),
    );
  }

  void _showCommentsPanel(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(documentProvider.notifier);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      // Let the panel occupy up to 90 % of screen height so the keyboard
      // doesn't push it off-screen when the composer is focused.
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.90,
      ),
      builder: (sheetContext) {
        // Re-watch the provider inside the sheet so the list stays live.
        return Consumer(
          builder: (context, ref, _) {
            final comments = ref.watch(
              documentProvider.select((s) => s.comments),
            );

            return CommentsPanel(
              comments: comments,
              onAddComment: notifier.addComment,
              onJumpToComment: (Comment comment) {
                // Close the panel first, then the caller can scroll to the
                // comment offset via the controller if needed.
                Navigator.of(sheetContext).pop();
              },
              onResolveComment: (Comment comment) =>
                  notifier.resolveComment(comment.id),
              onReopenComment: (Comment comment) =>
                  notifier.reopenComment(comment.id),
              onDeleteComment: (Comment comment) =>
                  notifier.deleteComment(comment.id),
              onClose: () => Navigator.of(sheetContext).pop(),
            );
          },
        );
      },
    );
  }
}
