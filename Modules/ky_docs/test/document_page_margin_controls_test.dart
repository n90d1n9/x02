import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/page_margin_preset.dart';
import 'package:ky_docs/docx/widgets/page_settings/document_page_margin_controls.dart';

void main() {
  group('DocumentPageMarginControls', () {
    testWidgets('applies selected margin presets', (tester) async {
      EdgeInsets? changedMargins;

      await _pumpControls(
        tester,
        margins: DocumentPageMarginPreset.normal.margins,
        onChanged: (margins) => changedMargins = margins,
      );

      await tester.tap(find.text('Narrow'));
      await tester.pump();

      expect(changedMargins, DocumentPageMarginPreset.narrow.margins);
    });

    testWidgets('emits exact margin values from numeric fields', (
      tester,
    ) async {
      EdgeInsets? changedMargins;

      await _pumpControls(
        tester,
        margins: const EdgeInsets.fromLTRB(72, 36, 54, 90),
        onChanged: (margins) => changedMargins = margins,
      );

      await tester.enterText(
        find.byKey(DocumentPageMarginControls.leftFieldKey),
        '80',
      );
      await tester.pump();

      expect(changedMargins, isNotNull);
      expect(changedMargins!.left, 80);
      expect(changedMargins!.top, 36);
      expect(changedMargins!.right, 54);
      expect(changedMargins!.bottom, 90);
    });
  });
}

Future<void> _pumpControls(
  WidgetTester tester, {
  required EdgeInsets margins,
  required ValueChanged<EdgeInsets> onChanged,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 520,
          child: DocumentPageMarginControls(
            margins: margins,
            onChanged: onChanged,
          ),
        ),
      ),
    ),
  );
}
