import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/page_settings.dart';
import 'package:ky_docs/docx/widgets/document_page_chrome.dart';
import 'package:ky_docs/docx/widgets/page_chrome/document_header_footer_quick_edit_dialog.dart';

void main() {
  group('DocumentPageChrome', () {
    testWidgets('renders configured header, footer, and page number', (
      tester,
    ) async {
      await _pumpChrome(
        tester,
        currentPage: 3,
        pageSettings: const PageSettings(
          showHeader: true,
          header: 'Quarterly Report',
          showFooter: true,
          footer: 'Confidential',
          pageNumberFormat: 'Page {n}',
          pageNumberStart: 2,
        ),
      );

      expect(find.byKey(DocumentPageChrome.headerKey), findsOneWidget);
      expect(find.byKey(DocumentPageChrome.footerKey), findsOneWidget);
      expect(find.text('Quarterly Report'), findsOneWidget);
      expect(find.text('Confidential'), findsOneWidget);
      expect(find.text('Page 4'), findsOneWidget);
      expect(find.byKey(DocumentPageChrome.headerEditButtonKey), findsNothing);
      expect(find.byKey(DocumentPageChrome.footerEditButtonKey), findsNothing);
    });

    testWidgets('edits header text from the page chrome band', (tester) async {
      PageSettings? changedSettings;

      await _pumpChrome(
        tester,
        pageSettings: const PageSettings(
          showHeader: true,
          header: 'Quarterly Report',
        ),
        onPageSettingsChanged: (settings) => changedSettings = settings,
      );

      await tester.tap(find.byKey(DocumentPageChrome.headerEditButtonKey));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(DocumentHeaderFooterQuickEditDialog.textFieldKey),
        'Board Brief',
      );
      await tester.tap(
        find.byKey(DocumentHeaderFooterQuickEditDialog.saveButtonKey),
      );

      expect(changedSettings, isNotNull);
      expect(changedSettings!.showHeader, isTrue);
      expect(changedSettings!.header, 'Board Brief');
    });

    testWidgets('removes footer text from the page chrome band', (
      tester,
    ) async {
      PageSettings? changedSettings;

      await _pumpChrome(
        tester,
        pageSettings: const PageSettings(
          showFooter: true,
          footer: 'Confidential',
        ),
        onPageSettingsChanged: (settings) => changedSettings = settings,
      );

      await tester.tap(find.byKey(DocumentPageChrome.footerEditButtonKey));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(DocumentHeaderFooterQuickEditDialog.removeButtonKey),
      );

      expect(changedSettings, isNotNull);
      expect(changedSettings!.showFooter, isFalse);
      expect(changedSettings!.footer, isNull);
    });

    testWidgets('returns bare content when page chrome is disabled', (
      tester,
    ) async {
      await _pumpChrome(
        tester,
        pageSettings: const PageSettings(
          showHeader: false,
          showFooter: false,
          showPageNumbers: false,
        ),
      );

      expect(find.text('Document body'), findsOneWidget);
      expect(find.byKey(DocumentPageChrome.headerKey), findsNothing);
      expect(find.byKey(DocumentPageChrome.footerKey), findsNothing);
    });

    test('formats page numbers from page settings', () {
      final label = DocumentPageNumberFormatter.format(
        pageSettings: const PageSettings(
          pageNumberFormat: 'Sheet {n}',
          pageNumberStart: 5,
        ),
        currentPage: 2,
      );

      expect(label, 'Sheet 6');
    });
  });
}

Future<void> _pumpChrome(
  WidgetTester tester, {
  required PageSettings pageSettings,
  int currentPage = 1,
  ValueChanged<PageSettings>? onPageSettingsChanged,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 420,
          height: 320,
          child: DocumentPageChrome(
            pageSettings: pageSettings,
            currentPage: currentPage,
            onPageSettingsChanged: onPageSettingsChanged,
            child: const Center(child: Text('Document body')),
          ),
        ),
      ),
    ),
  );
}
