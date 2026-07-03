import 'document_command.dart';

/// Selects the highest-value commands for the palette suggestion strip.
class DocumentCommandSuggestions {
  const DocumentCommandSuggestions._();

  static List<DocumentCommand> fromCommands(
    List<DocumentCommand> commands, {
    int limit = 4,
  }) {
    final rankedCommands = [
      for (var index = 0; index < commands.length; index++)
        if (commands[index].suggested)
          _SuggestedCommand(command: commands[index], originalIndex: index),
    ]..sort(_compareCommands);

    return [
      for (final rankedCommand in rankedCommands.take(limit))
        rankedCommand.command,
    ];
  }

  static int _compareCommands(_SuggestedCommand a, _SuggestedCommand b) {
    final priorityComparison = b.command.suggestionPriority.compareTo(
      a.command.suggestionPriority,
    );
    if (priorityComparison != 0) return priorityComparison;

    final enabledComparison = _enabledWeight(
      b.command,
    ).compareTo(_enabledWeight(a.command));
    if (enabledComparison != 0) return enabledComparison;

    return a.originalIndex.compareTo(b.originalIndex);
  }

  static int _enabledWeight(DocumentCommand command) {
    return command.enabled ? 1 : 0;
  }
}

class _SuggestedCommand {
  final DocumentCommand command;
  final int originalIndex;

  const _SuggestedCommand({required this.command, required this.originalIndex});
}
