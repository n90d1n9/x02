import '../models/comment.dart';

typedef CommentClock = DateTime Function();

/// Manages immutable document comment thread updates.
class CommentService {
  final CommentClock now;

  const CommentService({this.now = DateTime.now});

  List<Comment> addComment({
    required List<Comment> currentComments,
    required String id,
    required String author,
    required String text,
    required int offset,
    String? anchorText,
    DateTime? createdAt,
  }) {
    final normalizedText = text.trim();
    if (normalizedText.isEmpty) return currentComments;

    return [
      ...currentComments,
      Comment(
        id: id,
        author: _normalizeAuthor(author),
        text: normalizedText,
        offset: offset < 0 ? 0 : offset,
        anchorText: _normalizeAnchor(anchorText),
        createdAt: createdAt ?? now(),
      ),
    ];
  }

  List<Comment> resolveComment({
    required List<Comment> currentComments,
    required String id,
  }) {
    return _setResolved(
      currentComments: currentComments,
      id: id,
      resolved: true,
    );
  }

  List<Comment> reopenComment({
    required List<Comment> currentComments,
    required String id,
  }) {
    return _setResolved(
      currentComments: currentComments,
      id: id,
      resolved: false,
    );
  }

  List<Comment> deleteComment({
    required List<Comment> currentComments,
    required String id,
  }) {
    return currentComments.where((comment) => comment.id != id).toList();
  }

  List<Comment> _setResolved({
    required List<Comment> currentComments,
    required String id,
    required bool resolved,
  }) {
    return currentComments.map((comment) {
      if (comment.id != id) return comment;
      return comment.copyWith(resolved: resolved);
    }).toList();
  }

  String _normalizeAuthor(String author) {
    final normalizedAuthor = author.trim();
    if (normalizedAuthor.isEmpty) return 'You';
    return normalizedAuthor;
  }

  String? _normalizeAnchor(String? anchorText) {
    final normalizedAnchor = anchorText?.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalizedAnchor == null || normalizedAnchor.isEmpty) return null;
    return normalizedAnchor;
  }
}
