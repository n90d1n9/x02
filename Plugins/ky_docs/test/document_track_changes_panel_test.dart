import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/document_change.dart';
import 'package:ky_docs/docx/models/document_editing_mode.dart';
import 'package:ky_docs/docx/widgets/review_hub/document_review_action_policy.dart';
import 'package:ky_docs/docx/widgets/track_changes/document_track_changes_panel.dart';

void main() {
  group('DocumentTrackChangesPanel', () {
    testWidgets('renders empty state and submits a suggestion', (tester) async {
      String? suggestedText;

      await _pumpPanel(
        tester,
        changes: const [],
        onProposeChange: (text) => suggestedText = text,
      );

      expect(find.text('Track Changes'), findsOneWidget);
      expect(find.text('No pending changes'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Use clearer wording.');
      await tester.pump();
      await tester.tap(find.text('Suggest'));

      expect(suggestedText, 'Use clearer wording.');
    });

    testWidgets('routes jump, accept, reject, and delete actions', (
      tester,
    ) async {
      DocumentChange? jumpedChange;
      DocumentChange? acceptedChange;
      DocumentChange? rejectedChange;
      DocumentChange? deletedChange;
      final pendingChange = DocumentChange(
        id: 'change-1',
        userId: 'local',
        userName: 'You',
        changeType: 'replace',
        offset: 6,
        length: 5,
        originalText: 'rough',
        data: 'polished',
        timestamp: DateTime(2026, 1, 2, 9, 30),
      );
      final rejectedChangeFixture = DocumentChange(
        id: 'change-2',
        userId: 'editor',
        userName: 'Maya',
        changeType: 'insert',
        offset: 12,
        length: 0,
        data: 'extra context',
        timestamp: DateTime(2026, 1, 3, 10, 15),
        status: DocumentChangeStatus.rejected,
      );

      await _pumpPanel(
        tester,
        changes: [pendingChange, rejectedChangeFixture],
        onJumpToChange: (change) => jumpedChange = change,
        onAcceptChange: (change) => acceptedChange = change,
        onRejectChange: (change) => rejectedChange = change,
        onDeleteChange: (change) => deletedChange = change,
      );

      expect(find.text('1 pending, 2 total'), findsOneWidget);
      expect(find.text('1 pending change'), findsOneWidget);
      expect(find.text('Replacement suggestion'), findsOneWidget);
      expect(find.text('rough'), findsOneWidget);
      expect(find.text('polished'), findsOneWidget);

      await tester.tap(find.text('Jump'));
      await tester.tap(find.text('Accept'));
      await tester.ensureVisible(find.text('Reject'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reject'));

      expect(jumpedChange, same(pendingChange));
      expect(acceptedChange, same(pendingChange));
      expect(rejectedChange, same(pendingChange));

      await tester.tap(find.text('Resolved 1'));
      await tester.pumpAndSettle();

      expect(find.text('Insert suggestion'), findsOneWidget);
      expect(find.text('Rejected'), findsOneWidget);
      expect(find.text('1 resolved change'), findsOneWidget);

      await tester.tap(find.byTooltip('Delete tracked change change-2'));

      expect(deletedChange, same(rejectedChangeFixture));
    });

    testWidgets('keeps changes navigable but locked while viewing', (
      tester,
    ) async {
      DocumentChange? jumpedChange;
      DocumentChange? acceptedChange;
      DocumentChange? deletedChange;
      final change = DocumentChange(
        id: 'change-1',
        userId: 'local',
        userName: 'You',
        changeType: 'replace',
        offset: 6,
        length: 5,
        originalText: 'rough',
        data: 'polished',
        timestamp: DateTime(2026, 1, 2, 9, 30),
      );

      await _pumpPanel(
        tester,
        changes: [change],
        actionPolicy: const DocumentReviewActionPolicy(
          editingMode: DocumentEditingMode.viewing,
        ),
        onJumpToChange: (value) => jumpedChange = value,
        onAcceptChange: (value) => acceptedChange = value,
        onDeleteChange: (value) => deletedChange = value,
      );

      expect(find.text('View-only changes'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Accept'), findsNothing);
      expect(find.text('Reject'), findsNothing);
      expect(find.byTooltip('Delete tracked change change-1'), findsNothing);

      await tester.tap(find.text('Jump'));

      expect(jumpedChange, same(change));
      expect(acceptedChange, isNull);
      expect(deletedChange, isNull);
    });
  });
}

Future<void> _pumpPanel(
  WidgetTester tester, {
  required List<DocumentChange> changes,
  ValueChanged<String>? onProposeChange,
  ValueChanged<DocumentChange>? onJumpToChange,
  ValueChanged<DocumentChange>? onAcceptChange,
  ValueChanged<DocumentChange>? onRejectChange,
  ValueChanged<DocumentChange>? onDeleteChange,
  DocumentReviewActionPolicy actionPolicy = DocumentReviewActionPolicy.editing,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          height: 760,
          child: DocumentTrackChangesPanel(
            changes: changes,
            onProposeChange: onProposeChange ?? (_) {},
            onJumpToChange: onJumpToChange ?? (_) {},
            onAcceptChange: onAcceptChange ?? (_) {},
            onRejectChange: onRejectChange ?? (_) {},
            onDeleteChange: onDeleteChange ?? (_) {},
            actionPolicy: actionPolicy,
          ),
        ),
      ),
    ),
  );
}
