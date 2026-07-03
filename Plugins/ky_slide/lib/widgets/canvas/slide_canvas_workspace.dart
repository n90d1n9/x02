import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../ruler/canvas_ruler_corner.dart';
import '../ruler/horizontal_ruler.dart';
import '../ruler/vertical_ruler.dart';

/// Reusable workspace chrome that frames the slide canvas with optional rulers.
class SlideCanvasWorkspace extends StatelessWidget {
  final bool showRuler;
  final Size slideSize;
  final Offset cursorPosition;
  final Widget child;

  const SlideCanvasWorkspace({
    super.key,
    required this.showRuler,
    required this.slideSize,
    required this.cursorPosition,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFF101114)),
      child: Column(
        children: [
          if (showRuler)
            SizedBox(
              height: CanvasRulerCorner.size,
              child: Row(
                children: [
                  const CanvasRulerCorner(),
                  Expanded(
                    child: HorizontalRuler(
                      width: slideSize.width,
                      cursorX: cursorPosition.dx,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Row(
              children: [
                if (showRuler)
                  VerticalRuler(
                    height: slideSize.height,
                    cursorY: cursorPosition.dy,
                  ),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

@Preview(name: 'Slide canvas workspace', size: Size(820, 520))
Widget slideCanvasWorkspacePreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      body: SlideCanvasWorkspace(
        showRuler: true,
        slideSize: const Size(960, 540),
        cursorPosition: const Offset(180, 120),
        child: Center(
          child: Container(
            width: 560,
            height: 315,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 28,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
