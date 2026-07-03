import 'dart:math' as math;
import 'dart:ui';

import '../models/component_arrange_action.dart';
import '../models/presentation_component.dart';

class ComponentLayoutService {
  const ComponentLayoutService._();

  static PresentationComponent arrange({
    required PresentationComponent component,
    required Size slideSize,
    required ComponentArrangeAction action,
    double gridSize = 20,
  }) {
    if (action == ComponentArrangeAction.rotateLeft) {
      return component.copyWith(
        rotation: _normalizeRotation(component.rotation - 90),
      );
    }

    if (action == ComponentArrangeAction.rotateRight) {
      return component.copyWith(
        rotation: _normalizeRotation(component.rotation + 90),
      );
    }

    final position = switch (action) {
      ComponentArrangeAction.alignLeft => Offset(0, component.position.dy),
      ComponentArrangeAction.alignHorizontalCenter => Offset(
        (slideSize.width - component.size.width) / 2,
        component.position.dy,
      ),
      ComponentArrangeAction.alignRight => Offset(
        slideSize.width - component.size.width,
        component.position.dy,
      ),
      ComponentArrangeAction.alignTop => Offset(component.position.dx, 0),
      ComponentArrangeAction.alignVerticalCenter => Offset(
        component.position.dx,
        (slideSize.height - component.size.height) / 2,
      ),
      ComponentArrangeAction.alignBottom => Offset(
        component.position.dx,
        slideSize.height - component.size.height,
      ),
      ComponentArrangeAction.centerOnSlide => Offset(
        (slideSize.width - component.size.width) / 2,
        (slideSize.height - component.size.height) / 2,
      ),
      ComponentArrangeAction.snapToGrid => _snapToGrid(
        component.position,
        gridSize: gridSize,
      ),
      ComponentArrangeAction.rotateLeft ||
      ComponentArrangeAction.rotateRight => component.position,
    };

    return component.copyWith(
      position: _clampPosition(
        position,
        componentSize: component.size,
        slideSize: slideSize,
      ),
    );
  }

  static PresentationComponent moveBy({
    required PresentationComponent component,
    required Size slideSize,
    required Offset delta,
    bool snapToGrid = false,
    double gridSize = 20,
  }) {
    final position = component.position + delta;
    final alignedPosition = snapToGrid
        ? _snapToGrid(position, gridSize: gridSize)
        : position;

    return component.copyWith(
      position: _clampPosition(
        alignedPosition,
        componentSize: component.size,
        slideSize: slideSize,
      ),
    );
  }

  static PresentationComponent updateFrame({
    required PresentationComponent component,
    required Size slideSize,
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
    double minSize = 8,
  }) {
    final safeMinSize = math.max(1.0, minSize);
    final nextWidth = _finiteOr(
      width,
      component.size.width,
    ).clamp(safeMinSize, math.max(safeMinSize, slideSize.width));
    final nextHeight = _finiteOr(
      height,
      component.size.height,
    ).clamp(safeMinSize, math.max(safeMinSize, slideSize.height));
    final nextSize = Size(nextWidth.toDouble(), nextHeight.toDouble());
    final nextPosition = Offset(
      _finiteOr(x, component.position.dx),
      _finiteOr(y, component.position.dy),
    );

    return component.copyWith(
      position: _clampPosition(
        nextPosition,
        componentSize: nextSize,
        slideSize: slideSize,
      ),
      size: nextSize,
      rotation: rotation == null
          ? component.rotation
          : _normalizeRotation(_finiteOr(rotation, component.rotation)),
    );
  }

  static Offset _snapToGrid(Offset position, {required double gridSize}) {
    final safeGrid = math.max(1.0, gridSize);

    return Offset(
      (position.dx / safeGrid).round() * safeGrid,
      (position.dy / safeGrid).round() * safeGrid,
    );
  }

  static Offset _clampPosition(
    Offset position, {
    required Size componentSize,
    required Size slideSize,
  }) {
    final maxX = math.max(0.0, slideSize.width - componentSize.width);
    final maxY = math.max(0.0, slideSize.height - componentSize.height);

    return Offset(
      position.dx.clamp(0.0, maxX).toDouble(),
      position.dy.clamp(0.0, maxY).toDouble(),
    );
  }

  static double _finiteOr(double? value, double fallback) {
    return value == null || !value.isFinite ? fallback : value;
  }

  static double _normalizeRotation(double value) {
    final normalized = value % 360;
    return normalized < 0 ? normalized + 360 : normalized;
  }
}
