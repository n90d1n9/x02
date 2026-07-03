import 'dart:ui';

import '../models/alignment_guide.dart';
import '../models/alignment_snap_result.dart';
import '../models/enums.dart';
import '../models/presentation_component.dart';

/// Computes smart alignment guide lines and snapping for a selected component frame.
class AlignmentGuideService {
  static const double defaultTolerance = 5;

  const AlignmentGuideService._();

  static AlignmentSnapResult snapMove({
    required PresentationComponent component,
    required Iterable<PresentationComponent> components,
    required Size slideSize,
    double tolerance = defaultTolerance,
  }) {
    final rect = Rect.fromLTWH(
      component.position.dx,
      component.position.dy,
      component.size.width,
      component.size.height,
    );
    final snapDelta = Offset(
      _bestSnapDelta(
        axis: AlignmentGuideAxis.vertical,
        component: component,
        components: components,
        rect: rect,
        slideSize: slideSize,
        tolerance: tolerance,
      ),
      _bestSnapDelta(
        axis: AlignmentGuideAxis.horizontal,
        component: component,
        components: components,
        rect: rect,
        slideSize: slideSize,
        tolerance: tolerance,
      ),
    );
    final snappedComponent = snapDelta == Offset.zero
        ? component
        : component.copyWith(position: component.position + snapDelta);

    return AlignmentSnapResult(
      component: snappedComponent,
      guides: resolve(
        component: snappedComponent,
        components: components,
        slideSize: slideSize,
        tolerance: tolerance,
      ),
    );
  }

  /// Snaps the actively resized edge of a component to nearby guide targets.
  static AlignmentSnapResult snapResize({
    required PresentationComponent component,
    required ResizeHandle handle,
    required Iterable<PresentationComponent> components,
    required Size slideSize,
    double minSize = 50,
    double tolerance = defaultTolerance,
  }) {
    final rect = Rect.fromLTWH(
      component.position.dx,
      component.position.dy,
      component.size.width,
      component.size.height,
    );
    var left = rect.left;
    var top = rect.top;
    var width = rect.width;
    var height = rect.height;

    if (_resizesLeft(handle)) {
      final delta = _bestSnapDeltaForAnchor(
        axis: AlignmentGuideAxis.vertical,
        anchor: rect.left,
        component: component,
        components: components,
        slideSize: slideSize,
        tolerance: tolerance,
      );
      if (delta != 0 && width - delta >= minSize) {
        left += delta;
        width -= delta;
      }
    } else if (_resizesRight(handle)) {
      final delta = _bestSnapDeltaForAnchor(
        axis: AlignmentGuideAxis.vertical,
        anchor: rect.right,
        component: component,
        components: components,
        slideSize: slideSize,
        tolerance: tolerance,
      );
      if (delta != 0 && width + delta >= minSize) {
        width += delta;
      }
    }

    if (_resizesTop(handle)) {
      final delta = _bestSnapDeltaForAnchor(
        axis: AlignmentGuideAxis.horizontal,
        anchor: rect.top,
        component: component,
        components: components,
        slideSize: slideSize,
        tolerance: tolerance,
      );
      if (delta != 0 && height - delta >= minSize) {
        top += delta;
        height -= delta;
      }
    } else if (_resizesBottom(handle)) {
      final delta = _bestSnapDeltaForAnchor(
        axis: AlignmentGuideAxis.horizontal,
        anchor: rect.bottom,
        component: component,
        components: components,
        slideSize: slideSize,
        tolerance: tolerance,
      );
      if (delta != 0 && height + delta >= minSize) {
        height += delta;
      }
    }

    final snappedComponent = component.copyWith(
      position: Offset(left, top),
      size: Size(width, height),
    );

    return AlignmentSnapResult(
      component: snappedComponent,
      guides: resolve(
        component: snappedComponent,
        components: components,
        slideSize: slideSize,
        tolerance: tolerance,
      ),
    );
  }

