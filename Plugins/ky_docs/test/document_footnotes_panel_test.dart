import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/footnote.dart';
import 'package:ky_docs/docx/widgets/footnotes/document_footnotes_panel.dart';

void main() {
  group('DocumentFootnotesPanel', () {
    testWidgets('renders empty state and add action', (tester) async {
      var added = false;

      await _pumpPanel(
        tester,
        footnotes: const [],
        onAddFootnote: () => added = true,
      );

      expect(find.text('No footnotes yet'), findsOneWidget);
      expect(find.text('Add footnote'), findsOneWidget);

      await tester.tap(find.text('Add footnote'));

      expect(added, isTrue);
    });

    testWidgets('renders footnotes and routes edit/delete actions', (
      tester,
    ) async {
      Footnote? editedFootnote;
      Footnote? deletedFootnote;
      const first = Footnote(
        id: 'fn-1',
        number: 1,
        text: 'Source citation',
        offset: 12,
      );
      const second = Footnote(
        id: 'fn-2',
        number: 2,
        text: 'Clarifying note',
        offset: 30,
      );

      await _pumpPanel(
        tester,
        footnotes: const [first, second],
        onEditFootnote: (footnote) => editedFootnote = footnote,
        onDeleteFootnote: (footnote) => deletedFootnote = footnote,
      );

      expect(find.text('2 footnotes'), findsOneWidget);
      expect(find.text('Source citation'), findsOneWidget);
      expect(find.text('Clarifying note'), findsOneWidget);
      expect(find.text('Anchor position 12'), findsOneWidget);

      await tester.tap(find.byTooltip('Edit footnote 2'));
      await tester.tap(find.byTooltip('Delete footnote 1'));

      expect(editedFootnote, same(second));
      expect(deletedFootnote, same(first));
    });
  });
}

Future<void> _pumpPanel(
  WidgetTester tester, {
  required List<Footnote> footnotes,
  VoidCallback? onAddFootnote,
  ValueChanged<Footnote>? onEditFootnote,
  ValueChanged<Footnote>? onDeleteFootnote,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: DocumentFootnotesPanel(
            footnotes: footnotes,
            onAddFootnote: onAddFootnote ?? () {},
            onEditFootnote: onEditFootnote ?? (_) {},
            onDeleteFootnote: onDeleteFootnote ?? (_) {},
          ),
        ),
      ),
    ),
  );
}
