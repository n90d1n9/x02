import 'dart:ui';

import 'package:flutter_riverpod/legacy.dart';

final layoutModeProvider = StateProvider<LayoutMode>((ref) => LayoutMode.web);

final rulerVisibilityProvider = StateProvider<bool>((ref) => true);

final widgetGalleryProvider = StateProvider<bool>((ref) => false);

final cursorPositionProvider = StateProvider<Offset>((ref) => Offset.zero);

enum LayoutMode { web, print, focus }
