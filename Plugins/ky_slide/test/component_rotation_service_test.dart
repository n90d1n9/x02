import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/services/component_rotation_service.dart';

void main() {
  test('normalize keeps rotation in a positive 0 to 360 degree range', () {
    expect(ComponentRotationService.normalize(-15), 345);
    expect(ComponentRotationService.normalize(390), 30);
    expect(ComponentRotationService.normalize(double.nan), 0);
  });

  test('magneticSnap snaps angles near clean increments', () {
    expect(ComponentRotationService.magneticSnap(13), 15);
    expect(ComponentRotationService.magneticSnap(358.5), 0);
  });

  test('magneticSnap preserves angles outside the tolerance band', () {
    expect(ComponentRotationService.magneticSnap(11), 11);
    expect(
      ComponentRotationService.magneticSnap(42, increment: 15, tolerance: 1),
      42,
    );
  });

  test(
    'rotationFromHandleDrag derives snapped angles from handle movement',
    () {
      const componentSize = Size(100, 60);

      expect(
        ComponentRotationService.rotationFromHandleDrag(
          localPosition: const Offset(50, -30),
          componentSize: componentSize,
        ),
        0,
      );
      expect(
        ComponentRotationService.rotationFromHandleDrag(
          localPosition: const Offset(150, 70),
          componentSize: componentSize,
        ),
        90,
      );
    },
  );
}
