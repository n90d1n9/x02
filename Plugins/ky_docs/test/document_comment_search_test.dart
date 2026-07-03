import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/document_comment.dart';
import 'package:ky_docs/docx/widgets/comments/document_comment_search.dart';

void main() {
  group('DocumentCommentSearchModel', () {
    test('filters comments by status, author, text, and anchor', () {
      final openComment = _comment(
        id: 'open',
        author: 'Maya',
        text: 'Please clarify the revenue note.',
        anchorText: 'Revenue plan',
      );
      final resolvedComment = _comment(
        id: 'resolved',
        author: 'Ari',
        text: 'Resolved wording detail.',
        anchorText: 'Executive summary',
        resolved: true,
      );

      final model = DocumentCommentSearchModel(
        comments: [openComment, resolvedComment],
        query: 'revenue',
        filter: DocumentCommentThreadFilter.open,
      );

      expect(model.hasQuery, isTrue);
      expect(model.visibleComments, [openComment]);
      expect(model.countFor(DocumentCommentThreadFilter.open), 1);
      expect(model.countFor(DocumentCommentThreadFilter.resolved), 0);
    });

    test('describes empty states for search and status filters', () {
      final searchModel = DocumentCommentSearchModel(
        comments: [_comment(id: 'open')],
        query: 'missing',
        filter: DocumentCommentThreadFilter.open,
      );
      const resolvedModel = DocumentCommentSearchModel(
        comments: [],
        query: '',
        filter: DocumentCommentThreadFilter.resolved,
      );

      expect(searchModel.visibleComments, isEmpty);
      expect(searchModel.emptyTitle, 'No matching comments');
      expect(
        searchModel.emptyMessage,
        'Try another author, phrase, or anchor text.',
      );
      expect(resolvedModel.emptyTitle, 'No resolved comments');
      expect(resolvedModel.emptyMessage, 'Resolved threads will appear here.');
    });
  });
}

DocumentComment _comment({
  required String id,
  String author = 'You',
  String text = 'Comment text',
  String? anchorText,
  bool resolved = false,
}) {
  return DocumentComment(
    id: id,
    author: author,
    text: text,
    offset: 10,
    anchorText: anchorText,
    createdAt: DateTime(2026, 1, 2, 9, 30),
    resolved: resolved,
  );
}