  static List<AlignmentGuide> resolve({
    required PresentationComponent component,
    required Iterable<PresentationComponent> components,
    required Size slideSize,
    double tolerance = defaultTolerance,
  }) {
    final guides = <AlignmentGuide>[];
    final rect = Rect.fromLTWH(
      component.position.dx,
      component.position.dy,
      component.size.width,
      component.size.height,
    );

    _collectSlideGuides(
      guides: guides,
      rect: rect,
      slideSize: slideSize,
      tolerance: tolerance,
    );

    for (final other in components) {
      if (other.id == component.id || !other.isVisible) continue;

      _collectObjectGuides(
        guides: guides,
        movingRect: rect,
        targetRect: Rect.fromLTWH(
          other.position.dx,
          other.position.dy,
          other.size.width,
          other.size.height,
        ),
        tolerance: tolerance,
      );
    }

    guides.sort((a, b) {
      final axisCompare = a.axis.index.compareTo(b.axis.index);
      if (axisCompare != 0) return axisCompare;
      return a.position.compareTo(b.position);
    });

    return guides;
  }

  static void _collectSlideGuides({
    required List<AlignmentGuide> guides,
    required Rect rect,
    required Size slideSize,
    required double tolerance,
  }) {
    final slideCenterX = slideSize.width / 2;
    final slideCenterY = slideSize.height / 2;

    _addMatches(
      guides: guides,
      axis: AlignmentGuideAxis.vertical,
      source: AlignmentGuideSource.slide,
      label: 'Slide center',
      anchors: [rect.left, rect.center.dx, rect.right],
      target: slideCenterX,
      tolerance: tolerance,
    );
    _addMatches(
      guides: guides,
      axis: AlignmentGuideAxis.horizontal,
      source: AlignmentGuideSource.slide,
      label: 'Slide middle',
      anchors: [rect.top, rect.center.dy, rect.bottom],
      target: slideCenterY,
      tolerance: tolerance,
    );
  }

  static void _collectObjectGuides({
    required List<AlignmentGuide> guides,
    required Rect movingRect,
    required Rect targetRect,
    required double tolerance,
  }) {
    final movingXAnchors = [
      movingRect.left,
      movingRect.center.dx,
      movingRect.right,
    ];
    final movingYAnchors = [
      movingRect.top,
      movingRect.center.dy,
      movingRect.bottom,
    ];

    for (final target in [
      targetRect.left,
      targetRect.center.dx,
      targetRect.right,
    ]) {
      _addMatches(
        guides: guides,
        axis: AlignmentGuideAxis.vertical,
        source: AlignmentGuideSource.object,
        label: 'Object alignment',
        anchors: movingXAnchors,
        target: target,
        tolerance: tolerance,
      );
    }

    for (final target in [
      targetRect.top,
      targetRect.center.dy,
      targetRect.bottom,
    ]) {
      _addMatches(
        guides: guides,
        axis: AlignmentGuideAxis.horizontal,
        source: AlignmentGuideSource.object,
        label: 'Object alignment',
        anchors: movingYAnchors,
        target: target,
        tolerance: tolerance,
      );
    }
  }

  static void _addMatches({
    required List<AlignmentGuide> guides,
    required AlignmentGuideAxis axis,
    required AlignmentGuideSource source,
    required String label,
    required Iterable<double> anchors,
    required double target,
    required double tolerance,
  }) {
    for (final anchor in anchors) {
      if ((anchor - target).abs() > tolerance) continue;
      _addUniqueGuide(
        guides,
        AlignmentGuide(
          axis: axis,
          source: source,
          position: target,
          label: label,
        ),
      );
      return;
    }
  }

  static void _addUniqueGuide(
    List<AlignmentGuide> guides,
    AlignmentGuide guide,
  ) {
    final alreadyExists = guides.any((existing) {
      return existing.axis == guide.axis &&
          (existing.position - guide.position).abs() < 0.5;
    });
    if (!alreadyExists && guide.position.isFinite && !guide.position.isNaN) {
      guides.add(guide);
    }
  }

