import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/document_editing_mode.dart';
import 'package:ky_docs/docx/widgets/review_mode/document_editing_mode_status_details.dart';
import 'package:ky_docs/docx/widgets/review_mode/document_editing_mode_status_chip.dart';

void main() {
  group('DocumentEditingModeStatusDetails', () {
    test('summarizes mode rules for compact status chrome', () {
      final editing = DocumentEditingModeStatusDetails(
        DocumentEditingMode.editing,
      );
      final viewing = DocumentEditingModeStatusDetails(
        DocumentEditingMode.viewing,
      );

      expect(editing.editingAccessLabel, 'Direct edits');
      expect(editing.toolbarLabel, 'Available');
      expect(editing.workspaceBannerLabel, 'Hidden');
      expect(editing.readOnlyLabel, 'Off');
      expect(viewing.editingAccessLabel, 'Locked');
      expect(viewing.toolbarLabel, 'Hidden');
      expect(viewing.workspaceBannerLabel, 'Visible');
      expect(viewing.readOnlyLabel, 'On');
    });
  });

  group('DocumentEditingModeStatusChip', () {
    testWidgets('renders the active review mode as status chrome', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: DocumentEditingModeStatusChip(
                mode: DocumentEditingMode.suggesting,
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(DocumentEditingModeStatusChip.chipKey), findsOneWidget);
      expect(find.text('Suggesting'), findsOneWidget);
      expect(
        find.byTooltip(DocumentEditingMode.suggesting.description),
        findsOneWidget,
      );
    });

    testWidgets('opens editing mode details popover', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: DocumentEditingModeStatusChip(
                mode: DocumentEditingMode.viewing,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(DocumentEditingModeStatusChip.chipKey));
      await tester.pumpAndSettle();

      expect(find.byKey(DocumentEditingModeStatusChip.menuKey), findsOneWidget);
      expect(find.text('Editing mode'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(DocumentEditingModeStatusChip.menuKey),
          matching: find.text('Viewing'),
        ),
        findsOneWidget,
      );
      expect(find.text('Document changes'), findsOneWidget);
      expect(find.text('Locked'), findsOneWidget);
      expect(find.text('Formatting toolbar'), findsOneWidget);
      expect(find.text('Hidden'), findsOneWidget);
      expect(find.text('Read only'), findsOneWidget);
      expect(find.text('On'), findsOneWidget);
    });

    testWidgets('routes optional mode action from the popover', (tester) async {
      var actionInvoked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: DocumentEditingModeStatusChip(
                mode: DocumentEditingMode.suggesting,
                onPressed: () => actionInvoked = true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(DocumentEditingModeStatusChip.chipKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(DocumentEditingModeStatusChip.actionKey));
      await tester.pumpAndSettle();

      expect(actionInvoked, isTrue);
    });
  });
}
