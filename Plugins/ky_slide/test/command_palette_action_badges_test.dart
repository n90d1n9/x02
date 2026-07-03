import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/widgets/editor/command_palette_action_badges.dart';

void main() {
  testWidgets('command palette action badges render shortcut and metadata', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          backgroundColor: Color(0xFF0F172A),
          body: Center(
            child: CommandPaletteActionBadges(
              category: 'Object',
              shortcutLabel: 'Cmd/Ctrl+D',
              metadataLabels: ['Selected', 'Layer'],
              enabled: true,
              accentColor: Color(0xFF38BDF8),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Cmd/Ctrl+D'), findsOneWidget);
    expect(find.text('Selected'), findsOneWidget);
    expect(find.text('Layer'), findsOneWidget);
    expect(find.text('Object'), findsOneWidget);
  });
}
