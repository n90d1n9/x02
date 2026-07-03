import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/widgets/editor/command_palette_keyboard_hints.dart';

void main() {
  testWidgets('command palette keyboard hints render full labels', (
    tester,
  ) async {
    await tester.pumpWidget(
      const _Harness(
        child: CommandPaletteKeyboardHints(accentColor: Color(0xFF38BDF8)),
      ),
    );

    expect(find.text('Up/Down'), findsOneWidget);
    expect(find.text('Navigate'), findsOneWidget);
    expect(find.text('Enter'), findsOneWidget);
    expect(find.text('Run'), findsOneWidget);
    expect(find.text('Esc'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
  });

  testWidgets('command palette keyboard hints hide disabled result actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      const _Harness(
        child: CommandPaletteKeyboardHints(
          accentColor: Color(0xFF38BDF8),
          canNavigate: false,
          canRun: false,
        ),
      ),
    );

    expect(find.text('Up/Down'), findsNothing);
    expect(find.text('Enter'), findsNothing);
    expect(find.text('Esc'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
  });

  testWidgets(
    'command palette keyboard hints collapse labels in compact mode',
    (tester) async {
      await tester.pumpWidget(
        const _Harness(
          child: CommandPaletteKeyboardHints(
            accentColor: Color(0xFF38BDF8),
            compact: true,
          ),
        ),
      );

      expect(find.text('Up/Down'), findsOneWidget);
      expect(find.text('Enter'), findsOneWidget);
      expect(find.text('Esc'), findsOneWidget);
      expect(find.text('Navigate'), findsNothing);
      expect(find.text('Run'), findsNothing);
      expect(find.text('Close'), findsNothing);
    },
  );
}

class _Harness extends StatelessWidget {
  final Widget child;

  const _Harness({required this.child});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Center(child: child),
      ),
    );
  }
}
