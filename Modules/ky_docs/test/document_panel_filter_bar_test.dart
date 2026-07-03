import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/widgets/panel/document_panel_filter_bar.dart';

enum _FilterFixture { all, flagged }

void main() {
  group('DocumentPanelFilterBar', () {
    testWidgets('renders counted chips and routes selection', (tester) async {
      _FilterFixture? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentPanelFilterBar<_FilterFixture>(
              keyPrefix: 'fixture-filter',
              selectedValue: _FilterFixture.all,
              options: const [
                DocumentPanelFilterOption(
                  value: _FilterFixture.all,
                  keySuffix: 'all',
                  label: 'All',
                  count: 3,
                  tooltip: 'Show all items',
                ),
                DocumentPanelFilterOption(
                  value: _FilterFixture.flagged,
                  keySuffix: 'flagged',
                  label: 'Flagged',
                  count: 1,
                ),
              ],
              onSelected: (value) => selected = value,
            ),
          ),
        ),
      );

      expect(find.text('All 3'), findsOneWidget);
      expect(find.text('Flagged 1'), findsOneWidget);
      expect(find.byTooltip('Show all items'), findsOneWidget);

      await tester.tap(find.byKey(const Key('fixture-filter-flagged')));

      expect(selected, _FilterFixture.flagged);
    });
  });
}
