import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/document_comment.dart';
import 'package:ky_docs/docx/models/document_editing_mode.dart';
import 'package:ky_docs/docx/widgets/comments/document_comments_panel.dart';
import 'package:ky_docs/docx/widgets/review_hub/document_review_action_policy.dart';

void main() {
  group('DocumentCommentsPanel', () {
    testWidgets('renders empty state and submits a new comment', (
      tester,
    ) async {
      String? addedComment;

      await _pumpPanel(
        tester,
        comments: const [],
        onAddComment: (text) => addedComment = text,
      );

      expect(find.text('Comments'), findsOneWidget);
      expect(find.text('No open comments'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, 'Add a comment'),
        'Please clarify this.',
      );
      await tester.pump();
      await tester.tap(find.text('Comment'));

      expect(addedComment, 'Please clarify this.');
    });

    testWidgets('routes jump, resolve, reopen, and delete actions', (
      tester,
    ) async {
      DocumentComment? jumpedComment;
      DocumentComment? resolvedComment;
      DocumentComment? reopenedComment;
      DocumentComment? deletedComment;
      final openComment = DocumentComment(
        id: 'comment-1',
        author: 'You',
        text: 'Tighten this paragraph.',
        offset: 8,
        anchorText: 'First paragraph',
        createdAt: DateTime(2026, 1, 2, 9, 30),
      );
      final resolvedCommentFixture = DocumentComment(
        id: 'comment-2',
        author: 'Maya',
        text: 'Resolved wording note.',
        offset: 20,
        createdAt: DateTime(2026, 1, 3, 10, 15),
        resolved: true,
      );

      await _pumpPanel(
        tester,
        comments: [openComment, resolvedCommentFixture],
        onJumpToComment: (comment) => jumpedComment = comment,
        onResolveComment: (comment) => resolvedComment = comment,
        onReopenComment: (comment) => reopenedComment = comment,
        onDeleteComment: (comment) => deletedComment = comment,
      );

      expect(find.text('1 open, 2 total'), findsOneWidget);
      expect(find.text('Tighten this paragraph.'), findsOneWidget);
      expect(find.text('First paragraph'), findsOneWidget);

      await tester.tap(find.text('Jump'));
      await tester.tap(find.text('Resolve'));

      expect(jumpedComment, same(openComment));
      expect(resolvedComment, same(openComment));

      await tester.tap(find.text('Resolved 1'));
      await tester.pumpAndSettle();

      expect(find.text('Resolved wording note.'), findsOneWidget);

      await tester.tap(find.text('Reopen'));
      await tester.tap(find.byTooltip('Delete comment comment-2'));

      expect(reopenedComment, same(resolvedCommentFixture));
      expect(deletedComment, same(resolvedCommentFixture));
    });

    testWidgets('keeps comments navigable but locked while viewing', (
      tester,
    ) async {
      DocumentComment? jumpedComment;
      DocumentComment? resolvedComment;
      DocumentComment? deletedComment;
      final comment = DocumentComment(
        id: 'comment-1',
        author: 'You',
        text: 'Read this note.',
        offset: 8,
        createdAt: DateTime(2026, 1, 2, 9, 30),
      );

      await _pumpPanel(
        tester,
        comments: [comment],
        actionPolicy: const DocumentReviewActionPolicy(
          editingMode: DocumentEditingMode.viewing,
        ),
        onJumpToComment: (value) => jumpedComment = value,
        onResolveComment: (value) => resolvedComment = value,
        onDeleteComment: (value) => deletedComment = value,
      );

      expect(find.text('View-only comments'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Add a comment'), findsNothing);
      expect(find.byKey(DocumentCommentsPanel.searchFieldKey), findsOneWidget);
      expect(find.text('Resolve'), findsNothing);
      expect(find.byTooltip('Delete comment comment-1'), findsNothing);

      await tester.tap(find.text('Jump'));

      expect(jumpedComment, same(comment));
      expect(resolvedComment, isNull);
      expect(deletedComment, isNull);
    });

    testWidgets('searches comments within the selected status filter', (
      tester,
    ) async {
      final openComment = DocumentComment(
        id: 'comment-1',
        author: 'Maya',
        text: 'Clarify the revenue note.',
        offset: 8,
        anchorText: 'Revenue plan',
        createdAt: DateTime(2026, 1, 2, 9, 30),
      );
      final resolvedComment = DocumentComment(
        id: 'comment-2',
        author: 'Ari',
        text: 'Resolved appendix note.',
        offset: 20,
        createdAt: DateTime(2026, 1, 3, 10, 15),
        resolved: true,
      );

      await _pumpPanel(tester, comments: [openComment, resolvedComment]);

      await tester.enterText(
        find.byKey(DocumentCommentsPanel.searchFieldKey),
        'revenue',
      );
      await tester.pumpAndSettle();

      expect(find.text('Open 1'), findsOneWidget);
      expect(find.text('Resolved 0'), findsOneWidget);
      expect(find.text('1 open comment for "revenue"'), findsOneWidget);
      expect(find.text('Clarify the revenue note.'), findsOneWidget);
      expect(find.text('Resolved appendix note.'), findsNothing);

      await tester.enterText(
        find.byKey(DocumentCommentsPanel.searchFieldKey),
        'appendix',
      );
      await tester.pumpAndSettle();

      expect(find.text('Open 0'), findsOneWidget);
      expect(find.text('Resolved 1'), findsOneWidget);
      expect(find.text('0 open comments for "appendix"'), findsOneWidget);
      expect(
        find.byKey(DocumentCommentsPanel.filteredEmptyStateKey),
        findsOneWidget,
      );
      expect(find.text('No matching comments'), findsOneWidget);

      await tester.tap(find.text('Resolved 1'));
      await tester.pumpAndSettle();

      expect(find.text('1 resolved comment for "appendix"'), findsOneWidget);
      expect(find.text('Resolved appendix note.'), findsOneWidget);
    });

    testWidgets('clears comment search text', (tester) async {
      final comment = DocumentComment(
        id: 'comment-1',
        author: 'Maya',
        text: 'Clarify this paragraph.',
        offset: 8,
        createdAt: DateTime(2026, 1, 2, 9, 30),
      );

      await _pumpPanel(tester, comments: [comment]);

      await tester.enterText(
        find.byKey(DocumentCommentsPanel.searchFieldKey),
        'missing',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(DocumentCommentsPanel.clearSearchButtonKey));
      await tester.pumpAndSettle();

      expect(find.text('Clarify this paragraph.'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(DocumentCommentsPanel.searchFieldKey))
            .controller
            ?.text,
        isEmpty,
      );
    });
  });
}

Future<void> _pumpPanel(
  WidgetTester tester, {
  required List<DocumentComment> comments,
  ValueChanged<String>? onAddComment,
  ValueChanged<DocumentComment>? onJumpToComment,
  ValueChanged<DocumentComment>? onResolveComment,
  ValueChanged<DocumentComment>? onReopenComment,
  ValueChanged<DocumentComment>? onDeleteComment,
  DocumentReviewActionPolicy actionPolicy = DocumentReviewActionPolicy.editing,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 380,
          height: 720,
          child: DocumentCommentsPanel(
            comments: comments,
            onAddComment: onAddComment ?? (_) {},
            onJumpToComment: onJumpToComment ?? (_) {},
            onResolveComment: onResolveComment ?? (_) {},
            onReopenComment: onReopenComment ?? (_) {},
            onDeleteComment: onDeleteComment ?? (_) {},
            actionPolicy: actionPolicy,
          ),
        ),
      ),
    ),
  );
}
