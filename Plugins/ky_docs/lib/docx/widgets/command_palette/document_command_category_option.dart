import 'document_command.dart';

/// Describes one category filter option shown above command palette results.
class DocumentCommandCategoryOption {
  static const allKey = '__all_commands__';

  final String key;
  final String label;
  final int count;

  const DocumentCommandCategoryOption({
    required this.key,
    required this.label,
    required this.count,
  });

  bool get isAll {
    return key == allKey;
  }

  static List<DocumentCommandCategoryOption> fromCommands(
    List<DocumentCommand> commands,
  ) {
    final orderedCategories = <String>[];
    final categoryCounts = <String, int>{};

    for (final command in commands) {
      final category = _normalizeCategory(command.category);
      categoryCounts.update(
        category,
        (count) => count + 1,
        ifAbsent: () {
          orderedCategories.add(category);
          return 1;
        },
      );
    }

    return [
      DocumentCommandCategoryOption(
        key: allKey,
        label: 'All',
        count: commands.length,
      ),
      for (final category in orderedCategories)
        DocumentCommandCategoryOption(
          key: category,
          label: category,
          count: categoryCounts[category]!,
        ),
    ];
  }

  static String _normalizeCategory(String category) {
    final normalized = category.trim();
    if (normalized.isEmpty) return 'General';
    return normalized;
  }
}
