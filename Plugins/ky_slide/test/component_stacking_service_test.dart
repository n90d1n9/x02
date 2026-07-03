import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/models/component.dart';
import 'package:ky_slide/models/presentation_component.dart';
import 'package:ky_slide/services/component_stacking_service.dart';

void main() {
  test('moveForward moves the selected component one visual layer up', () {
    const service = ComponentStackingService();

    final components = service.moveForward([
      _component(id: 'background', zIndex: 0),
      _component(id: 'title', zIndex: 10),
      _component(id: 'badge', zIndex: 30),
    ], 'title');

    expect(_zIndexFor(components, 'background'), 0);
    expect(_zIndexFor(components, 'badge'), 1);
    expect(_zIndexFor(components, 'title'), 2);
  });

  test('moveBackward moves the selected component one visual layer down', () {
    const service = ComponentStackingService();

    final components = service.moveBackward([
      _component(id: 'background', zIndex: 0),
      _component(id: 'title', zIndex: 10),
      _component(id: 'badge', zIndex: 30),
    ], 'title');

    expect(_zIndexFor(components, 'title'), 0);
    expect(_zIndexFor(components, 'background'), 1);
    expect(_zIndexFor(components, 'badge'), 2);
  });

  test(
    'moveForward returns the same list when the layer is already on top',
    () {
      const service = ComponentStackingService();
      final components = [
        _component(id: 'background', zIndex: 0),
        _component(id: 'title', zIndex: 10),
      ];

      expect(service.moveForward(components, 'title'), same(components));
    },
  );

  test('reorderTopToBottom assigns visual stack order from layer list', () {
    const service = ComponentStackingService();

    final components = service.reorderTopToBottom(
      [
        _component(id: 'background', zIndex: 0),
        _component(id: 'title', zIndex: 10),
        _component(id: 'badge', zIndex: 30),
      ],
      ['title', 'badge', 'background'],
    );

    expect(_zIndexFor(components, 'title'), 2);
    expect(_zIndexFor(components, 'badge'), 1);
    expect(_zIndexFor(components, 'background'), 0);
  });

  test('reorderTopToBottom ignores incomplete layer lists', () {
    const service = ComponentStackingService();
    final components = [
      _component(id: 'background', zIndex: 0),
      _component(id: 'title', zIndex: 10),
    ];

    expect(service.reorderTopToBottom(components, ['title']), same(components));
  });
}

PresentationComponent _component({required String id, required int zIndex}) {
  return PresentationComponent(
    id: id,
    type: ComponentType.shape,
    position: Offset.zero,
    size: const Size(100, 80),
    zIndex: zIndex,
  );
}

int _zIndexFor(List<PresentationComponent> components, String id) {
  return components.firstWhere((component) => component.id == id).zIndex;
}
