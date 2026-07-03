import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/widgets/panel/document_panel_item_card.dart';

void main() {
  group('DocumentPanelItemCard', () {
    testWidgets('renders leading, content, trailing, body, and actions', (
      tester,
    ) async {
      var actionPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentPanelItemCard(
              leading: const DocumentPanelNumberBadge(label: '1'),
              title: const Text('Source citation'),
              subtitle: const Text('Anchor position 12'),
              trailing: const Icon(Icons.edit_outlined),
              body: const Text('Replacement suggestions'),
              backgroundColor: Colors.amber,
              borderColor: Colors.orange,
              actions: FilledButton(
                onPressed: () => actionPressed = true,
                child: const Text('Apply'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('1'), findsOneWidget);
      expect(find.text('Source citation'), findsOneWidget);
      expect(find.text('Anchor position 12'), findsOneWidget);
      expect(find.text('Replacement suggestions'), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      final card = tester.widget<Container>(
        find
            .ancestor(
              of: find.text('Source citation'),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = card.decoration! as BoxDecoration;
      expect(decoration.color, Colors.amber);

      await tester.tap(find.text('Apply'));

      expect(actionPressed, isTrue);
    });
  });
}
