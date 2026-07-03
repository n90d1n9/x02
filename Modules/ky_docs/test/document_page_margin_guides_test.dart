import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/page_settings.dart';
import 'package:ky_docs/docx/widgets/page_margin/document_page_margin_guides.dart';

void main() {
  group('DocumentPageMarginGuides', () {
    testWidgets('renders child content with four guide lines', (tester) async {
      await _pumpGuides(
        tester,
        visible: true,
        child: const Center(child: Text('Document body')),
      );

      expect(find.text('Document body'), findsOneWidget);
      expect(find.byKey(DocumentPageMarginGuides.guidesKey), findsOneWidget);
      expect(find.byKey(DocumentPageMarginGuides.topGuideKey), findsOneWidget);
      expect(
        find.byKey(DocumentPageMarginGuides.rightGuideKey),
        findsOneWidget,
      );
      expect(
        find.byKey(DocumentPageMarginGuides.bottomGuideKey),
        findsOneWidget,
      );
      expect(find.byKey(DocumentPageMarginGuides.leftGuideKey), findsOneWidget);
    });

    testWidgets('returns bare content when guides are hidden', (tester) async {
      await _pumpGuides(
        tester,
        visible: false,
        child: const Center(child: Text('Document body')),
      );

      expect(find.text('Document body'), findsOneWidget);
      expect(find.byKey(DocumentPageMarginGuides.guidesKey), findsNothing);
      expect(find.byKey(DocumentPageMarginGuides.topGuideKey), findsNothing);
    });
  });
}

Future<void> _pumpGuides(
  WidgetTester tester, {
  required bool visible,
  required Widget child,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 600,
          height: 420,
          child: DocumentPageMarginGuides(
            pageSettings: const PageSettings(
              margins: EdgeInsets.fromLTRB(72, 54, 72, 72),
            ),
            visible: visible,
            child: child,
          ),
        ),
      ),
    ),
  );
}
