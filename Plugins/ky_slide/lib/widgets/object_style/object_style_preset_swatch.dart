import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

/// Reusable miniature preview swatch for object style preset controls.
class ObjectStylePresetSwatch extends StatelessWidget {
  final Color fillColor;
  final Color borderColor;
  final bool showGlow;
  final double width;
  final double height;
  final double radius;

  const ObjectStylePresetSwatch({
    super.key,
    required this.fillColor,
    required this.borderColor,
    required this.showGlow,
    this.width = 28,
    this.height = 20,
    this.radius = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: borderColor.withValues(alpha: 0.36),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
    );
  }
}

@Preview(name: 'Object style preset swatch', size: Size(120, 80))
Widget objectStylePresetSwatchPreview() {
  return const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: Color(0xFF101114),
      body: Center(
        child: ObjectStylePresetSwatch(
          fillColor: Color(0x3D14B8A6),
          borderColor: Color(0x7038BDF8),
          showGlow: true,
        ),
      ),
    ),
  );
}
