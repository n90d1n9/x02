import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/page_orientation.dart';
import 'package:ky_docs/docx/models/page_settings.dart';
import 'package:ky_docs/docx/widgets/page_navigation/document_page_navigation_model.dart';
import 'package:ky_docs/docx/widgets/page_navigation/document_page_navigator_panel.dart';

void main() {
  group('DocumentPageNavigatorPanel', () {
    testWidgets('shows proportional page thumbnails and selected page state', (
      tester,
    ) async {
      int? selectedPage;

      await _pumpPanel(
        tester,
        model: const DocumentPageNavigationModel(
          currentPage: 2,
          totalPages: 3,
          pageSettings: PageSettings(
            orientation: DocumentPageOrientation.landscape,
          ),
        ),
        onPageSelected: (page) => selectedPage = page,
      );

      expect(find.text('Pages'), findsWidgets);
      expect(find.text('A4 landscape'), findsOneWidget);
      expect(find.text('3 pages'), findsOneWidget);
      expect(find.text('Current'), findsOneWidget);
      expect(
        find.byKey(DocumentPageNavigatorPanel.pageTileKey(2)),
        findsOneWidget,
      );

      final thirdPage = find.byKey(DocumentPageNavigatorPanel.pageTileKey(3));
      await tester.drag(
        find.byKey(DocumentPageNavigatorPanel.pageListKey),
        const Offset(0, -240),
      );
      await tester.pumpAndSettle();
      await tester.tap(thirdPage);

      expect(selectedPage, 3);
    });

    testWidgets('opens with the selected page thumbnail in view', (
      tester,
    ) async {
      await _pumpPanel(
        tester,
        model: const DocumentPageNavigationModel(
          currentPage: 12,
          totalPages: 20,
          pageSettings: PageSettings(),
        ),
      );
      await tester.pumpAndSettle();

      final panelRect = tester.getRect(
        find.byKey(DocumentPageNavigatorPanel.panelKey),
      );
      final selectedPageRect = tester.getRect(
        find.byKey(DocumentPageNavigatorPanel.pageTileKey(12)),
      );

      expect(selectedPageRect.top, greaterThanOrEqualTo(panelRect.top));
      expect(selectedPageRect.bottom, lessThanOrEqualTo(panelRect.bottom));
      expect(
        find.byKey(DocumentPageNavigatorPanel.pageTileKey(1)),
        findsNothing,
      );
    });

    testWidgets('routes the outline entry point', (tester) async {
      var openedOutline = false;

      await _pumpPanel(
        tester,
        model: const DocumentPageNavigationModel(
          currentPage: 1,
          totalPages: 1,
          pageSettings: PageSettings(),
        ),
        onOpenOutline: () => openedOutline = true,
      );

      await tester.tap(find.byKey(DocumentPageNavigatorPanel.outlineButtonKey));

      expect(openedOutline, isTrue);
    });

    testWidgets('routes the close action', (tester) async {
      var closed = false;

      await _pumpPanel(
        tester,
        model: const DocumentPageNavigationModel(
          currentPage: 1,
          totalPages: 1,
          pageSettings: PageSettings(),
        ),
        onClose: () => closed = true,
      );

      await tester.tap(find.byKey(DocumentPageNavigatorPanel.closeButtonKey));

      expect(closed, isTrue);
    });

    testWidgets('routes first, previous, next, and last page controls', (
      tester,
    ) async {
      final selectedPages = <int>[];

      await _pumpPanel(
        tester,
        model: const DocumentPageNavigationModel(
          currentPage: 2,
          totalPages: 3,
          pageSettings: PageSettings(),
        ),
        onPageSelected: selectedPages.add,
      );

      expect(find.text('Page 2 of 3'), findsOneWidget);

      await tester.tap(
        find.byKey(DocumentPageNavigatorPanel.firstPageButtonKey),
      );
      await tester.tap(
        find.byKey(DocumentPageNavigatorPanel.previousPageButtonKey),
      );
      await tester.tap(
        find.byKey(DocumentPageNavigatorPanel.nextPageButtonKey),
      );
      await tester.tap(
        find.byKey(DocumentPageNavigatorPanel.lastPageButtonKey),
      );

      expect(selectedPages, [1, 1, 3, 3]);
    });

    testWidgets('disables step controls at page boundaries', (tester) async {
      int? selectedPage;

      await _pumpPanel(
        tester,
        model: const DocumentPageNavigationModel(
          currentPage: 1,
          totalPages: 1,
          pageSettings: PageSettings(),
        ),
        onPageSelected: (page) => selectedPage = page,
      );

      await tester.tap(
        find.byKey(DocumentPageNavigatorPanel.firstPageButtonKey),
        warnIfMissed: false,
      );
      await tester.tap(
        find.byKey(DocumentPageNavigatorPanel.previousPageButtonKey),
        warnIfMissed: false,
      );
      await tester.tap(
        find.byKey(DocumentPageNavigatorPanel.nextPageButtonKey),
        warnIfMissed: false,
      );
      await tester.tap(
        find.byKey(DocumentPageNavigatorPanel.lastPageButtonKey),
        warnIfMissed: false,
      );

      expect(selectedPage, isNull);
    });

    testWidgets('jumps to typed page numbers and validates empty input', (
      tester,
    ) async {
      int? selectedPage;

      await _pumpPanel(
        tester,
        model: const DocumentPageNavigationModel(
          currentPage: 1,
          totalPages: 4,
          pageSettings: PageSettings(),
        ),
        onPageSelected: (page) => selectedPage = page,
      );

      await tester.enterText(
        find.byKey(DocumentPageNavigatorPanel.pageJumpFieldKey),
        '99',
      );
      await tester.tap(
        find.byKey(DocumentPageNavigatorPanel.pageJumpButtonKey),
      );
      await tester.pumpAndSettle();

      expect(selectedPage, 4);
      expect(
        find.byKey(DocumentPageNavigatorPanel.pageJumpErrorKey),
        findsNothing,
      );

      selectedPage = null;
      await tester.enterText(
        find.byKey(DocumentPageNavigatorPanel.pageJumpFieldKey),
        '',
      );
      await tester.tap(
        find.byKey(DocumentPageNavigatorPanel.pageJumpButtonKey),
      );
      await tester.pumpAndSettle();

      expect(selectedPage, isNull);
      expect(find.text('Enter 1-4'), findsOneWidget);
      expect(
        find.byKey(DocumentPageNavigatorPanel.pageJumpErrorKey),
        findsOneWidget,
      );
    });
  });
}

Future<void> _pumpPanel(
  WidgetTester tester, {
  required DocumentPageNavigationModel model,
  ValueChanged<int>? onPageSelected,
  VoidCallback? onOpenOutline,
  VoidCallback? onClose,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 284,
          height: 620,
          child: DocumentPageNavigatorPanel(
            model: model,
            onPageSelected: onPageSelected ?? (_) {},
            onOpenOutline: onOpenOutline,
            onClose: onClose,
          ),
        ),
      ),
    ),
  );
}
