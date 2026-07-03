import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/widgets/navigation/document_navigation_panel_close_button.dart';

void main() {
  group('DocumentNavigationPanelCloseButton', () {
    testWidgets('dismisses navigation rails through a compact action', (
      tester,
    ) async {
      var closed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: DocumentNavigationPanelCloseButton(
                onPressed: () => closed = true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byTooltip('Close navigation panel'));

      expect(closed, isTrue);
    });
  });
}
