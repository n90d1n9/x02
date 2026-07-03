import 'find_replace_controller.dart';

/// Summarizes the pending replacement impact shown in the find/replace panel.
class DocxFindReplaceSummary {
  final bool hasQuery;
  final int matchCount;
  final String replacementText;

  const DocxFindReplaceSummary({
    required this.hasQuery,
    required this.matchCount,
    required this.replacementText,
  });

  factory DocxFindReplaceSummary.fromController(
    DocxFindReplaceController controller,
  ) {
    return DocxFindReplaceSummary(
      hasQuery: controller.hasQuery,
      matchCount: controller.matchCount,
      replacementText: controller.replaceTextController.text,
    );
  }

  bool get hasMatches => matchCount > 0;

  bool get replacesWithEmptyText => replacementText.isEmpty;

  bool get shouldShow => hasQuery || replacementText.isNotEmpty;

  String get countLabel => matchCount == 1 ? '1 match' : '$matchCount matches';

  String get actionLabel {
    if (!hasQuery) return 'Type a search term to preview replacements';
    if (!hasMatches) return 'No replacements available';
    if (replacesWithEmptyText) return 'Replace $countLabel with empty text';
    return 'Replace $countLabel with "$replacementText"';
  }

  String get detailLabel {
    if (!hasQuery) {
      return 'Replacement actions stay disabled until a match is found.';
    }
    if (!hasMatches) return 'Try changing search options or the query.';
    if (replacesWithEmptyText) return 'Current matches will be removed.';
    return 'Current matches will become "$replacementText".';
  }
}
