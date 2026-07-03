import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/widgets/panel/document_panel_search_field.dart';

void main() {
  group('DocumentPanelSearchField', () {
    testWidgets('renders search text and routes clear action', (tester) async {
      final controller = TextEditingController(text: 'draft');
      addTearDown(controller.dispose);
      var cleared = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentPanelSearchField(
              fieldKey: const Key('panel-search'),
              clearButtonKey: const Key('clear-panel-search'),
              controller: controller,
              hintText: 'Search panel',
              onChanged: (_) {},
              onClear: () {
                controller.clear();
                cleared = true;
              },
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('panel-search')), findsOneWidget);
      expect(find.byKey(const Key('clear-panel-search')), findsOneWidget);

      await tester.tap(find.byKey(const Key('clear-panel-search')));

      expect(cleared, isTrue);
      expect(controller.text, isEmpty);
    });

    testWidgets('uses explicit query state for externally managed searches', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentPanelSearchField(
              clearButtonKey: const Key('clear-panel-search'),
              controller: controller,
              hintText: 'Search panel',
              hasQuery: true,
              onChanged: (_) {},
              onClear: () {},
              tone: DocumentPanelSearchFieldTone.container,
            ),
          ),
        ),
      );

      expect(find.text('Search panel'), findsOneWidget);
      expect(find.byKey(const Key('clear-panel-search')), findsOneWidget);
    });
  });
}
