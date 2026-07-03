import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/models/alignment_guide.dart';
import 'package:ky_slide/models/component.dart';
import 'package:ky_slide/models/enums.dart';
import 'package:ky_slide/models/presentation_component.dart';
import 'package:ky_slide/services/alignment_guide_service.dart';

void main() {
  test('resolves slide center guides for the moving component', () {
    final component = _component(
      id: 'moving',
      position: const Offset(270, 40),
      size: const Size(100, 60),
    );

    final guides = AlignmentGuideService.resolve(
      component: component,
      components: [component],
      slideSize: const Size(640, 360),
    );

    expect(guides, hasLength(1));
    expect(guides.single.axis, AlignmentGuideAxis.vertical);
    expect(guides.single.source, AlignmentGuideSource.slide);
    expect(guides.single.position, 320);
  });

  test('resolves object edge guides within tolerance', () {
    final component = _component(
      id: 'moving',
      position: const Offset(280, 82),
      size: const Size(100, 60),
    );
    final target = _component(
      id: 'target',
      position: const Offset(160, 80),
      size: const Size(120, 70),
    );

    final guides = AlignmentGuideService.resolve(
      component: component,
      components: [component, target],
      slideSize: const Size(640, 360),
    );

    expect(
      guides.where((guide) => guide.axis == AlignmentGuideAxis.vertical),
      isNotEmpty,
    );
    expect(
      guides.where((guide) => guide.axis == AlignmentGuideAxis.horizontal),
      isNotEmpty,
    );
    expect(
      guides.every((guide) => guide.source == AlignmentGuideSource.object),
      isTrue,
    );
  });

  test('ignores hidden objects when resolving guides', () {
    final component = _component(
      id: 'moving',
      position: const Offset(280, 82),
      size: const Size(100, 60),
    );
    final hiddenTarget = _component(
      id: 'target',
      position: const Offset(160, 80),
      size: const Size(120, 70),
      isVisible: false,
    );

    final guides = AlignmentGuideService.resolve(
      component: component,
      components: [component, hiddenTarget],
      slideSize: const Size(640, 360),
    );

    expect(guides, isEmpty);
  });

  test('snaps moving component to the slide center guide', () {
    final component = _component(
      id: 'moving',
      position: const Offset(268, 40),
      size: const Size(100, 60),
    );

    final result = AlignmentGuideService.snapMove(
      component: component,
      components: [component],
      slideSize: const Size(640, 360),
    );

    expect(result.component.position.dx, 270);
    expect(
      result.guides.any((guide) {
        return guide.axis == AlignmentGuideAxis.vertical &&
            guide.source == AlignmentGuideSource.slide &&
            guide.position == 320;
      }),
      isTrue,
    );
  });

  test('snaps moving component to a neighboring object edge', () {
    final component = _component(
      id: 'moving',
      position: const Offset(276, 92),
      size: const Size(100, 60),
    );
    final target = _component(
      id: 'target',
      position: const Offset(160, 80),
      size: const Size(120, 70),
    );

    final result = AlignmentGuideService.snapMove(
      component: component,
      components: [component, target],
      slideSize: const Size(640, 360),
    );

    expect(result.component.position.dx, 280);
    expect(
      result.guides.any((guide) {
        return guide.axis == AlignmentGuideAxis.vertical &&
            guide.source == AlignmentGuideSource.object &&
            guide.position == 280;
      }),
      isTrue,
    );
  });

  test('does not snap moving component outside tolerance', () {
    final component = _component(
      id: 'moving',
      position: const Offset(260, 40),
      size: const Size(100, 60),
    );

    final result = AlignmentGuideService.snapMove(
      component: component,
      components: [component],
      slideSize: const Size(640, 360),
    );

    expect(result.component.position.dx, 260);
    expect(result.guides, isEmpty);
  });

  test('snaps the resized right edge to a neighboring object edge', () {
    final component = _component(
      id: 'moving',
      position: const Offset(100, 40),
      size: const Size(258, 60),
    );
    final target = _component(
      id: 'target',
      position: const Offset(360, 80),
      size: const Size(120, 70),
    );

    final result = AlignmentGuideService.snapResize(
      component: component,
      handle: ResizeHandle.right,
      components: [component, target],
      slideSize: const Size(640, 360),
    );

    expect(result.component.position.dx, 100);
    expect(result.component.size.width, 260);
    expect(
      result.guides.any((guide) {
        return guide.axis == AlignmentGuideAxis.vertical &&
            guide.source == AlignmentGuideSource.object &&
            guide.position == 360;
      }),
      isTrue,
    );
  });

  test('snaps the resized top-left corner to slide center guides', () {
    final component = _component(
      id: 'moving',
      position: const Offset(322, 182),
      size: const Size(100, 80),
    );

    final result = AlignmentGuideService.snapResize(
      component: component,
      handle: ResizeHandle.topLeft,
      components: [component],
      slideSize: const Size(640, 360),
    );

    expect(result.component.position, const Offset(320, 180));
    expect(result.component.size, const Size(102, 82));
    expect(
      result.guides.where(
        (guide) => guide.source == AlignmentGuideSource.slide,
      ),
      hasLength(2),
    );
  });

  test('does not snap resized edge below minimum size', () {
    final component = _component(
      id: 'moving',
      position: const Offset(316, 40),
      size: const Size(50, 60),
    );

    final result = AlignmentGuideService.snapResize(
      component: component,
      handle: ResizeHandle.left,
      components: [component],
      slideSize: const Size(640, 360),
    );

    expect(result.component.position.dx, 316);
    expect(result.component.size.width, 50);
  });
}

PresentationComponent _component({
  required String id,
  required Offset position,
  required Size size,
  bool isVisible = true,
}) {
  return PresentationComponent(
    id: id,
    type: ComponentType.shape,
    position: position,
    size: size,
    isVisible: isVisible,
  );
}
