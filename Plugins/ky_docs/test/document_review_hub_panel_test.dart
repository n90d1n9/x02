import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/document_change.dart';
import 'package:ky_docs/docx/models/document_comment.dart';
import 'package:ky_docs/docx/models/document_editing_mode.dart';
import 'package:ky_docs/docx/services/document_statistics.dart';
import 'package:ky_docs/docx/widgets/review_hub/document_review_hub_panel.dart';
import 'package:ky_docs/docx/widgets/review_hub/document_side_panel.dart';

void main() {
  group('DocumentReviewHubPanel', () {
    testWidgets('shows active counts and switches review tabs', (tester) async {
      DocumentSidePanel? selectedPanel;

      await _pumpHub(
        tester,
        activePanel: DocumentSidePanel.review,
        onPanelChanged: (panel) => selectedPanel = panel,
      );

      expect(find.text('Review Hub'), findsOneWidget);
      expect(find.text('2 active items'), findsOneWidget);
      expect(find.text('Document quality'), findsOneWidget);

      await tester.tap(find.text('Comments'));
      await tester.pumpAndSettle();

      expect(selectedPanel, DocumentSidePanel.comments);
    });

    testWidgets('renders comments and track changes content by active tab', (
      tester,
    ) async {
      await _pumpHub(tester, activePanel: DocumentSidePanel.comments);

      expect(find.text('Clarify this paragraph.'), findsOneWidget);
      expect(find.text('Suggested text'), findsNothing);

      await _pumpHub(tester, activePanel: DocumentSidePanel.trackChanges);

      expect(find.text('Suggested text'), findsOneWidget);
      expect(find.text('rough'), findsOneWidget);
      expect(find.text('polished'), findsOneWidget);
    });

    testWidgets('locks comment and tracked-change mutations while viewing', (
      tester,
    ) async {
      await _pumpHub(
        tester,
        activePanel: DocumentSidePanel.comments,
        editingMode: DocumentEditingMode.viewing,
      );

      expect(find.text('View-only comments'), findsOneWidget);
      expect(find.text('Add a comment'), findsNothing);
      expect(find.text('Resolve'), findsNothing);
      expect(find.byTooltip('Delete comment comment-1'), findsNothing);
      expect(find.text('Jump'), findsOneWidget);

      await _pumpHub(
        tester,
        activePanel: DocumentSidePanel.trackChanges,
        editingMode: DocumentEditingMode.viewing,
      );

      expect(find.text('View-only changes'), findsOneWidget);
      expect(find.text('Suggested text'), findsNothing);
      expect(find.text('Accept'), findsNothing);
      expect(find.text('Reject'), findsNothing);
      expect(find.byTooltip('Delete tracked change change-1'), findsNothing);
      expect(find.text('Jump'), findsOneWidget);
    });
  });
}

Future<void> _pumpHub(
  WidgetTester tester, {
  required DocumentSidePanel activePanel,
  DocumentEditingMode editingMode = DocumentEditingMode.editing,
  ValueChanged<DocumentSidePanel>? onPanelChanged,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 420,
          height: 760,
          child: DocumentReviewHubPanel(
            activePanel: activePanel,
            onPanelChanged: onPanelChanged ?? (_) {},
            statistics: DocumentTextStatistics.fromText(
              'Clear draft. Good flow.',
            ),
            editingMode: editingMode,
            comments: [
              DocumentComment(
                id: 'comment-1',
                author: 'You',
                text: 'Clarify this paragraph.',
                offset: 0,
                createdAt: DateTime(2026, 1, 2),
              ),
            ],
            trackedChanges: [
              DocumentChange(
                id: 'change-1',
                userId: 'local',
                userName: 'You',
                changeType: 'replace',
                offset: 0,
                length: 5,
                originalText: 'rough',
                data: 'polished',
                timestamp: DateTime(2026, 1, 2),
              ),
            ],
            onAddComment: (_) {},
            onJumpToComment: (_) {},
            onResolveComment: (_) {},
            onReopenComment: (_) {},
            onDeleteComment: (_) {},
            onProposeChange: (_) {},
            onJumpToChange: (_) {},
            onAcceptChange: (_) {},
            onRejectChange: (_) {},
            onDeleteChange: (_) {},
          ),
        ),
      ),
    ),
  );
}
