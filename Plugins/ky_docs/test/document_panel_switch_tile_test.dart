import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/widgets/panel/document_panel_switch_tile.dart';

void main() {
  group('DocumentPanelSwitchTile', () {
    testWidgets('renders icon, title, subtitle, and routes changes', (
      tester,
    ) async {
      var enabled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return DocumentPanelSwitchTile(
                  icon: Icons.pin_outlined,
                  title: 'Page numbers',
                  subtitle: 'Show page numbers on export.',
                  value: enabled,
                  onChanged: (value) => setState(() => enabled = value),
                );
              },
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.pin_outlined), findsOneWidget);
      expect(find.text('Page numbers'), findsOneWidget);
      expect(find.text('Show page numbers on export.'), findsOneWidget);

      await tester.tap(find.text('Page numbers'));
      await tester.pump();

      expect(enabled, isTrue);
    });

    testWidgets('omits subtitle when not provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentPanelSwitchTile(
              title: 'Include Metadata',
              value: true,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Include Metadata'), findsOneWidget);
      expect(find.byType(Icon), findsNothing);
    });
  });
}
