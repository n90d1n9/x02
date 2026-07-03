import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/document_comment.dart';
import 'package:ky_docs/docx/services/document_comment_service.dart';

void main() {
  group('DocumentCommentService', () {
    final timestamp = DateTime(2026, 1, 2, 9, 30);
    final service = DocumentCommentService(now: () => timestamp);

    test('adds normalized anchored comments', () {
      final comments = service.addComment(
        currentComments: const [],
        id: 'comment-1',
        author: ' You ',
        text: '  Please clarify this section.  ',
        offset: 12,
        anchorText: '  selected   text  ',
      );

      expect(comments, hasLength(1));
      expect(comments.single.author, 'You');
      expect(comments.single.text, 'Please clarify this section.');
      expect(comments.single.offset, 12);
      expect(comments.single.anchorText, 'selected text');
      expect(comments.single.createdAt, timestamp);
      expect(comments.single.isOpen, isTrue);
    });

    test('ignores empty comment drafts', () {
      final existing = [
        DocumentComment(
          id: 'comment-1',
          author: 'You',
          text: 'Ready',
          offset: 0,
          createdAt: timestamp,
        ),
      ];

      final comments = service.addComment(
        currentComments: existing,
        id: 'comment-2',
        author: 'You',
        text: '   ',
        offset: 4,
      );

      expect(identical(comments, existing), isTrue);
    });

    test('resolves, reopens, and deletes comments immutably', () {
      final comments = [
        DocumentComment(
          id: 'comment-1',
          author: 'You',
          text: 'Ready',
          offset: 0,
          createdAt: timestamp,
        ),
      ];

      final resolved = service.resolveComment(
        currentComments: comments,
        id: 'comment-1',
      );
      final reopened = service.reopenComment(
        currentComments: resolved,
        id: 'comment-1',
      );
      final deleted = service.deleteComment(
        currentComments: reopened,
        id: 'comment-1',
      );

      expect(comments.single.resolved, isFalse);
      expect(resolved.single.resolved, isTrue);
      expect(reopened.single.resolved, isFalse);
      expect(deleted, isEmpty);
    });
  });
}
