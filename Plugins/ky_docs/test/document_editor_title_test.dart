import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/widgets/editor_app_bar/document_title.dart';

void main() {
  group('DocumentEditorTitle', () {
    testWidgets('routes rename taps when editable', (tester) async {
      var tapped = false;

      await _pumpTitle(tester, onTap: () => tapped = true);

      expect(find.text('Proposal'), findsOneWidget);
      expect(find.byIcon(Icons.edit), findsOneWidget);

      await tester.tap(find.byKey(DocumentEditorTitle.titleKey));

      expect(tapped, isTrue);
    });

    testWidgets('shows a locked title affordance when read-only', (
      tester,
    ) async {
      var tapped = false;

      await _pumpTitle(tester, onTap: null);

      expect(find.byIcon(Icons.lock_outline), findsOneWidget);

      await tester.tap(
        find.byKey(DocumentEditorTitle.titleKey),
        warnIfMissed: false,
      );

      expect(tapped, isFalse);
    });
  });
}

Future<void> _pumpTitle(WidgetTester tester, {VoidCallback? onTap}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: DocumentEditorTitle(title: 'Proposal', onTap: onTap),
        ),
      ),
    ),
  );
}
