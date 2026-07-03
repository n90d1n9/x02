import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/models/canvas_grid_preset.dart';
import 'package:ky_slide/models/component.dart';
import 'package:ky_slide/models/presentation.dart';
import 'package:ky_slide/models/presentation_component.dart';
import 'package:ky_slide/models/rich_text_content.dart';
import 'package:ky_slide/models/slide.dart';
import 'package:ky_slide/models/style/presentation_theme.dart';
import 'package:ky_slide/states/component_layer_actions_provider.dart';
import 'package:ky_slide/states/component_provider.dart';
import 'package:ky_slide/states/history_provider.dart';
import 'package:ky_slide/states/presentation_provider.dart';

void main() {
  test('duplicates and deletes the selected layer with selection updates', () {
    final container = _container();
    addTearDown(container.dispose);

    container.read(selectedComponentProvider.notifier).state = 'title';
    final actions = container.read(componentLayerActionsProvider);

    final duplicateId = actions.duplicateSelectedLayer();
    var components = _components(container);
    final duplicate = components.firstWhere(
      (component) => component.id == duplicateId,
    );

    expect(duplicateId, isNotNull);
    expect(container.read(selectedComponentProvider), duplicateId);
    expect(components.length, 4);
    expect(duplicate.richText?.text, 'Quarterly update');
    expect(duplicate.position, const Offset(56, 56));
    expect(container.read(historyProvider).undoLabel, 'Duplicate layer');

    expect(actions.deleteSelectedLayer(), isTrue);

    components = _components(container);
    expect(components.map((component) => component.id), [
      'background',
      'title',
      'badge',
    ]);
    expect(container.read(selectedComponentProvider), isNull);
    expect(container.read(historyProvider).undoLabel, 'Delete layer');
  });

  test('ignores stale selections without recording history', () {
    final container = _container();
    addTearDown(container.dispose);

    container.read(selectedComponentProvider.notifier).state = 'missing';
    final actions = container.read(componentLayerActionsProvider);

    expect(actions.selectedLayerId, isNull);
    expect(actions.deleteSelectedLayer(), isFalse);
    expect(actions.duplicateSelectedLayer(), isNull);
    expect(actions.moveSelectedLayerForward(), isFalse);
    expect(_componentIds(container), ['background', 'title', 'badge']);
    expect(container.read(historyProvider).entries, isEmpty);
  });

  test('records visibility and lock changes only when state changes', () {
    final container = _container();
    addTearDown(container.dispose);

    final actions = container.read(componentLayerActionsProvider);

    expect(actions.setLayerVisibility('title', false), isTrue);
    expect(_component(container, 'title').isVisible, isFalse);
    expect(container.read(historyProvider).undoLabel, 'Hide layer');

    final historyLength = container.read(historyProvider).entries.length;
    expect(actions.setLayerVisibility('title', false), isFalse);
    expect(container.read(historyProvider).entries.length, historyLength);

    expect(actions.setLayerLocked('title', true), isTrue);
    expect(_component(container, 'title').isLocked, isTrue);
    expect(container.read(historyProvider).undoLabel, 'Lock layer');

    expect(actions.unlockAllLayers(), isTrue);
    expect(_component(container, 'title').isLocked, isFalse);
    expect(container.read(historyProvider).undoLabel, 'Unlock all layers');
  });

  test('moves the selected layer through the stack', () {
    final container = _container();
    addTearDown(container.dispose);

    container.read(selectedComponentProvider.notifier).state = 'title';
    final actions = container.read(componentLayerActionsProvider);

    expect(actions.moveSelectedLayerForward(), isTrue);
    expect(_component(container, 'title').zIndex, 2);
    expect(_component(container, 'badge').zIndex, 1);
    expect(container.read(historyProvider).undoLabel, 'Move layer forward');

    expect(actions.sendSelectedLayerToBack(), isTrue);
    expect(_component(container, 'title').zIndex, -1);
    expect(container.read(historyProvider).undoLabel, 'Send layer to back');
  });

  test('reorders layers from a top-to-bottom layer list', () {
    final container = _container();
    addTearDown(container.dispose);

    final actions = container.read(componentLayerActionsProvider);

    expect(actions.reorderLayers(['title', 'badge', 'background']), isTrue);
    expect(_component(container, 'title').zIndex, 2);
    expect(_component(container, 'badge').zIndex, 1);
    expect(_component(container, 'background').zIndex, 0);
    expect(container.read(historyProvider).undoLabel, 'Reorder layers');

    final historyLength = container.read(historyProvider).entries.length;
    expect(actions.reorderLayers(['title', 'badge']), isFalse);
    expect(container.read(historyProvider).entries.length, historyLength);
  });

  test('nudges the selected layer with bounds, snap, and lock handling', () {
    final container = _container();
    addTearDown(container.dispose);

    container.read(selectedComponentProvider.notifier).state = 'title';
    final actions = container.read(componentLayerActionsProvider);

    expect(actions.nudgeSelectedLayer(const Offset(1, 0)), isTrue);
    expect(_component(container, 'title').position, const Offset(41, 40));
    expect(container.read(historyProvider).undoLabel, 'Nudge layer');

    expect(
      actions.nudgeSelectedLayer(const Offset(0, 1), isLargeStep: true),
      isTrue,
    );
    expect(_component(container, 'title').position, const Offset(41, 50));

    container.read(snapToGridProvider.notifier).state = true;
    expect(actions.nudgeSelectedLayer(const Offset(1, 0)), isTrue);
    expect(_component(container, 'title').position, const Offset(60, 60));

    container.read(canvasGridPresetProvider.notifier).state =
        CanvasGridPreset.compact;
    expect(actions.nudgeSelectedLayer(const Offset(1, 0)), isTrue);
    expect(_component(container, 'title').position, const Offset(70, 60));

    final historyLength = container.read(historyProvider).entries.length;
    expect(actions.setLayerLocked('title', true), isTrue);
    expect(actions.nudgeSelectedLayer(const Offset(1, 0)), isFalse);
    expect(_component(container, 'title').position, const Offset(70, 60));
    expect(container.read(historyProvider).entries.length, historyLength + 1);
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
    id: 'layer-actions-test',
    title: 'Layer Actions Test',
    slides: [
      Slide(
        id: 'slide',
        components: [
          _shape(id: 'background', zIndex: 0),
          _text(id: 'title', text: 'Quarterly update', zIndex: 1),
          _shape(id: 'badge', type: ComponentType.circle, zIndex: 2),
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

List<String> _componentIds(ProviderContainer container) {
  return _components(container).map((component) => component.id).toList();
}

PresentationComponent _component(ProviderContainer container, String id) {
  return _components(container).firstWhere((component) => component.id == id);
}

PresentationComponent _shape({
  required String id,
  required int zIndex,
  ComponentType type = ComponentType.shape,
}) {
  return PresentationComponent(
    id: id,
    type: type,
    position: Offset.zero,
    size: const Size(100, 80),
    zIndex: zIndex,
  );
}

PresentationComponent _text({
  required String id,
  required String text,
  required int zIndex,
}) {
  return PresentationComponent(
    id: id,
    type: ComponentType.richText,
    position: const Offset(40, 40),
    size: const Size(240, 80),
    zIndex: zIndex,
    richText: RichTextContent(
      text: text,
      style: const TextStyle(color: Colors.white, fontSize: 24),
    ),
  );
}
