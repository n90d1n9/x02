import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/models/enums.dart';
import 'package:ky_slide/widgets/canvas/component_transform_handles.dart';

void main() {
  testWidgets('component resize handle renders semantic target and tooltip', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 120,
            height: 80,
            child: Stack(
              children: [
                ComponentResizeHandle(
                  handle: ResizeHandle.right,
                  alignment: Alignment.centerRight,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('resize-handle-right')), findsOneWidget);
    expect(find.byTooltip('Resize from right'), findsOneWidget);
  });

  testWidgets('component rotate handle renders knob and connector', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 160,
            height: 120,
            child: Stack(
              clipBehavior: Clip.none,
              children: [ComponentRotateHandle(componentWidth: 120)],
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('rotate-handle')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('rotate-handle-connector')),
      findsOneWidget,
    );
    expect(find.byTooltip('Rotate object'), findsOneWidget);
    expect(find.byIcon(Icons.rotate_right), findsOneWidget);
  });

  test('resize handle helpers expose expected copy and cursors', () {
    expect(resizeHandleTooltip(ResizeHandle.topLeft), 'Resize from top left');
    expect(
      resizeHandleCursor(ResizeHandle.right),
      SystemMouseCursors.resizeLeftRight,
    );
  });
}
