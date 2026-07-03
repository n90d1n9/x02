import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/models/component.dart';
import 'package:ky_slide/models/enums.dart';
import 'package:ky_slide/models/presentation.dart';
import 'package:ky_slide/models/presentation_component.dart';
import 'package:ky_slide/models/slide.dart';
import 'package:ky_slide/models/style/presentation_theme.dart';
import 'package:ky_slide/states/component_insert_actions_provider.dart';
import 'package:ky_slide/states/component_provider.dart';
import 'package:ky_slide/states/history_provider.dart';
import 'package:ky_slide/states/presentation_provider.dart';

void main() {
  test('inserts components with defaults selection and history labels', () {
    final container = _container();
    addTearDown(container.dispose);

    final actions = container.read(componentInsertActionsProvider);

    final shapeId = actions.addShape(ComponentType.circle);
    var component = _components(container).last;
    expect(component.id, shapeId);
    expect(component.type, ComponentType.circle);
    expect(component.size, const Size(200, 200));
    expect(component.backgroundColor, const Color(0xFF2563EB));
    expect(container.read(selectedComponentProvider), shapeId);
    expect(container.read(historyProvider).undoLabel, 'Add shape');

    final chartId = actions.addChart(ChartType.bar);
    component = _components(container).last;
    expect(component.id, chartId);
    expect(component.type, ComponentType.chart);
    expect(component.chartData?.type, ChartType.bar);
    expect(component.chartData?.labels, ['Q1', 'Q2', 'Q3', 'Q4', 'Q5']);
    expect(container.read(selectedComponentProvider), chartId);
    expect(container.read(historyProvider).undoLabel, 'Add chart');

    final interactiveId = actions.addInteractive(InteractiveType.poll);
    component = _components(container).last;
    expect(component.id, interactiveId);
    expect(component.type, ComponentType.hotspot);
    expect(component.interactive?.type, InteractiveType.poll);
    expect(component.interactive?.options, hasLength(3));
    expect(container.read(selectedComponentProvider), interactiveId);
    expect(container.read(historyProvider).undoLabel, 'Add interactive');

    final imageBytes = Uint8List.fromList([1, 2, 3]);
    final imageId = actions.addImage(imageBytes);
    component = _components(container).last;
    expect(component.id, imageId);
    expect(component.type, ComponentType.image);
    expect(component.imageData, imageBytes);
    expect(container.read(selectedComponentProvider), imageId);
    expect(container.read(historyProvider).undoLabel, 'Add image');

    final videoId = actions.addVideo('https://example.com/video');
    component = _components(container).last;
    expect(component.id, videoId);
    expect(component.type, ComponentType.video);
    expect(component.videoUrl, 'https://example.com/video');
    expect(component.backgroundColor, Colors.black);
    expect(container.read(selectedComponentProvider), videoId);
    expect(container.read(historyProvider).undoLabel, 'Add video');
  });
}

ProviderContainer _container() {
  return ProviderContainer(
    overrides: [
      presentationProvider.overrideWith(
        (ref) => PresentationNotifier(initialPresentation: _presentation()),
      ),
    ],
  );
}

Presentation _presentation() {
  return Presentation(
    id: 'insert-actions-test',
    title: 'Insert Actions Test',
    slides: [
      Slide(
        id: 'slide',
        components: [
          PresentationComponent(
            id: 'title',
            type: ComponentType.richText,
            position: const Offset(40, 40),
            size: const Size(240, 80),
          ),
        ],
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
  );
}

List<PresentationComponent> _components(ProviderContainer container) {
  final presentation = container.read(presentationProvider);
  return presentation.slides[presentation.currentSlideIndex].components;
}
