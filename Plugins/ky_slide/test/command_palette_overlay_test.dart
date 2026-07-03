import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/models/command_palette_action.dart';
import 'package:ky_slide/widgets/editor/command_palette_overlay.dart';

void main() {
  testWidgets('command palette filters commands and invokes an action', (
    tester,
  ) async {
    final invoked = <String>[];
    final recorded = <String>[];
    var closeRequests = 0;

    await tester.pumpWidget(
      _harness(
        actions: _actions(onInvoke: invoked.add),
        onClose: () => closeRequests++,
        onCommandInvoked: (action) => recorded.add(action.id),
      ),
    );
    await tester.pump();

    expect(_commandText('Open Slide Board'), findsOneWidget);
    expect(_commandText('Open Import / Export'), findsOneWidget);
    expect(find.text('2 commands'), findsOneWidget);
    expect(find.text('1 of 2'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'files');
    await tester.pump();

    expect(_commandText('Open Slide Board'), findsNothing);
    expect(_commandText('Open Import / Export'), findsOneWidget);
    expect(find.text('1 match'), findsOneWidget);

    await tester.tap(_commandText('Open Import / Export'));
    await tester.pump();

    expect(invoked, ['files']);
    expect(recorded, ['files']);
    expect(closeRequests, 1);
  });

  testWidgets('command palette renders recent commands ahead of categories', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        actions: _actions(onInvoke: (_) {}),
        recentCommandIds: const ['files'],
        onClose: () {},
      ),
    );
    await tester.pump();

    expect(find.text('RECENT'), findsOneWidget);
    expect(find.text('VIEW'), findsOneWidget);
    expect(find.text('PPTX'), findsOneWidget);
    expect(find.text('Panel'), findsOneWidget);
    expect(_commandText('Open Import / Export'), findsOneWidget);
    expect(_commandText('Open Slide Board'), findsOneWidget);
  });

  testWidgets('command palette clears a no-result query from empty state', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        actions: _actions(onInvoke: (_) {}),
        onClose: () {},
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'missing command');
    await tester.pump();

    expect(find.text('No commands found'), findsOneWidget);
    expect(find.text('No matches for "missing command"'), findsOneWidget);
    expect(find.text('No matches'), findsOneWidget);

    await tester.tap(find.text('Clear'));
    await tester.pump();

    expect(find.text('No commands found'), findsNothing);
    expect(_commandText('Open Slide Board'), findsOneWidget);
    expect(_commandText('Open Import / Export'), findsOneWidget);
    expect(find.text('2 commands'), findsOneWidget);
  });

  testWidgets('command palette closes from escape and close button', (
    tester,
  ) async {
    var closeRequests = 0;

    await tester.pumpWidget(
      _harness(
        actions: _actions(onInvoke: (_) {}),
        onClose: () => closeRequests++,
      ),
    );
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    expect(closeRequests, 1);

    await tester.tap(find.byTooltip('Close command palette'));
    await tester.pump();

    expect(closeRequests, 2);
  });
}

Finder _commandText(String text) => find.text(text, findRichText: true);

Widget _harness({
  required List<CommandPaletteAction> actions,
  required VoidCallback onClose,
  List<String> recentCommandIds = const [],
  ValueChanged<CommandPaletteAction>? onCommandInvoked,
}) {
  return MaterialApp(
    home: Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: CommandPaletteOverlay(
        accentColor: const Color(0xFF2563EB),
        actions: actions,
        onClose: onClose,
        recentCommandIds: recentCommandIds,
        onCommandInvoked: onCommandInvoked,
      ),
    ),
  );
}

List<CommandPaletteAction> _actions({required ValueChanged<String> onInvoke}) {
  return [
    CommandPaletteAction(
      id: 'slide-board',
      title: 'Open Slide Board',
      description: 'Organize and batch edit slides',
      category: 'View',
      icon: Icons.view_module_outlined,
      keywords: const ['sorter', 'grid', 'slides'],
      metadataLabels: const ['Overlay'],
      onInvoke: () => onInvoke('slide-board'),
    ),
    CommandPaletteAction(
      id: 'files',
      title: 'Open Import / Export',
      description: 'Show presentation file actions',
      category: 'Files',
      icon: Icons.folder_open_outlined,
      keywords: const ['ppt', 'pptx', 'files'],
      metadataLabels: const ['Panel', 'PPTX'],
      onInvoke: () => onInvoke('files'),
    ),
  ];
}
