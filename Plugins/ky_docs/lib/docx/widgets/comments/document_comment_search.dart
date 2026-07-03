import '../../models/comment.dart';

/// Describes the thread status filter used by the comments panel.
enum CommentThreadFilter {
  open,
  resolved;

  bool accepts(Comment comment) {
    return switch (this) {
      CommentThreadFilter.open => comment.isOpen,
      CommentThreadFilter.resolved => comment.resolved,
    };
  }
}

/// Builds searchable comment thread data for the comments panel.
class CommentSearchModel {
  final List<Comment> comments;
  final String query;
  final CommentThreadFilter filter;

  const CommentSearchModel({
    required this.comments,
    required this.query,
    required this.filter,
  });

  bool get hasQuery => query.trim().isNotEmpty;

  List<Comment> get visibleComments {
    return comments
        .where(filter.accepts)
        .where(_matchesQuery)
        .toList(growable: false);
  }

  int countFor(CommentThreadFilter threadFilter) {
    return comments.where(threadFilter.accepts).where(_matchesQuery).length;
  }

  String get emptyTitle {
    if (hasQuery) return 'No matching comments';
    return switch (filter) {
      CommentThreadFilter.open => 'No open comments',
      CommentThreadFilter.resolved => 'No resolved comments',
    };
  }

  String get emptyMessage {
    if (hasQuery) return 'Try another author, phrase, or anchor text.';
    return switch (filter) {
      CommentThreadFilter.open => 'Add a comment to start a discussion.',
      CommentThreadFilter.resolved => 'Resolved threads will appear here.',
    };
  }

  bool _matchesQuery(Comment comment) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return true;

    final searchableText = [
      comment.author,
      comment.text,
      ?comment.anchorText,
    ].join(' ').toLowerCase();

    return searchableText.contains(normalizedQuery);
  }
}
