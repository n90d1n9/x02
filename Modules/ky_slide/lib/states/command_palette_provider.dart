import 'package:flutter_riverpod/legacy.dart';

final commandPaletteRecentCommandIdsProvider =
    StateNotifierProvider<CommandPaletteRecentCommandsNotifier, List<String>>((
      ref,
    ) {
      return CommandPaletteRecentCommandsNotifier();
    });

/// Maintains a small in-memory list of recently invoked command IDs.
class CommandPaletteRecentCommandsNotifier extends StateNotifier<List<String>> {
  static const maxRecentCommandCount = 6;

  CommandPaletteRecentCommandsNotifier() : super(const []);

  void record(String commandId) {
    final normalizedId = commandId.trim();
    if (normalizedId.isEmpty) return;

    state = [
      normalizedId,
      ...state.where((id) => id != normalizedId),
    ].take(maxRecentCommandCount).toList(growable: false);
  }

  void clear() {
    state = const [];
  }
}
