import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/page_settings.dart';
import 'document_page_margin_guide_geometry.dart';

/// Overlays subtle page margin guides on the print-layout writing surface.
class DocumentPageMarginGuides extends StatelessWidget {
  static const guidesKey = ValueKey('document-page-margin-guides');
  static const topGuideKey = ValueKey('document-page-margin-guides-top');
  static const rightGuideKey = ValueKey('document-page-margin-guides-right');
  static const bottomGuideKey = ValueKey('document-page-margin-guides-bottom');
  static const leftGuideKey = ValueKey('document-page-margin-guides-left');

  final PageSettings pageSettings;
  final Widget child;
  final bool visible;
  final double guideThickness;

  const DocumentPageMarginGuides({
    super.key,
    required this.pageSettings,
    required this.child,
    this.visible = true,
    this.guideThickness = 1,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) return child;

    final colorScheme = Theme.of(context).colorScheme;
    final guideColor = colorScheme.primary.withValues(alpha: 0.26);

    return LayoutBuilder(
      builder: (context, constraints) {
        final fallbackPageSize = pageSettings.getPageSize();
        final surfaceSize = Size(
          constraints.hasBoundedWidth
              ? constraints.maxWidth
              : fallbackPageSize.width,
          constraints.hasBoundedHeight
              ? constraints.maxHeight
              : fallbackPageSize.height,
        );
        final geometry = DocumentPageMarginGuideGeometry.fromSettings(
          pageSettings: pageSettings,
          surfaceSize: surfaceSize,
        );
        final thickness = math.max(0.5, guideThickness);

        return SizedBox(
          key: guidesKey,
          width: surfaceSize.width,
          height: surfaceSize.height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(child: child),
              IgnorePointer(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned(
                      top: _linePosition(
                        geometry.topGuideY,
                        surfaceSize.height,
                        thickness,
                      ),
                      left: 0,
                      right: 0,
                      height: thickness,
                      child: _MarginGuideLine(
                        key: topGuideKey,
                        axis: Axis.horizontal,
                        color: guideColor,
                      ),
                    ),
                    Positioned(
                      left: _linePosition(
                        geometry.rightGuideX,
                        surfaceSize.width,
                        thickness,
                      ),
                      top: 0,
                      bottom: 0,
                      width: thickness,
                      child: _MarginGuideLine(
                        key: rightGuideKey,
                        axis: Axis.vertical,
                        color: guideColor,
                      ),
                    ),
                    Positioned(
                      top: _linePosition(
                        geometry.bottomGuideY,
                        surfaceSize.height,
                        thickness,
                      ),
                      left: 0,
                      right: 0,
                      height: thickness,
                      child: _MarginGuideLine(
                        key: bottomGuideKey,
                        axis: Axis.horizontal,
                        color: guideColor,
                      ),
                    ),
                    Positioned(
                      left: _linePosition(
                        geometry.leftGuideX,
                        surfaceSize.width,
                        thickness,
                      ),
                      top: 0,
                      bottom: 0,
                      width: thickness,
                      child: _MarginGuideLine(
                        key: leftGuideKey,
                        axis: Axis.vertical,
                        color: guideColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static double _linePosition(
    double coordinate,
    double extent,
    double thickness,
  ) {
    final maxPosition = math.max(0.0, extent - thickness);
    return coordinate.clamp(0.0, maxPosition).toDouble();
  }
}

/// Draws one subtly tinted margin guide line.
class _MarginGuideLine extends StatelessWidget {
  final Axis axis;
  final Color color;

  const _MarginGuideLine({super.key, required this.axis, required this.color});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(1);

    return DecoratedBox(
      decoration: BoxDecoration(color: color, borderRadius: radius),
      child: SizedBox(
        width: axis == Axis.vertical ? double.infinity : null,
        height: axis == Axis.horizontal ? double.infinity : null,
      ),
    );
  }
}
