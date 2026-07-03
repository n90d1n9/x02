import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/document_outline.dart';
import 'package:ky_docs/docx/widgets/outline/document_outline_navigation_model.dart';
import 'package:ky_docs/docx/widgets/outline/outline_panel.dart';

void main() {
  group('DocxOutlinePanel', () {
    testWidgets('renders heading search, level filters, and document map', (
      tester,
    ) async {
      await _pumpPanel(tester, outline: _outlineFixture());

      expect(find.text('Document map'), findsOneWidget);
      expect(find.text('Jump between headings'), findsOneWidget);
      expect(find.text('All 4'), findsOneWidget);
      expect(find.text('H1 1'), findsOneWidget);
      expect(find.text('H2 2'), findsOneWidget);
      expect(find.text('H3+ 1'), findsOneWidget);
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('API Appendix'), findsOneWidget);
    });

    testWidgets('filters headings and routes heading jumps', (tester) async {
      int? jumpedOffset;

      await _pumpPanel(
        tester,
        outline: _outlineFixture(),
        onJumpToOffset: (offset) => jumpedOffset = offset,
      );

      await tester.enterText(
        find.byKey(DocxOutlinePanel.searchFieldKey),
        'pricing',
      );
      await tester.pumpAndSettle();

      expect(find.text('Pricing Detail'), findsOneWidget);
      expect(find.text('Overview'), findsNothing);
      expect(find.text('1/4'), findsOneWidget);

      await tester.tap(
        find.byKey(Key('${DocxOutlinePanel.tilePrefixKey}-pricing-detail')),
      );

      expect(jumpedOffset, 52);
    });

    testWidgets('filters by heading level', (tester) async {
      await _pumpPanel(tester, outline: _outlineFixture());

      final h3PlusFilter = find.byKey(
        Key(
          '${DocxOutlinePanel.filterPrefixKey}-'
          '${DocumentOutlineLevelFilter.levelThreePlus.name}',
        ),
      );
      await tester.ensureVisible(h3PlusFilter);
      await tester.pumpAndSettle();
      await tester.tap(h3PlusFilter);
      await tester.pumpAndSettle();

      expect(find.text('API Appendix'), findsOneWidget);
      expect(find.text('Overview'), findsNothing);
      expect(find.text('1/4'), findsOneWidget);
    });

    testWidgets('routes the page navigator entry point', (tester) async {
      var openedPages = false;

      await _pumpPanel(
        tester,
        outline: _outlineFixture(),
        onOpenPageNavigator: () => openedPages = true,
      );

      await tester.tap(find.byKey(DocxOutlinePanel.pagesButtonKey));

      expect(openedPages, isTrue);
    });

    testWidgets('routes the close action', (tester) async {
      var closed = false;

      await _pumpPanel(
        tester,
        outline: _outlineFixture(),
        onClose: () => closed = true,
      );

      await tester.tap(find.byKey(DocxOutlinePanel.closeButtonKey));

      expect(closed, isTrue);
    });
  });
}

Future<void> _pumpPanel(
  WidgetTester tester, {
  required List<DocumentOutline> outline,
  ValueChanged<int>? onJumpToOffset,
  VoidCallback? onOpenPageNavigator,
  VoidCallback? onClose,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 320,
          height: 680,
          child: DocxOutlinePanel(
            outline: outline,
            onJumpToOffset: onJumpToOffset ?? (_) {},
            onOpenPageNavigator: onOpenPageNavigator,
            onClose: onClose,
          ),
        ),
      ),
    ),
  );
}

List<DocumentOutline> _outlineFixture() {
  return const [
    DocumentOutline(id: 'overview', title: 'Overview', level: 1, offset: 0),
    DocumentOutline(id: 'goals', title: 'Project Goals', level: 2, offset: 20),
    DocumentOutline(id: 'api', title: 'API Appendix', level: 3, offset: 36),
    DocumentOutline(
      id: 'pricing-detail',
      title: 'Pricing Detail',
      level: 2,
      offset: 52,
    ),
  ];
}
