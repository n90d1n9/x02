import 'dart:math' as math;
import 'dart:ui';

/// Computes and normalizes rotation values for direct canvas manipulation.
class ComponentRotationService {
  static const double defaultSnapIncrement = 15;
  static const double defaultSnapTolerance = 2.5;
  static const double defaultHandleOffset = 40;

  const ComponentRotationService._();

  static double rotationFromHandleDrag({
    required Offset localPosition,
    required Size componentSize,
    double handleOffset = defaultHandleOffset,
    double snapIncrement = defaultSnapIncrement,
    double snapTolerance = defaultSnapTolerance,
  }) {
    final center = Offset(
      componentSize.width / 2,
      componentSize.height / 2 + handleOffset,
    );
    final angle = math.atan2(
      localPosition.dy - center.dy,
      localPosition.dx - center.dx,
    );

    return magneticSnap(
      (angle * 180 / math.pi) + 90,
      increment: snapIncrement,
      tolerance: snapTolerance,
    );
  }

  static double magneticSnap(
    double degrees, {
    double increment = defaultSnapIncrement,
    double tolerance = defaultSnapTolerance,
  }) {
    final normalized = normalize(degrees);
    final safeIncrement = increment.isFinite && increment > 0
        ? increment
        : defaultSnapIncrement;
    final safeTolerance = tolerance.isFinite && tolerance >= 0
        ? tolerance
        : defaultSnapTolerance;
    final snapped = normalize(
      (normalized / safeIncrement).round() * safeIncrement,
    );

    return _circularDistance(normalized, snapped) <= safeTolerance
        ? snapped
        : normalized;
  }

  static double normalize(double degrees) {
    if (!degrees.isFinite) return 0;

    final normalized = degrees % 360;
    return normalized < 0 ? normalized + 360 : normalized;
  }

  static double _circularDistance(double a, double b) {
    final distance = (normalize(a) - normalize(b)).abs();
    return math.min(distance, 360 - distance);
  }
}
