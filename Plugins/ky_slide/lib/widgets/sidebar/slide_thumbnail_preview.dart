import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/component.dart';
import '../../models/presentation_component.dart';
import '../../models/slide.dart';
import '../../models/style/presentation_theme.dart';

class SlideThumbnailPreview extends StatelessWidget {
  final Slide slide;
  final PresentationTheme theme;
  final Size slideSize;
  final int maxVisibleComponents;

  const SlideThumbnailPreview({
    super.key,
    required this.slide,
    required this.theme,
    required this.slideSize,
    this.maxVisibleComponents = 12,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: slide.backgroundColor ?? theme.backgroundColor,
          image: slide.backgroundImage != null
              ? DecorationImage(
                  image: MemoryImage(slide.backgroundImage!),
                  fit: BoxFit.cover,
                )
              : null,
          gradient: slide.backgroundGradient != null
              ? LinearGradient(
                  colors: slide.backgroundGradient!.colors,
                  begin: slide.backgroundGradient!.begin,
                  end: slide.backgroundGradient!.end,
                )
              : null,
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final components = List<PresentationComponent>.from(
              slide.components.where((component) => component.isVisible),
            )..sort((a, b) => a.zIndex.compareTo(b.zIndex));

            return Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.03),
                          Colors.black.withValues(alpha: 0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
                for (final component in components.take(maxVisibleComponents))
                  _ThumbnailComponent(
                    component: component,
                    slideSize: slideSize,
                    previewSize: constraints.biggest,
                    accentColor: theme.primaryColor,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ThumbnailComponent extends StatelessWidget {
  final PresentationComponent component;
  final Size slideSize;
  final Size previewSize;
  final Color accentColor;

  const _ThumbnailComponent({
    required this.component,
    required this.slideSize,
    required this.previewSize,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final left = _scaleX(component.position.dx);
    final top = _scaleY(component.position.dy);
    final width = math.max(4.0, _scaleX(component.size.width));
    final height = math.max(4.0, _scaleY(component.size.height));

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Opacity(
        opacity: component.opacity.clamp(0.2, 1.0),
        child: Transform.rotate(
          angle: component.rotation,
          child: _ComponentShape(
            component: component,
            accentColor: accentColor,
          ),
        ),
      ),
    );
  }

  double _scaleX(double value) {
    if (slideSize.width <= 0 || previewSize.width <= 0) {
      return 0;
    }

    return value * previewSize.width / slideSize.width;
  }

  double _scaleY(double value) {
    if (slideSize.height <= 0 || previewSize.height <= 0) {
      return 0;
    }

    return value * previewSize.height / slideSize.height;
  }
}

class _ComponentShape extends StatelessWidget {
  final PresentationComponent component;
  final Color accentColor;

  const _ComponentShape({required this.component, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    switch (component.type) {
      case ComponentType.richText:
        return _TextSkeleton(color: component.richText?.style.color);
      case ComponentType.image:
      case ComponentType.gif:
        return _ImageSkeleton(component: component);
      case ComponentType.chart:
        return CustomPaint(
          painter: _ChartSkeletonPainter(color: accentColor),
          child: const SizedBox.expand(),
        );
      case ComponentType.circle:
        return _Surface(
          color: _surfaceColor,
          shape: BoxShape.circle,
          borderColor: accentColor,
        );
      case ComponentType.triangle:
        return CustomPaint(
          painter: _TriangleSkeletonPainter(color: _surfaceColor),
          child: const SizedBox.expand(),
        );
      case ComponentType.video:
      case ComponentType.audio:
      case ComponentType.hotspot:
      case ComponentType.poll:
      case ComponentType.quiz:
      case ComponentType.countdown:
      case ComponentType.progressBar:
      case ComponentType.lottie:
      case ComponentType.particles:
      case ComponentType.gradient:
      case ComponentType.diagram:
      case ComponentType.icon:
      case ComponentType.shape:
      case ComponentType.unknown:
        return _Surface(color: _surfaceColor, borderColor: accentColor);
    }
  }

  Color get _surfaceColor {
    return (component.backgroundColor ?? accentColor).withValues(alpha: 0.28);
  }
}

class _TextSkeleton extends StatelessWidget {
  final Color? color;

  const _TextSkeleton({this.color});

  @override
  Widget build(BuildContext context) {
    final lineColor = (color ?? Colors.white).withValues(alpha: 0.68);

    return CustomPaint(
      painter: _TextSkeletonPainter(color: lineColor),
      child: const SizedBox.expand(),
    );
  }
}

class _ImageSkeleton extends StatelessWidget {
  final PresentationComponent component;

  const _ImageSkeleton({required this.component});

  @override
  Widget build(BuildContext context) {
    if (component.imageData != null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: MemoryImage(component.imageData!),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return _Surface(
      color: Colors.white.withValues(alpha: 0.12),
      borderColor: Colors.white.withValues(alpha: 0.18),
    );
  }
}

class _Surface extends StatelessWidget {
  final Color color;
  final Color borderColor;
  final BoxShape shape;

  const _Surface({
    required this.color,
    required this.borderColor,
    this.shape = BoxShape.rectangle,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        shape: shape,
        borderRadius: shape == BoxShape.rectangle
            ? BorderRadius.circular(3)
            : null,
        border: Border.all(color: borderColor.withValues(alpha: 0.42)),
      ),
    );
  }
}

class _TextSkeletonPainter extends CustomPainter {
  final Color color;

  const _TextSkeletonPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }

    final paint = Paint()..style = PaintingStyle.fill;
    final inset = math.min(3.0, math.min(size.width, size.height) * 0.18);
    final lineHeight = math.max(1.0, math.min(3.0, size.height * 0.18));
    final gap = math.max(1.0, size.height * 0.12);
    final top = math.max(0.0, (size.height - (lineHeight * 2 + gap)) / 2);
    final left = inset;
    final availableWidth = math.max(1.0, size.width - (inset * 2));

    for (final line in [
      (widthFactor: 0.88, y: top, alpha: 1.0),
      (widthFactor: 0.64, y: top + lineHeight + gap, alpha: 0.72),
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            left,
            line.y,
            availableWidth * line.widthFactor,
            lineHeight,
          ),
          Radius.circular(lineHeight / 2),
        ),
        paint..color = color.withValues(alpha: line.alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TextSkeletonPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _ChartSkeletonPainter extends CustomPainter {
  final Color color;

  const _ChartSkeletonPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.46)
      ..style = PaintingStyle.fill;
    final barWidth = size.width / 5;

    for (var i = 0; i < 3; i++) {
      final heightFactor = 0.38 + (i * 0.2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            i * barWidth * 1.55,
            size.height * (1 - heightFactor),
            barWidth,
            size.height * heightFactor,
          ),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ChartSkeletonPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _TriangleSkeletonPainter extends CustomPainter {
  final Color color;

  const _TriangleSkeletonPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TriangleSkeletonPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
