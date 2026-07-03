import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/page_layout.dart';
import 'package:ky_docs/docx/widgets/document_layout_switcher.dart';

void main() {
  group('DocumentLayoutSwitcher', () {
    testWidgets('shows the active layout label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DocumentLayoutSwitcher(currentLayout: PageLayout.web),
          ),
        ),
      );

      expect(find.text('Web Layout'), findsOneWidget);
    });

    testWidgets('invokes layout selection callbacks', (tester) async {
      PageLayout? selectedLayout;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentLayoutSwitcher(
              currentLayout: PageLayout.print,
              onLayoutSelected: (layout) => selectedLayout = layout,
            ),
          ),
        ),
      );

      await tester.tap(find.byTooltip('Outline Layout'));

      expect(selectedLayout, PageLayout.outline);
    });
  });
}
