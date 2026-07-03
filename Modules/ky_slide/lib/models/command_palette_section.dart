import 'command_palette_action.dart';

/// A display group of related command palette actions.
class CommandPaletteSection {
  final String title;
  final List<CommandPaletteAction> actions;

  const CommandPaletteSection({required this.title, required this.actions});
}
