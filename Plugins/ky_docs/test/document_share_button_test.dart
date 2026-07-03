import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/widgets/editor_app_bar/share_button.dart';

void main() {
  group('DocumentShareButton', () {
    testWidgets('renders a labeled share action before collaboration starts', (
      tester,
    ) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentShareButton(
              collaborationEnabled: false,
              collaboratorCount: 0,
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Share'), findsOneWidget);

      await tester.tap(find.text('Share'));

      expect(pressed, isTrue);
    });

    testWidgets('shows collaborator count when sharing is active', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentShareButton(
              collaborationEnabled: true,
              collaboratorCount: 3,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Shared'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });
  });
}
