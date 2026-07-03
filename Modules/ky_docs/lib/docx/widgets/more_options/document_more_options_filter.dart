import 'document_more_option.dart';

/// Filters More Options groups while preserving their original grouping.
class DocumentMoreOptionsFilter {
  final List<DocumentMoreOptionGroup> groups;
  final String query;

  const DocumentMoreOptionsFilter({required this.groups, this.query = ''});

  String get normalizedQuery => query.trim().toLowerCase();

  bool get hasQuery => normalizedQuery.isNotEmpty;

  int get totalOptionCount {
    return groups.fold(0, (count, group) => count + group.options.length);
  }

  List<DocumentMoreOptionGroup> get visibleGroups {
    if (!hasQuery) return groups;

    final results = <DocumentMoreOptionGroup>[];
    for (final group in groups) {
      final options = group.options
          .where((option) => _matchesOption(group, option))
          .toList(growable: false);
      if (options.isEmpty) continue;
      results.add(
        DocumentMoreOptionGroup(
          title: group.title,
          icon: group.icon,
          options: options,
        ),
      );
    }
    return results;
  }

  int get visibleOptionCount {
    return visibleGroups.fold(
      0,
      (count, group) => count + group.options.length,
    );
  }

  String get summary {
    if (groups.isEmpty) return 'No document tools available';

    if (hasQuery) {
      if (visibleOptionCount == 0) return 'No tools match "$query"';
      final toolLabel = visibleOptionCount == 1 ? 'tool' : 'tools';
      return '$visibleOptionCount of $totalOptionCount $toolLabel matching "$query"';
    }

    final groupLabel = groups.length == 1 ? 'group' : 'groups';
    final toolLabel = totalOptionCount == 1 ? 'tool' : 'tools';
    return '$totalOptionCount $toolLabel across ${groups.length} $groupLabel';
  }

  bool _matchesOption(
    DocumentMoreOptionGroup group,
    DocumentMoreOption option,
  ) {
    return _matches(group.title) ||
        _matches(option.title) ||
        _matches(option.subtitle) ||
        _matches(option.shortcutLabel) ||
        option.keywords.any(_matches) ||
        _matches(option.disabledReason);
  }

  bool _matches(String? value) {
    return value?.toLowerCase().contains(normalizedQuery) ?? false;
  }
}
