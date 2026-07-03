import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/widgets/keyboard_shortcut_dialog.dart';

void main() {
  group('KeyboardShortcutDialog', () {
    testWidgets('renders grouped shortcut sections', (tester) async {
      await _pumpDialog(tester);

      expect(find.text('Keyboard shortcuts'), findsOneWidget);
      expect(find.text('Document'), findsOneWidget);
      expect(find.text('Formatting'), findsOneWidget);
      expect(find.text('Save document'), findsOneWidget);
      expect(find.text('Command palette'), findsOneWidget);
      expect(find.text('Ctrl/Cmd'), findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, -240));
      await tester.pump();

      expect(find.text('Selection'), findsOneWidget);
    });

    testWidgets('filters shortcuts by action and keyboard chord', (
      tester,
    ) async {
      await _pumpDialog(tester);

      await tester.enterText(
        find.byKey(KeyboardShortcutDialog.searchFieldKey),
        'palette',
      );
      await tester.pump();

      expect(find.text('Command palette'), findsOneWidget);
      expect(find.text('Save document'), findsNothing);

      await tester.enterText(
        find.byKey(KeyboardShortcutDialog.searchFieldKey),
        'ctrl h',
      );
      await tester.pump();

      expect(find.text('Find and replace'), findsOneWidget);
      expect(find.text('Command palette'), findsNothing);
    });

    testWidgets('shows an empty state when no shortcut matches', (
      tester,
    ) async {
      await _pumpDialog(tester);

      await tester.enterText(
        find.byKey(KeyboardShortcutDialog.searchFieldKey),
        'presentation mode',
      );
      await tester.pump();

      expect(find.text('No shortcuts found'), findsOneWidget);
      expect(find.text('Save document'), findsNothing);
    });
  });
}

Future<void> _pumpDialog(WidgetTester tester) {
  return tester.pumpWidget(
    const MaterialApp(
      home: Scaffold(body: Center(child: KeyboardShortcutDialog())),
    ),
  );
}
