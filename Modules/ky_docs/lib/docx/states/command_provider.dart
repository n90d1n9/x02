import 'package:flutter_riverpod/legacy.dart';

import '../../docx/models/slash_menu_state.dart';

final themeProvider = StateProvider<bool>((ref) => false);
final toolbarVisibilityProvider = StateProvider<bool>((ref) => true);
final focusModeProvider = StateProvider<bool>((ref) => false);
final commandPaletteProvider = StateProvider<bool>((ref) => false);
final slashMenuProvider = StateProvider<SlashMenuState?>((ref) => null);
