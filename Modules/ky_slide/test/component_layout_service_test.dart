import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/models/component.dart';
import 'package:ky_slide/models/component_arrange_action.dart';
import 'package:ky_slide/models/presentation.dart';
import 'package:ky_slide/models/presentation_component.dart';
import 'package:ky_slide/models/slide.dart';
import 'package:ky_slide/models/style/presentation_theme.dart';
import 'package:ky_slide/services/component_layout_service.dart';
import 'package:ky_slide/states/presentation_provider.dart';

void main() {
  test('centers a component on the slide', () {
    final arranged = ComponentLayoutService.arrange(
      component: _component(position: const Offset(20, 30)),
      slideSize: const Size(1000, 600),
      action: ComponentArrangeAction.centerOnSlide,
    );

    expect(arranged.position, const Offset(400, 250));
  });

  test('aligns to slide edges', () {
    final component = _component(position: const Offset(120, 140));

    expect(
      ComponentLayoutService.arrange(
        component: component,
        slideSize: const Size(1000, 600),
        action: ComponentArrangeAction.alignRight,
      ).position,
      const Offset(800, 140),
    );
    expect(
      ComponentLayoutService.arrange(
        component: component,
        slideSize: const Size(1000, 600),
        action: ComponentArrangeAction.alignBottom,
      ).position,
      const Offset(120, 500),
    );
  });

  test('snaps to grid and keeps the component inside the slide', () {
    final arranged = ComponentLayoutService.arrange(
      component: _component(position: const Offset(987, 590)),
      slideSize: const Size(1000, 600),
      action: ComponentArrangeAction.snapToGrid,
      gridSize: 20,
    );

    expect(arranged.position, const Offset(800, 500));
  });

  test('moves a component by delta while staying inside the slide', () {
    final moved = ComponentLayoutService.moveBy(
      component: _component(position: const Offset(10, 12)),
      slideSize: const Size(1000, 600),
      delta: const Offset(-50, 700),
    );

    expect(moved.position, const Offset(0, 500));
  });

  test('moves a component with grid snapping when requested', () {
    final moved = ComponentLayoutService.moveBy(
      component: _component(position: const Offset(43, 47)),
      slideSize: const Size(1000, 600),
      delta: const Offset(20, 0),
      snapToGrid: true,
      gridSize: 20,
    );

    expect(moved.position, const Offset(60, 40));
  });

  test('updates frame values while clamping to slide bounds', () {
    final updated = ComponentLayoutService.updateFrame(
      component: _component(position: const Offset(40, 50)),
      slideSize: const Size(1000, 600),
      x: 980,
      y: -20,
      width: 300,
      height: 700,
      rotation: -30,
    );

    expect(updated.position, const Offset(700, 0));
    expect(updated.size, const Size(300, 600));
    expect(updated.rotation, 330);
  });

  test('rotates a component in quarter-turn steps', () {
    final component = _component(
      position: const Offset(120, 140),
    ).copyWith(rotation: 315);

    expect(
      ComponentLayoutService.arrange(
        component: component,
        slideSize: const Size(1000, 600),
        action: ComponentArrangeAction.rotateRight,
      ).rotation,
      45,
    );
    expect(
      ComponentLayoutService.arrange(
        component: component,
        slideSize: const Size(1000, 600),
        action: ComponentArrangeAction.rotateLeft,
      ).rotation,
      225,
    );
  });

  test('provider arranges the matching component on the current slide', () {
    final notifier = PresentationNotifier(initialPresentation: _presentation());

    notifier.arrangeComponent('selected', ComponentArrangeAction.alignLeft);

    final component = notifier.state.slides.first.components.first;
    expect(component.position.dx, 0);
    expect(component.position.dy, 88);
  });
}

PresentationComponent _component({required Offset position}) {
  return PresentationComponent(
    id: 'selected',
    type: ComponentType.shape,
    position: position,
    size: const Size(200, 100),
  );
}

Presentation _presentation() {
  return Presentation(
    id: 'layout-test',
    title: 'Layout Test',
    slides: [
      Slide(
        id: 'slide-a',
        components: [_component(position: const Offset(96, 88))],
      ),
    ],
    theme: PresentationTheme(
      id: 'test-theme',
      name: 'Test Theme',
      primaryColor: const Color(0xFF2563EB),
      secondaryColor: const Color(0xFF14B8A6),
      backgroundColor: const Color(0xFF0F172A),
      textColor: Colors.white,
      titleStyle: const TextStyle(color: Colors.white, fontSize: 48),
      bodyStyle: const TextStyle(color: Colors.white70, fontSize: 20),
      colorPalette: const [Color(0xFF2563EB), Color(0xFF14B8A6)],
    ),
    slideSize: const Size(1000, 600),
  );
}
