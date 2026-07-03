import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/widgets/editor/command_palette_empty_state.dart';

void main() {
  testWidgets('command palette empty state shows query and clears it', (
    tester,
  ) async {
    var clearRequests = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          body: CommandPaletteEmptyState(
            query: 'timeline export',
            accentColor: const Color(0xFF38BDF8),
            onClearQuery: () => clearRequests++,
          ),
        ),
      ),
    );

    expect(find.text('No commands found'), findsOneWidget);
    expect(find.text('No matches for "timeline export"'), findsOneWidget);

    await tester.tap(find.text('Clear'));
    await tester.pump();

    expect(clearRequests, 1);
  });

  testWidgets('command palette empty state omits clear action without query', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          backgroundColor: Color(0xFF0F172A),
          body: CommandPaletteEmptyState(),
        ),
      ),
    );

    expect(find.text('No commands found'), findsOneWidget);
    expect(find.text('Clear'), findsNothing);
  });
}
