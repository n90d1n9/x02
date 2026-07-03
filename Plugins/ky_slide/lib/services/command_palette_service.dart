import '../models/command_palette_action.dart';
import '../models/command_palette_section.dart';

/// Filters and groups command palette actions for search and display.
class CommandPaletteService {
  const CommandPaletteService._();

  static List<CommandPaletteAction> filter({
    required List<CommandPaletteAction> actions,
    required String query,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return actions;

    final terms = normalizedQuery
        .split(RegExp(r'\s+'))
        .where((term) => term.isNotEmpty)
        .toList();

    return actions.where((action) {
      final haystack = [
        action.title,
        action.description,
        action.category,
        action.shortcutLabel ?? '',
        ...action.keywords,
        ...action.metadataLabels,
      ].join(' ').toLowerCase();

      return terms.every(haystack.contains);
    }).toList();
  }

  static List<CommandPaletteSection> sections({
    required List<CommandPaletteAction> actions,
    required String query,
    List<String> recentCommandIds = const [],
  }) {
    if (actions.isEmpty) return const [];

    final normalizedQuery = query.trim();
    final sections = <CommandPaletteSection>[];
    final groupedActions = <String, List<CommandPaletteAction>>{};
    final useRecentSection =
        normalizedQuery.isEmpty && recentCommandIds.isNotEmpty;
    final recentActions = useRecentSection
        ? _recentActions(actions: actions, recentCommandIds: recentCommandIds)
        : const <CommandPaletteAction>[];
    final recentActionIds = recentActions.map((action) => action.id).toSet();

    if (recentActions.isNotEmpty) {
      sections.add(
        CommandPaletteSection(title: 'Recent', actions: recentActions),
      );
    }

    for (final action in actions) {
      if (recentActionIds.contains(action.id)) continue;

      groupedActions
          .putIfAbsent(action.category, () => <CommandPaletteAction>[])
          .add(action);
    }

    for (final entry in groupedActions.entries) {
      sections.add(
        CommandPaletteSection(title: entry.key, actions: entry.value),
      );
    }

    return sections;
  }

  static List<CommandPaletteAction> flattenSections(
    List<CommandPaletteSection> sections,
  ) {
    return [for (final section in sections) ...section.actions];
  }

  static List<CommandPaletteAction> _recentActions({
    required List<CommandPaletteAction> actions,
    required List<String> recentCommandIds,
  }) {
    final actionsById = {for (final action in actions) action.id: action};
    final recentActions = <CommandPaletteAction>[];
    final seenIds = <String>{};

    for (final commandId in recentCommandIds) {
      if (!seenIds.add(commandId)) continue;

      final action = actionsById[commandId];
      if (action != null) {
        recentActions.add(action);
      }
    }

    return recentActions;
  }
}
