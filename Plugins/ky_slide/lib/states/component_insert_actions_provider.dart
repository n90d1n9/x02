import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart' show Colors;
import 'package:flutter_riverpod/flutter_riverpod.dart' show Provider, Ref;
import 'package:uuid/uuid.dart';

import '../models/chart_data.dart';
import '../models/component.dart';
import '../models/enums.dart';
import '../models/interactive_element.dart';
import '../models/presentation_component.dart';
import 'component_provider.dart';
import 'history_provider.dart';
import 'presentation_provider.dart';

final componentInsertActionsProvider = Provider<ComponentInsertActions>((ref) {
  return ComponentInsertActions(ref);
});

/// Creates insertable slide components and records undo history.
class ComponentInsertActions {
  final Ref ref;

  const ComponentInsertActions(this.ref);

  String addShape(ComponentType type) {
    final presentation = ref.read(presentationProvider);
    final component = PresentationComponent(
      id: const Uuid().v4(),
      type: type,
      position: const Offset(300, 300),
      size: const Size(200, 200),
      backgroundColor: presentation.theme.primaryColor,
    );

    return _insert(component, label: ComponentInsertActionLabels.addShape);
  }

  String addImage(Uint8List imageData) {
    final component = PresentationComponent(
      id: const Uuid().v4(),
      type: ComponentType.image,
      position: const Offset(300, 300),
      size: const Size(400, 300),
      imageData: imageData,
    );

    return _insert(component, label: ComponentInsertActionLabels.addImage);
  }

  String addVideo(String url) {
    final component = PresentationComponent(
      id: const Uuid().v4(),
      type: ComponentType.video,
      position: const Offset(300, 300),
      size: const Size(640, 360),
      videoUrl: url,
      backgroundColor: Colors.black,
    );

    return _insert(component, label: ComponentInsertActionLabels.addVideo);
  }

  String addChart(ChartType type) {
    final presentation = ref.read(presentationProvider);
    final chartData = ChartData(
      type: type,
      values: const [30, 50, 70, 40, 60],
      labels: const ['Q1', 'Q2', 'Q3', 'Q4', 'Q5'],
      colors: presentation.theme.colorPalette,
    );

    final component = PresentationComponent(
      id: const Uuid().v4(),
      type: ComponentType.chart,
      position: const Offset(300, 300),
      size: const Size(500, 350),
      chartData: chartData,
      backgroundColor: Colors.white.withValues(alpha: 0.05),
    );

    return _insert(component, label: ComponentInsertActionLabels.addChart);
  }

  String addInteractive(InteractiveType type) {
    final presentation = ref.read(presentationProvider);
    final interactive = InteractiveElement(
      id: const Uuid().v4(),
      type: type,
      label: type == InteractiveType.countdown ? '60' : 'Interactive Element',
      options: type == InteractiveType.poll || type == InteractiveType.quiz
          ? const ['Option 1', 'Option 2', 'Option 3']
          : null,
      duration: type == InteractiveType.countdown ? 60 : null,
    );

    final component = PresentationComponent(
      id: const Uuid().v4(),
      type: ComponentType.hotspot,
      position: const Offset(300, 300),
      size: const Size(300, 200),
      interactive: interactive,
      backgroundColor: presentation.theme.primaryColor.withValues(alpha: 0.2),
    );

    return _insert(
      component,
      label: ComponentInsertActionLabels.addInteractive,
    );
  }

  String _insert(PresentationComponent component, {required String label}) {
    ref.read(historyProvider.notifier).recordPresentationMutation((notifier) {
      notifier.addComponent(component);
    }, label: label);

    ref.read(selectedComponentProvider.notifier).state = component.id;
    return component.id;
  }
}

class ComponentInsertActionLabels {
  static const addChart = 'Add chart';
  static const addImage = 'Add image';
  static const addInteractive = 'Add interactive';
  static const addShape = 'Add shape';
  static const addVideo = 'Add video';

  const ComponentInsertActionLabels._();
}
