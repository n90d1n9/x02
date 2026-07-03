import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/page_settings.dart';
import 'package:ky_docs/docx/widgets/document_page_ruler.dart';

void main() {
  group('DocumentPageRuler', () {
    testWidgets('renders margin-aware ruler semantics', (tester) async {
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 600,
              child: DocumentPageRuler(
                pageSettings: PageSettings(
                  margins: EdgeInsets.only(left: 72, right: 54),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(DocumentPageRuler.rulerKey), findsOneWidget);
      expect(
        tester.getSize(find.byKey(DocumentPageRuler.rulerKey)),
        const Size(600, 28),
      );
      expect(
        find.bySemanticsLabel(
          'Page ruler, left margin 72 points, right margin 54 points, '
          'writing width 469 points',
        ),
        findsOneWidget,
      );
      expect(find.byKey(DocumentPageRuler.leftMarginHandleKey), findsOneWidget);
      expect(
        find.byKey(DocumentPageRuler.rightMarginHandleKey),
        findsOneWidget,
      );

      semantics.dispose();
    });

    testWidgets('drags the left margin handle into updated point margins', (
      tester,
    ) async {
      EdgeInsets? updatedMargins;

      await _pumpRuler(
        tester,
        pageSettings: const PageSettings(
          margins: EdgeInsets.fromLTRB(72, 36, 54, 90),
        ),
        onMarginsChanged: (margins) => updatedMargins = margins,
      );

      await tester.drag(
        find.byKey(DocumentPageRuler.leftMarginHandleKey),
        const Offset(56, 0),
      );

      expect(updatedMargins, isNotNull);
      expect(updatedMargins!.left, closeTo(108, 0.1));
      expect(updatedMargins!.top, 36);
      expect(updatedMargins!.right, 54);
      expect(updatedMargins!.bottom, 90);
    });

    testWidgets('drags the right margin handle into updated point margins', (
      tester,
    ) async {
      EdgeInsets? updatedMargins;

      await _pumpRuler(
        tester,
        pageSettings: const PageSettings(
          margins: EdgeInsets.fromLTRB(72, 36, 54, 90),
        ),
        onMarginsChanged: (margins) => updatedMargins = margins,
      );

      await tester.drag(
        find.byKey(DocumentPageRuler.rightMarginHandleKey),
        const Offset(56, 0),
      );

      expect(updatedMargins, isNotNull);
      expect(updatedMargins!.left, 72);
      expect(updatedMargins!.top, 36);
      expect(updatedMargins!.right, closeTo(18, 0.1));
      expect(updatedMargins!.bottom, 90);
    });

    testWidgets('keeps margin handles passive without a change callback', (
      tester,
    ) async {
      await _pumpRuler(
        tester,
        pageSettings: const PageSettings(
          margins: EdgeInsets.fromLTRB(72, 36, 54, 90),
        ),
      );

      await tester.drag(
        find.byKey(DocumentPageRuler.leftMarginHandleKey),
        const Offset(36, 0),
      );

      expect(find.byKey(DocumentPageRuler.leftMarginHandleKey), findsOneWidget);
      expect(
        find.byKey(DocumentPageRuler.rightMarginHandleKey),
        findsOneWidget,
      );
    });
  });
}

Future<void> _pumpRuler(
  WidgetTester tester, {
  required PageSettings pageSettings,
  ValueChanged<EdgeInsets>? onMarginsChanged,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 595,
          child: DocumentPageRuler(
            pageSettings: pageSettings,
            onMarginsChanged: onMarginsChanged,
          ),
        ),
      ),
    ),
  );
}
