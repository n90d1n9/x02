import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

/// Corner block that visually joins the horizontal and vertical canvas rulers.
class CanvasRulerCorner extends StatelessWidget {
  static const double size = 30;

  const CanvasRulerCorner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF181B20),
        border: Border(
          right: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Center(
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

@Preview(name: 'Canvas ruler corner', size: Size(90, 90))
Widget canvasRulerCornerPreview() {
  return const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: Color(0xFF101114),
      body: Center(child: CanvasRulerCorner()),
    ),
  );
}
