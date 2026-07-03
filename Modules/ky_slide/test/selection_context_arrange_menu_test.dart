import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/models/component_arrange_action.dart';
import 'package:ky_slide/widgets/canvas/selection_context_arrange_menu.dart';

void main() {
  testWidgets('selection context arrange menu dispatches align actions', (
    tester,
  ) async {
    ComponentArrangeAction? selectedAction;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF101114),
          body: Center(
            child: SelectionContextArrangeMenu(
              accentColor: const Color(0xFF38BDF8),
              enabled: true,
              onSelected: (action) => selectedAction = action,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Align selected object'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Align right'));
    await tester.pumpAndSettle();

    expect(selectedAction, ComponentArrangeAction.alignRight);
  });
}
