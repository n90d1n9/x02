import 'dart:ui';

import 'package:flutter_riverpod/legacy.dart';

import '../models/editor_ribbon_tab.dart';

final activeRibbonTabProvider = StateProvider<EditorRibbonTab>((ref) {
  return EditorRibbonTab.home;
});

final speakerNotesVisibleProvider = StateProvider<bool>((ref) => true);

final slideNavigatorVisibleProvider = StateProvider<bool>((ref) => true);

final propertiesPanelVisibleProvider = StateProvider<bool>((ref) => true);

final slideSorterVisibleProvider = StateProvider<bool>((ref) => false);

final commandPaletteVisibleProvider = StateProvider<bool>((ref) => false);

final canvasViewportSizeProvider = StateProvider<Size>((ref) => Size.zero);
