import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/widgets/insert_elements/insert_element_command.dart';
import 'package:ky_docs/docx/widgets/insert_elements/insert_elements_hub.dart';

void main() {
  group('InsertElementsHub', () {
    testWidgets('renders grouped insert commands', (tester) async {
      await _pumpHub(tester);

      expect(find.text('Content'), findsOneWidget);
      expect(find.text('Media'), findsOneWidget);
      expect(find.text('References'), findsOneWidget);
      expect(find.text('Shapes'), findsOneWidget);
      expect(find.text('Table'), findsOneWidget);
      expect(find.text('Footnote'), findsOneWidget);
      expect(find.text('Rectangle'), findsOneWidget);
    });

    testWidgets('routes command selections', (tester) async {
      InsertElementCommandId? selectedCommand;

      await _pumpHub(
        tester,
        onCommandSelected: (command) => selectedCommand = command,
      );

      await tester.tap(_commandFinder(InsertElementCommandId.chart));

      expect(selectedCommand, InsertElementCommandId.chart);
    });

    testWidgets('routes close action when provided', (tester) async {
      var closed = false;

      await _pumpHub(tester, onClose: () => closed = true);
      await tester.tap(find.byKey(InsertElementsHub.closeButtonKey));

      expect(closed, isTrue);
    });

    testWidgets('supports embedded dock mode without duplicate title', (
      tester,
    ) async {
      await _pumpHub(tester, showHeader: false);

      expect(find.text('Insert'), findsNothing);
      expect(find.byKey(InsertElementsHub.closeButtonKey), findsNothing);
      expect(find.text('Content'), findsOneWidget);
      expect(find.text('Table'), findsOneWidget);
    });
  });
}

Finder _commandFinder(InsertElementCommandId command) {
  return find.byKey(ValueKey('${InsertElementsHub.commandPrefixKey}-$command'));
}

Future<void> _pumpHub(
  WidgetTester tester, {
  ValueChanged<InsertElementCommandId>? onCommandSelected,
  VoidCallback? onClose,
  bool showHeader = true,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 920,
          child: InsertElementsHub(
            onCommandSelected: onCommandSelected ?? (_) {},
            onClose: onClose,
            showHeader: showHeader,
          ),
        ),
      ),
    ),
  );
}
