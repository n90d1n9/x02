import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart' show Provider, Ref;

import '../models/component_arrange_action.dart';
import '../models/presentation_component.dart';
import '../services/component_layout_service.dart';
import 'component_provider.dart';
import 'history_provider.dart';
import 'presentation_provider.dart';

final componentLayerActionsProvider = Provider<ComponentLayerActions>((ref) {
  return ComponentLayerActions(ref);
});

class ComponentLayerActions {
  final Ref ref;

  const ComponentLayerActions(this.ref);

  String? get selectedLayerId => _validSelectedLayerId();

  String? duplicateSelectedLayer() {
    final selectedId = _validSelectedLayerId();
    if (selectedId == null) return null;

    String? duplicatedId;
    ref.read(historyProvider.notifier).recordPresentationMutation((notifier) {
      duplicatedId = notifier.duplicateComponent(selectedId);
    }, label: ComponentLayerActionLabels.duplicate);

    if (duplicatedId != null) {
      ref.read(selectedComponentProvider.notifier).state = duplicatedId;
    }

    return duplicatedId;
  }

  bool deleteSelectedLayer() {
    final selectedId = _validSelectedLayerId();
    if (selectedId == null) return false;

    final changed = _recordLayerMutation(
      selectedId,
      label: ComponentLayerActionLabels.delete,
      mutate: (notifier, componentId) {
        notifier.deleteComponent(componentId);
      },
    );

    if (changed) {
      ref.read(selectedComponentProvider.notifier).state = null;
    }

    return changed;
  }

  bool bringSelectedLayerToFront() {
    return _recordSelectedLayerMutation(
      label: ComponentLayerActionLabels.bringToFront,
      mutate: (notifier, componentId) {
        notifier.bringToFront(componentId);
      },
    );
  }

  bool moveSelectedLayerForward() {
    return _recordSelectedLayerMutation(
      label: ComponentLayerActionLabels.moveForward,
      mutate: (notifier, componentId) {
        notifier.moveComponentForward(componentId);
      },
    );
  }

  bool moveSelectedLayerBackward() {
    return _recordSelectedLayerMutation(
      label: ComponentLayerActionLabels.moveBackward,
      mutate: (notifier, componentId) {
        notifier.moveComponentBackward(componentId);
      },
    );
  }

  bool sendSelectedLayerToBack() {
    return _recordSelectedLayerMutation(
      label: ComponentLayerActionLabels.sendToBack,
      mutate: (notifier, componentId) {
        notifier.sendToBack(componentId);
      },
    );
  }

  bool reorderLayers(List<String> topToBottomIds) {
    final presentation = ref.read(presentationProvider);
    final currentSlide = presentation.slides[presentation.currentSlideIndex];
    if (topToBottomIds.length != currentSlide.components.length) {
      return false;
    }

    final currentIds = currentSlide.components.map((component) {
      return component.id;
    }).toSet();
    final orderedIds = topToBottomIds.toSet();
    if (currentIds.length != orderedIds.length ||
        !currentIds.containsAll(orderedIds)) {
      return false;
    }

    return _recordPresentationMutation(
      label: ComponentLayerActionLabels.reorder,
      mutate: (notifier) {
        notifier.reorderCurrentSlideComponentsTopToBottom(topToBottomIds);
      },
    );
  }

  bool arrangeSelectedLayer(ComponentArrangeAction action) {
    return _recordSelectedLayerMutation(
      label: ComponentLayerActionLabels.arrange,
      mutate: (notifier, componentId) {
        notifier.arrangeComponent(componentId, action);
      },
    );
  }

  bool nudgeSelectedLayer(Offset direction, {bool isLargeStep = false}) {
    if (direction == Offset.zero) return false;

    final selectedId = _validSelectedLayerId();
    if (selectedId == null) return false;

    final component = _currentComponent(selectedId);
    if (component == null || component.isLocked) return false;

    final snapToGrid = ref.read(snapToGridProvider);
    final gridSize = ref.read(canvasGridPresetProvider).spacing;
    final distance = snapToGrid
        ? (isLargeStep ? gridSize * 5 : gridSize)
        : (isLargeStep
              ? ComponentLayerActionSteps.largeNudge
              : ComponentLayerActionSteps.nudge);
    final delta = Offset(direction.dx * distance, direction.dy * distance);
    final presentation = ref.read(presentationProvider);
    final nudged = ComponentLayoutService.moveBy(
      component: component,
      slideSize: presentation.slideSize,
      delta: delta,
      snapToGrid: snapToGrid,
      gridSize: gridSize,
    );

    if (nudged.position == component.position) return false;

    return _recordLayerMutation(
      selectedId,
      label: ComponentLayerActionLabels.nudge,
      mutate: (notifier, componentId) {
        notifier.updateComponent(componentId, nudged);
      },
    );
  }

