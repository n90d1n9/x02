import 'document_command.dart';

/// Identifies the currently active command palette result.
class DocumentCommandActiveResult {
  final DocumentCommand? command;
  final int index;
  final int totalCount;

  const DocumentCommandActiveResult({
    required this.command,
    required this.index,
    required this.totalCount,
  });

  factory DocumentCommandActiveResult.fromCommands(
    List<DocumentCommand> commands, {
    int preferredIndex = 0,
  }) {
    if (commands.isEmpty) {
      return const DocumentCommandActiveResult(
        command: null,
        index: -1,
        totalCount: 0,
      );
    }

    final activeIndex = preferredIndex.clamp(0, commands.length - 1).toInt();
    return DocumentCommandActiveResult(
      command: commands[activeIndex],
      index: activeIndex,
      totalCount: commands.length,
    );
  }

  bool get hasCommand => command != null;

  bool get canRun => command?.enabled ?? false;

  DocumentCommand? get runnableCommand => canRun ? command : null;

  String? get commandId => command?.id;

  bool get canMove => totalCount > 1;

  int get nextIndex {
    if (!hasCommand) return 0;
    return (index + 1) % totalCount;
  }

  int get previousIndex {
    if (!hasCommand) return 0;
    return (index - 1 + totalCount) % totalCount;
  }
}
