import 'dart:math' as math;
import 'dart:ui';

/// Shared zoom calculations for editor viewport controls and tests.
class EditorZoomService {
  static const double minZoom = 0.25;
  static const double maxZoom = 3;
  static const double fitPadding = 96;

  const EditorZoomService._();

  static double clamp(double zoom) {
    return zoom.clamp(minZoom, maxZoom).toDouble();
  }

  static String label(double zoom) {
    return '${(clamp(zoom) * 100).round()}%';
  }

  static double fitToWindow({
    required Size slideSize,
    required Size viewportSize,
    double padding = fitPadding,
    double fallbackZoom = 1,
  }) {
    if (slideSize.width <= 0 ||
        slideSize.height <= 0 ||
        viewportSize.width <= 0 ||
        viewportSize.height <= 0) {
      return clamp(fallbackZoom);
    }

    final availableWidth = math.max(0, viewportSize.width - padding);
    final availableHeight = math.max(0, viewportSize.height - padding);

    if (availableWidth <= 0 || availableHeight <= 0) {
      return clamp(fallbackZoom);
    }

    return clamp(
      math.min(
        availableWidth / slideSize.width,
        availableHeight / slideSize.height,
      ),
    );
  }
}
