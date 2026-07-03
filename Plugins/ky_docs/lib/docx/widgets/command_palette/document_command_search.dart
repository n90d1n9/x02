import 'document_command.dart';

/// Identifies where a command palette query matched a command.
enum DocumentCommandMatchSource { title, category, shortcut, keyword, subtitle }

/// Describes one ranked command palette search hit.
class DocumentCommandSearchResult {
  final DocumentCommand command;
  final DocumentCommandMatchSource source;
  final int score;
  final int originalIndex;

  const DocumentCommandSearchResult({
    required this.command,
    required this.source,
    required this.score,
    required this.originalIndex,
  });
}

/// Filters and ranks command palette actions for fast keyboard workflows.
class DocumentCommandSearch {
  const DocumentCommandSearch._();

  static List<DocumentCommand> filterAndSort({
    required List<DocumentCommand> commands,
    required String query,
  }) {
    return search(
      commands: commands,
      query: query,
    ).map((result) => result.command).toList();
  }

  static List<DocumentCommandSearchResult> search({
    required List<DocumentCommand> commands,
    required String query,
  }) {
    final normalizedQuery = _normalize(query);
    if (normalizedQuery.isEmpty) return _allCommands(commands);

    final results = <DocumentCommandSearchResult>[];
    for (var index = 0; index < commands.length; index++) {
      final result = _scoreCommand(
        command: commands[index],
        query: normalizedQuery,
        originalIndex: index,
      );
      if (result != null) results.add(result);
    }

    results.sort(_compareResults);
    return results;
  }

  static List<DocumentCommandSearchResult> _allCommands(
    List<DocumentCommand> commands,
  ) {
    return [
      for (var index = 0; index < commands.length; index++)
        DocumentCommandSearchResult(
          command: commands[index],
          source: DocumentCommandMatchSource.title,
          score: 0,
          originalIndex: index,
        ),
    ];
  }

  static DocumentCommandSearchResult? _scoreCommand({
    required DocumentCommand command,
    required String query,
    required int originalIndex,
  }) {
    final candidates = <DocumentCommandSearchResult>[
      if (_titleScore(command.title, query) != null)
        DocumentCommandSearchResult(
          command: command,
          source: DocumentCommandMatchSource.title,
          score: _titleScore(command.title, query)!,
          originalIndex: originalIndex,
        ),
      if (_containsScore(command.category, query, startsWithScore: 88) != null)
        DocumentCommandSearchResult(
          command: command,
          source: DocumentCommandMatchSource.category,
          score: _containsScore(command.category, query, startsWithScore: 88)!,
          originalIndex: originalIndex,
        ),
      if (_shortcutScore(command.shortcut, query) != null)
        DocumentCommandSearchResult(
          command: command,
          source: DocumentCommandMatchSource.shortcut,
          score: _shortcutScore(command.shortcut, query)!,
          originalIndex: originalIndex,
        ),
      if (_keywordScore(command.keywords, query) != null)
        DocumentCommandSearchResult(
          command: command,
          source: DocumentCommandMatchSource.keyword,
          score: _keywordScore(command.keywords, query)!,
          originalIndex: originalIndex,
        ),
      if (_containsScore(command.subtitle, query, startsWithScore: 68) != null)
        DocumentCommandSearchResult(
          command: command,
          source: DocumentCommandMatchSource.subtitle,
          score: _containsScore(command.subtitle, query, startsWithScore: 68)!,
          originalIndex: originalIndex,
        ),
    ];

    if (candidates.isEmpty) return null;
    candidates.sort(_compareResults);
    return candidates.first;
  }

  static int? _titleScore(String value, String query) {
    final normalized = _normalize(value);
    if (normalized == query) return 120;
    if (normalized.startsWith(query)) return 112;
    if (normalized.contains(query)) return 100;
    return null;
  }

  static int? _keywordScore(List<String> values, String query) {
    var bestScore = 0;
    for (final value in values) {
      final score = _containsScore(value, query, startsWithScore: 78);
      if (score != null && score > bestScore) bestScore = score;
    }
    return bestScore == 0 ? null : bestScore;
  }

  static int? _shortcutScore(String? value, String query) {
    if (value == null) return null;

    final normalized = _normalize(value);
    final compactShortcut = normalized.replaceAll(' ', '');
    final compactQuery = query.replaceAll(' ', '');
    if (normalized.contains(query) || compactShortcut.contains(compactQuery)) {
      return 86;
    }
    return null;
  }

  static int? _containsScore(
    String value,
    String query, {
    required int startsWithScore,
  }) {
    final normalized = _normalize(value);
    if (normalized.startsWith(query)) return startsWithScore;
    if (normalized.contains(query)) return startsWithScore - 10;
    return null;
  }

  static int _compareResults(
    DocumentCommandSearchResult a,
    DocumentCommandSearchResult b,
  ) {
    final scoreComparison = b.score.compareTo(a.score);
    if (scoreComparison != 0) return scoreComparison;

    final enabledComparison = _enabledWeight(
      b.command,
    ).compareTo(_enabledWeight(a.command));
    if (enabledComparison != 0) return enabledComparison;

    return a.originalIndex.compareTo(b.originalIndex);
  }

  static int _enabledWeight(DocumentCommand command) {
    return command.enabled ? 1 : 0;
  }

  static String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}
