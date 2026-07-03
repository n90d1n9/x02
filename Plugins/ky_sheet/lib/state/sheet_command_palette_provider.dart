import 'package:flutter_riverpod/legacy.dart';

import '../model/sheet_command.dart';

final recentSheetCommandIdsProvider =
    StateNotifierProvider<RecentSheetCommandNotifier, List<String>>(
      (ref) => RecentSheetCommandNotifier(),
    );

class RecentSheetCommandNotifier extends StateNotifier<List<String>> {
  RecentSheetCommandNotifier() : super(const []);

  static const maxRecentCommands = 6;

  void record(SheetCommand command) {
    state = [
      command.id,
      for (final id in state)
        if (id != command.id) id,
    ].take(maxRecentCommands).toList();
  }

  List<SheetCommand> resolve(Iterable<SheetCommand> commands) {
    final commandsById = {for (final command in commands) command.id: command};
    return [
      for (final id in state)
        if (commandsById[id] != null) commandsById[id]!,
    ];
  }

  void clear() {
    state = const [];
  }
}
