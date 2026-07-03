import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/widgets/navigation/document_navigation_panel_switcher.dart';

void main() {
  group('DocumentNavigationPanelSwitcher', () {
    testWidgets('routes mode changes and keeps the selected mode inert', (
      tester,
    ) async {
      var openedPages = false;
      var openedOutline = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 260,
              child: DocumentNavigationPanelSwitcher(
                selectedMode: DocumentNavigationPanelMode.pages,
                onPagesSelected: () => openedPages = true,
                onOutlineSelected: () => openedOutline = true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(
        find.byKey(
          DocumentNavigationPanelSwitcher.modeButtonKey(
            DocumentNavigationPanelMode.pages,
          ),
        ),
      );
      await tester.tap(
        find.byKey(
          DocumentNavigationPanelSwitcher.modeButtonKey(
            DocumentNavigationPanelMode.outline,
          ),
        ),
      );

      expect(openedPages, isFalse);
      expect(openedOutline, isTrue);
    });
  });
}
