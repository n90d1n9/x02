import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/widgets/panel/document_panel_status_chip.dart';

void main() {
  group('DocumentPanelStatusChip', () {
    testWidgets('renders a labeled status chip', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DocumentPanelStatusChip(
              label: 'Pending',
              tone: DocumentPanelStatusTone.warning,
            ),
          ),
        ),
      );

      expect(find.text('Pending'), findsOneWidget);
    });

    testWidgets('wraps status chip with tooltip when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DocumentPanelStatusChip(
              label: 'Rejected',
              tone: DocumentPanelStatusTone.danger,
              tooltip: 'Suggestion rejected',
            ),
          ),
        ),
      );

      expect(find.text('Rejected'), findsOneWidget);
      expect(find.byTooltip('Suggestion rejected'), findsOneWidget);
    });
  });
}