  static double _bestSnapDelta({
    required AlignmentGuideAxis axis,
    required PresentationComponent component,
    required Iterable<PresentationComponent> components,
    required Rect rect,
    required Size slideSize,
    required double tolerance,
  }) {
    final anchors = axis == AlignmentGuideAxis.vertical
        ? [rect.left, rect.center.dx, rect.right]
        : [rect.top, rect.center.dy, rect.bottom];
    final targets = _snapTargets(
      axis: axis,
      component: component,
      components: components,
      slideSize: slideSize,
    );

    _SnapCandidate? best;
    for (final anchor in anchors) {
      for (final target in targets) {
        final delta = target.position - anchor;
        final distance = delta.abs();
        if (distance > tolerance) continue;

        final candidate = _SnapCandidate(delta: delta, distance: distance);
        if (best == null || candidate.distance < best.distance) {
          best = candidate;
        }
      }
    }

    return best?.delta ?? 0;
  }

  static double _bestSnapDeltaForAnchor({
    required AlignmentGuideAxis axis,
    required double anchor,
    required PresentationComponent component,
    required Iterable<PresentationComponent> components,
    required Size slideSize,
    required double tolerance,
  }) {
    final targets = _snapTargets(
      axis: axis,
      component: component,
      components: components,
      slideSize: slideSize,
    );

    _SnapCandidate? best;
    for (final target in targets) {
      final delta = target.position - anchor;
      final distance = delta.abs();
      if (distance > tolerance) continue;

      final candidate = _SnapCandidate(delta: delta, distance: distance);
      if (best == null || candidate.distance < best.distance) {
        best = candidate;
      }
    }

    return best?.delta ?? 0;
  }

  static List<_SnapTarget> _snapTargets({
    required AlignmentGuideAxis axis,
    required PresentationComponent component,
    required Iterable<PresentationComponent> components,
    required Size slideSize,
  }) {
    final targets = <_SnapTarget>[
      _SnapTarget(
        axis == AlignmentGuideAxis.vertical
            ? slideSize.width / 2
            : slideSize.height / 2,
      ),
    ];

    for (final other in components) {
      if (other.id == component.id || !other.isVisible) continue;

      final rect = Rect.fromLTWH(
        other.position.dx,
        other.position.dy,
        other.size.width,
        other.size.height,
      );
      final positions = axis == AlignmentGuideAxis.vertical
          ? [rect.left, rect.center.dx, rect.right]
          : [rect.top, rect.center.dy, rect.bottom];

      targets.addAll(positions.map(_SnapTarget.new));
    }

    return targets;
  }

  static bool _resizesLeft(ResizeHandle handle) {
    return handle == ResizeHandle.left ||
        handle == ResizeHandle.topLeft ||
        handle == ResizeHandle.bottomLeft;
  }

  static bool _resizesRight(ResizeHandle handle) {
    return handle == ResizeHandle.right ||
        handle == ResizeHandle.topRight ||
        handle == ResizeHandle.bottomRight;
  }

  static bool _resizesTop(ResizeHandle handle) {
    return handle == ResizeHandle.top ||
        handle == ResizeHandle.topLeft ||
        handle == ResizeHandle.topRight;
  }

  static bool _resizesBottom(ResizeHandle handle) {
    return handle == ResizeHandle.bottom ||
        handle == ResizeHandle.bottomLeft ||
        handle == ResizeHandle.bottomRight;
  }
}

/// Possible target anchor for smart snapping on one axis.
class _SnapTarget {
  final double position;

  const _SnapTarget(this.position);
}

/// Candidate snap movement scored by distance from the guide target.
class _SnapCandidate {
  final double delta;
  final double distance;

  const _SnapCandidate({required this.delta, required this.distance});
}
