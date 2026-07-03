import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/page_settings.dart';
import 'package:ky_docs/docx/widgets/document_page_vertical_ruler.dart';

void main() {
  group('DocumentPageVerticalRuler', () {
    void useTallTestViewport(WidgetTester tester) {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    }

    testWidgets('renders top and bottom margin semantics', (tester) async {
      useTallTestViewport(tester);
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 842,
              child: DocumentPageVerticalRuler(
                pageSettings: PageSettings(
                  margins: EdgeInsets.only(top: 72, bottom: 90),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(DocumentPageVerticalRuler.rulerKey), findsOneWidget);
      expect(
        tester.getSize(find.byKey(DocumentPageVerticalRuler.rulerKey)),
        const Size(28, 842),
      );
      expect(
        find.bySemanticsLabel(
          'Vertical page ruler, top margin 72 points, bottom margin 90 points, '
          'writing height 680 points',
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(DocumentPageVerticalRuler.topMarginHandleKey),
        findsOneWidget,
      );
      expect(
        find.byKey(DocumentPageVerticalRuler.bottomMarginHandleKey),
        findsOneWidget,
      );

      semantics.dispose();
    });

    testWidgets('drags the top margin handle into updated point margins', (
      tester,
    ) async {
      useTallTestViewport(tester);
      EdgeInsets? updatedMargins;

      await _pumpRuler(
        tester,
        pageSettings: const PageSettings(
          margins: EdgeInsets.fromLTRB(72, 36, 54, 90),
        ),
        onMarginsChanged: (margins) => updatedMargins = margins,
      );

      await tester.drag(
        find.byKey(DocumentPageVerticalRuler.topMarginHandleKey),
        const Offset(0, 56),
      );

      expect(updatedMargins, isNotNull);
      expect(updatedMargins!.left, 72);
      expect(updatedMargins!.top, closeTo(72, 0.1));
      expect(updatedMargins!.right, 54);
      expect(updatedMargins!.bottom, 90);
    });

    testWidgets('drags the bottom margin handle into updated point margins', (
      tester,
    ) async {
      useTallTestViewport(tester);
      EdgeInsets? updatedMargins;

      await _pumpRuler(
        tester,
        pageSettings: const PageSettings(
          margins: EdgeInsets.fromLTRB(72, 36, 54, 90),
        ),
        onMarginsChanged: (margins) => updatedMargins = margins,
      );

      await tester.drag(
        find.byKey(DocumentPageVerticalRuler.bottomMarginHandleKey),
        const Offset(0, 56),
      );

      expect(updatedMargins, isNotNull);
      expect(updatedMargins!.left, 72);
      expect(updatedMargins!.top, 36);
      expect(updatedMargins!.right, 54);
      expect(updatedMargins!.bottom, closeTo(54, 0.1));
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
          height: 842,
          child: DocumentPageVerticalRuler(
            pageSettings: pageSettings,
            onMarginsChanged: onMarginsChanged,
          ),
        ),
      ),
    ),
  );
}
