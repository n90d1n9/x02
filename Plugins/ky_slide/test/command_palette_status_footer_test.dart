import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/widgets/editor/command_palette_status_footer.dart';

void main() {
  testWidgets('command palette status footer renders command progress', (
    tester,
  ) async {
    await tester.pumpWidget(
      const _Harness(
        child: CommandPaletteStatusFooter(
          resultCount: 3,
          selectedIndex: 1,
          query: '',
          accentColor: Color(0xFF38BDF8),
        ),
      ),
    );

    expect(find.text('3 commands'), findsOneWidget);
    expect(find.text('2 of 3'), findsOneWidget);
    expect(find.text('Navigate'), findsOneWidget);
    expect(find.text('Run'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
  });

  testWidgets('command palette status footer renders search result count', (
    tester,
  ) async {
    await tester.pumpWidget(
      const _Harness(
        child: CommandPaletteStatusFooter(
          resultCount: 1,
          selectedIndex: 0,
          query: 'slide',
          accentColor: Color(0xFF38BDF8),
        ),
      ),
    );

    expect(find.text('1 match'), findsOneWidget);
    expect(find.text('1 of 1'), findsOneWidget);
  });

  testWidgets('command palette status footer renders no matches', (
    tester,
  ) async {
    await tester.pumpWidget(
      const _Harness(
        child: CommandPaletteStatusFooter(
          resultCount: 0,
          selectedIndex: 0,
          query: 'missing',
          accentColor: Color(0xFF38BDF8),
        ),
      ),
    );

    expect(find.text('No matches'), findsOneWidget);
    expect(find.text('1 of 0'), findsNothing);
    expect(find.text('Esc'), findsOneWidget);
    expect(find.text('Up/Down'), findsNothing);
    expect(find.text('Enter'), findsNothing);
  });

  testWidgets('command palette status footer collapses hints when narrow', (
    tester,
  ) async {
    await tester.pumpWidget(
      const _Harness(
        width: 420,
        child: CommandPaletteStatusFooter(
          resultCount: 3,
          selectedIndex: 0,
          query: '',
          accentColor: Color(0xFF38BDF8),
        ),
      ),
    );

    expect(find.text('Up/Down'), findsOneWidget);
    expect(find.text('Enter'), findsOneWidget);
    expect(find.text('Esc'), findsOneWidget);
    expect(find.text('Navigate'), findsNothing);
    expect(find.text('Run'), findsNothing);
    expect(find.text('Close'), findsNothing);
  });
}

class _Harness extends StatelessWidget {
  final Widget child;
  final double width;

  const _Harness({required this.child, this.width = 720});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Center(
          child: SizedBox(width: width, child: child),
        ),
      ),
    );
  }
}
