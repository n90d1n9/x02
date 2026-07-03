import 'document_command.dart';

/// Groups filtered command palette actions by their display category.
class DocumentCommandSection {
  final String category;
  final List<DocumentCommand> commands;

  const DocumentCommandSection({
    required this.category,
    required this.commands,
  });

  static List<DocumentCommandSection> fromCommands(
    List<DocumentCommand> commands,
  ) {
    final orderedCategories = <String>[];
    final groupedCommands = <String, List<DocumentCommand>>{};

    for (final command in commands) {
      final category = command.category.trim().isEmpty
          ? 'General'
          : command.category.trim();
      groupedCommands
          .putIfAbsent(category, () {
            orderedCategories.add(category);
            return <DocumentCommand>[];
          })
          .add(command);
    }

    return [
      for (final category in orderedCategories)
        DocumentCommandSection(
          category: category,
          commands: List.unmodifiable(groupedCommands[category]!),
        ),
    ];
  }
}
