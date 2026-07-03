import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/widgets/canvas/slide_canvas_workspace.dart';
import 'package:ky_slide/widgets/ruler/canvas_ruler_corner.dart';
import 'package:ky_slide/widgets/ruler/horizontal_ruler.dart';
import 'package:ky_slide/widgets/ruler/vertical_ruler.dart';

void main() {
  testWidgets('slide canvas workspace frames the canvas with rulers', (
    tester,
  ) async {
    await _pumpWorkspace(
      tester,
      showRuler: true,
      cursorPosition: const Offset(140, 96),
    );

    expect(find.byType(CanvasRulerCorner), findsOneWidget);
    expect(find.byType(HorizontalRuler), findsOneWidget);
    expect(find.byType(VerticalRuler), findsOneWidget);
    expect(find.byKey(const ValueKey('workspace-child')), findsOneWidget);

    final horizontal = tester.widget<HorizontalRuler>(
      find.byType(HorizontalRuler),
    );
    final vertical = tester.widget<VerticalRuler>(find.byType(VerticalRuler));

    expect(horizontal.width, 960);
    expect(horizontal.cursorX, 140);
    expect(vertical.height, 540);
    expect(vertical.cursorY, 96);
  });

  testWidgets('slide canvas workspace hides ruler chrome when disabled', (
    tester,
  ) async {
    await _pumpWorkspace(tester, showRuler: false);

    expect(find.byType(CanvasRulerCorner), findsNothing);
    expect(find.byType(HorizontalRuler), findsNothing);
    expect(find.byType(VerticalRuler), findsNothing);
    expect(find.byKey(const ValueKey('workspace-child')), findsOneWidget);
  });
}

Future<void> _pumpWorkspace(
  WidgetTester tester, {
  required bool showRuler,
  Offset cursorPosition = Offset.zero,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 640,
          height: 400,
          child: SlideCanvasWorkspace(
            showRuler: showRuler,
            slideSize: const Size(960, 540),
            cursorPosition: cursorPosition,
            child: const ColoredBox(
              key: ValueKey('workspace-child'),
              color: Color(0xFF2563EB),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
