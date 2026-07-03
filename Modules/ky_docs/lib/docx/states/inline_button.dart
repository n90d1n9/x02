import 'dart:ui';

import 'package:flutter_riverpod/legacy.dart';

final showInlineButtonsProvider = StateProvider<bool>((ref) => false);
final inlineButtonPositionProvider = StateProvider<Offset>(
  (ref) => Offset.zero,
);
final chatPanelProvider = StateProvider<bool>((ref) => false);
