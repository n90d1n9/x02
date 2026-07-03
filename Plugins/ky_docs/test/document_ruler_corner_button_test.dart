import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/page_orientation.dart';
import 'package:ky_docs/docx/models/page_settings.dart';
import 'package:ky_docs/docx/models/page_size.dart';
import 'package:ky_docs/docx/widgets/ruler/document_ruler_corner_button.dart';

void main() {
  group('DocumentRulerCornerButton', () {
    testWidgets('shows the compact page size and opens settings from menu', (
      tester,
    ) async {
      var tapped = false;

      await _pumpButton(
        tester,
        pageSettings: const PageSettings(pageSize: PageSize.letter),
        onPressed: () => tapped = true,
      );

      expect(find.byKey(DocumentRulerCornerButton.buttonKey), findsOneWidget);
      expect(find.text('LTR'), findsOneWidget);

      await tester.tap(find.byKey(DocumentRulerCornerButton.buttonKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(DocumentRulerCornerButton.settingsOptionKey));

      expect(tapped, isTrue);
    });

    testWidgets('applies page size updates from the corner menu', (
      tester,
    ) async {
      PageSettings? changedSettings;

      await _pumpButton(
        tester,
        pageSettings: const PageSettings(pageSize: PageSize.a4),
        onPageSettingsChanged: (settings) => changedSettings = settings,
      );

      await tester.tap(find.byKey(DocumentRulerCornerButton.buttonKey));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(DocumentRulerCornerButton.pageSizeOptionKey(PageSize.legal)),
      );

      expect(changedSettings, isNotNull);
      expect(changedSettings!.pageSize, PageSize.legal);
    });

    testWidgets('applies orientation updates from the corner menu', (
      tester,
    ) async {
      PageSettings? changedSettings;

      await _pumpButton(
        tester,
        pageSettings: const PageSettings(),
        onPageSettingsChanged: (settings) => changedSettings = settings,
      );

      await tester.tap(find.byKey(DocumentRulerCornerButton.buttonKey));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          DocumentRulerCornerButton.orientationOptionKey(
            DocumentPageOrientation.landscape,
          ),
        ),
      );

      expect(changedSettings, isNotNull);
      expect(changedSettings!.orientation, DocumentPageOrientation.landscape);
    });

    testWidgets('stays passive when page settings are locked', (tester) async {
      var tapped = false;

      await _pumpButton(
        tester,
        pageSettings: const PageSettings(pageSize: PageSize.legal),
      );

      expect(find.text('LGL'), findsOneWidget);

      await tester.tap(find.byKey(DocumentRulerCornerButton.buttonKey));
      await tester.pumpAndSettle();

      expect(tapped, isFalse);
      expect(
        find.byKey(DocumentRulerCornerButton.settingsOptionKey),
        findsNothing,
      );
    });
  });
}

Future<void> _pumpButton(
  WidgetTester tester, {
  required PageSettings pageSettings,
  ValueChanged<PageSettings>? onPageSettingsChanged,
  VoidCallback? onPressed,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 40,
          height: 28,
          child: DocumentRulerCornerButton(
            pageSettings: pageSettings,
            onPageSettingsChanged: onPageSettingsChanged,
            onPressed: onPressed,
          ),
        ),
      ),
    ),
  );
}
