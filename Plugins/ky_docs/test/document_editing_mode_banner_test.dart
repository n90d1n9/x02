import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/document_editing_mode.dart';
import 'package:ky_docs/docx/widgets/review_mode/document_editing_mode_banner.dart';

void main() {
  group('DocumentEditingModeBanner', () {
    testWidgets('shows a review action for suggesting mode', (tester) async {
      var actionTapped = false;

      await _pumpBanner(
        tester,
        mode: DocumentEditingMode.suggesting,
        onPrimaryAction: () => actionTapped = true,
      );

      expect(find.byKey(DocumentEditingModeBanner.bannerKey), findsOneWidget);
      expect(find.text('Suggesting mode'), findsOneWidget);
      expect(find.text('Review'), findsOneWidget);

      await tester.tap(find.byKey(DocumentEditingModeBanner.primaryActionKey));

      expect(actionTapped, isTrue);
    });

    testWidgets('shows an edit action for viewing mode', (tester) async {
      await _pumpBanner(tester, mode: DocumentEditingMode.viewing);

      expect(find.text('Viewing only'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
    });

    testWidgets('stays hidden for default editing mode', (tester) async {
      await _pumpBanner(tester, mode: DocumentEditingMode.editing);

      expect(find.byKey(DocumentEditingModeBanner.bannerKey), findsNothing);
    });
  });
}

Future<void> _pumpBanner(
  WidgetTester tester, {
  required DocumentEditingMode mode,
  VoidCallback? onPrimaryAction,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 760,
          child: DocumentEditingModeBanner(
            mode: mode,
            onPrimaryAction: onPrimaryAction,
          ),
        ),
      ),
    ),
  );
}
