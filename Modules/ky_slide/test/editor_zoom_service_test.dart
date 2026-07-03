import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/services/editor_zoom_service.dart';

void main() {
  test('clamp keeps zoom inside editor limits', () {
    expect(EditorZoomService.clamp(0.1), EditorZoomService.minZoom);
    expect(EditorZoomService.clamp(4), EditorZoomService.maxZoom);
    expect(EditorZoomService.clamp(1.25), 1.25);
  });

  test('label formats clamped zoom as a percentage', () {
    expect(EditorZoomService.label(1.25), '125%');
    expect(EditorZoomService.label(4), '300%');
  });

  test('fitToWindow calculates a padded viewport fit zoom', () {
    final zoom = EditorZoomService.fitToWindow(
      slideSize: const Size(1920, 1080),
      viewportSize: const Size(1056, 636),
    );

    expect(zoom, 0.5);
  });

  test(
    'fitToWindow falls back for unavailable geometry and clamps extremes',
    () {
      expect(
        EditorZoomService.fitToWindow(
          slideSize: const Size(1920, 1080),
          viewportSize: Size.zero,
        ),
        1,
      );
      expect(
        EditorZoomService.fitToWindow(
          slideSize: const Size(1920, 1080),
          viewportSize: const Size(10000, 10000),
        ),
        EditorZoomService.maxZoom,
      );
    },
  );
}
