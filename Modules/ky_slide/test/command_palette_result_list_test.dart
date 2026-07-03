import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/models/command_palette_action.dart';
import 'package:ky_slide/models/command_palette_section.dart';
import 'package:ky_slide/widgets/editor/command_palette_result_list.dart';

void main() {
  testWidgets('command palette result list invokes tapped action', (
    tester,
  ) async {
    final invoked = <String>[];

    await tester.pumpWidget(
      _Harness(selectedIndex: 0, onInvoke: (action) => invoked.add(action.id)),
    );

    await tester.tap(_commandText('Command 1'));
    await tester.pump();

    expect(invoked, ['command-1']);
  });

  testWidgets('command palette result list scrolls selected action into view', (
    tester,
  ) async {
    await tester.pumpWidget(
      _Harness(height: 170, selectedIndex: 10, onInvoke: (_) {}),
    );
    await tester.pumpAndSettle();

    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));

    expect(scrollable.position.pixels, greaterThan(0));
    expect(_commandText('Command 11'), findsOneWidget);
  });
}

Finder _commandText(String text) => find.text(text, findRichText: true);

class _Harness extends StatelessWidget {
  final double height;
  final int selectedIndex;
  final ValueChanged<CommandPaletteAction> onInvoke;

  const _Harness({
    this.height = 320,
    required this.selectedIndex,
    required this.onInvoke,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Center(
          child: SizedBox(
            width: 520,
            height: height,
            child: CommandPaletteResultList(
              sections: [
                CommandPaletteSection(
                  title: 'Commands',
                  actions: [
                    for (var index = 1; index <= 12; index++)
                      CommandPaletteAction(
                        id: 'command-$index',
                        title: 'Command $index',
                        description: 'Run workflow $index',
                        category: 'Commands',
                        icon: Icons.bolt_outlined,
                        keywords: const ['workflow'],
                        onInvoke: () {},
                      ),
                  ],
                ),
              ],
              selectedIndex: selectedIndex,
              query: '',
              accentColor: const Color(0xFF38BDF8),
              onInvoke: onInvoke,
            ),
          ),
        ),
      ),
    );
  }
}