  bool showAllLayers() {
    return _recordPresentationMutation(
      label: ComponentLayerActionLabels.showAll,
      mutate: (notifier) {
        notifier.setCurrentSlideComponentsVisibility(true);
      },
    );
  }

  bool unlockAllLayers() {
    return _recordPresentationMutation(
      label: ComponentLayerActionLabels.unlockAll,
      mutate: (notifier) {
        notifier.setCurrentSlideComponentsLocked(false);
      },
    );
  }

  bool setLayerVisibility(String componentId, bool isVisible) {
    final component = _currentComponent(componentId);
    if (component == null || component.isVisible == isVisible) return false;

    return _recordLayerMutation(
      componentId,
      label: isVisible
          ? ComponentLayerActionLabels.show
          : ComponentLayerActionLabels.hide,
      mutate: (notifier, componentId) {
        notifier.setComponentVisibility(componentId, isVisible);
      },
    );
  }

  bool setLayerLocked(String componentId, bool isLocked) {
    final component = _currentComponent(componentId);
    if (component == null || component.isLocked == isLocked) return false;

    return _recordLayerMutation(
      componentId,
      label: isLocked
          ? ComponentLayerActionLabels.lock
          : ComponentLayerActionLabels.unlock,
      mutate: (notifier, componentId) {
        notifier.setComponentLocked(componentId, isLocked);
      },
    );
  }

  bool _recordSelectedLayerMutation({
    required String label,
    required void Function(PresentationNotifier notifier, String componentId)
    mutate,
  }) {
    final selectedId = _validSelectedLayerId();
    if (selectedId == null) return false;

    return _recordLayerMutation(selectedId, label: label, mutate: mutate);
  }

  bool _recordLayerMutation(
    String componentId, {
    required String label,
    required void Function(PresentationNotifier notifier, String componentId)
    mutate,
  }) {
    if (_currentComponent(componentId) == null) return false;

    return _recordPresentationMutation(
      label: label,
      mutate: (notifier) => mutate(notifier, componentId),
    );
  }

  bool _recordPresentationMutation({
    required String label,
    required void Function(PresentationNotifier notifier) mutate,
  }) {
    final before = ref.read(presentationProvider);
    ref
        .read(historyProvider.notifier)
        .recordPresentationMutation(mutate, label: label);

    return !identical(before, ref.read(presentationProvider));
  }

  String? _validSelectedLayerId() {
    final selectedId = ref.read(selectedComponentProvider);
    if (selectedId == null) return null;

    return _currentComponent(selectedId) == null ? null : selectedId;
  }

  PresentationComponent? _currentComponent(String componentId) {
    final presentation = ref.read(presentationProvider);
    final currentSlide = presentation.slides[presentation.currentSlideIndex];

    for (final component in currentSlide.components) {
      if (component.id == componentId) return component;
    }

    return null;
  }
}

class ComponentLayerActionLabels {
  static const arrange = 'Arrange layer';
  static const bringToFront = 'Bring layer to front';
  static const delete = 'Delete layer';
  static const duplicate = 'Duplicate layer';
  static const hide = 'Hide layer';
  static const lock = 'Lock layer';
  static const moveBackward = 'Move layer backward';
  static const moveForward = 'Move layer forward';
  static const nudge = 'Nudge layer';
  static const reorder = 'Reorder layers';
  static const sendToBack = 'Send layer to back';
  static const show = 'Show layer';
  static const showAll = 'Show all layers';
  static const unlock = 'Unlock layer';
  static const unlockAll = 'Unlock all layers';

  const ComponentLayerActionLabels._();
}

class ComponentLayerActionSteps {
  static const nudge = 1.0;
  static const largeNudge = 10.0;

  const ComponentLayerActionSteps._();
}
