import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/widgets/status_bar/document_status_chip.dart';

void main() {
  group('DocumentStatusChip', () {
    testWidgets('renders metric label and invokes actions', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: DocumentStatusChip(
                icon: Icons.schedule_outlined,
                label: '3 min read',
                tooltip: 'Estimated reading time',
                onPressed: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('3 min read'), findsOneWidget);

      await tester.tap(find.text('3 min read'));

      expect(tapped, isTrue);
    });
  });

  group('DocumentSaveStatusBadge', () {
    testWidgets('renders saved and unsaved states', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                DocumentSaveStatusBadge(hasUnsavedChanges: false),
                DocumentSaveStatusBadge(hasUnsavedChanges: true),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Saved'), findsOneWidget);
      expect(find.text('Unsaved'), findsOneWidget);
    });
  });
}
