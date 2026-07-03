import 'dart:ui';

import 'package:flutter_riverpod/legacy.dart';

import '../models/canvas_grid_preset.dart';
import '../models/enums.dart';

final selectedComponentProvider = StateProvider<String?>((ref) => null);
final hoveredComponentProvider = StateProvider<String?>((ref) => null);
final presenterModeProvider = StateProvider<bool>((ref) => false);
final currentToolProvider = StateProvider<ToolMode>((ref) => ToolMode.select);
final rulerVisibilityProvider = StateProvider<bool>((ref) => true);
final showGridProvider = StateProvider<bool>((ref) => false);
final snapToGridProvider = StateProvider<bool>((ref) => false);
final canvasGridPresetProvider = StateProvider<CanvasGridPreset>((ref) {
  return CanvasGridPreset.comfortable;
});
final zoomLevelProvider = StateProvider<double>((ref) => 1.0);
final cursorPositionProvider = StateProvider<Offset>((ref) => Offset.zero);
final autoPlayProvider = StateProvider<bool>((ref) => false);
final autoPlayIntervalProvider = StateProvider<int>((ref) => 5);
