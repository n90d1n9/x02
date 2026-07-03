import 'package:flutter/services.dart';

/// Summarizes the active text selection for compact editor status surfaces.
class DocumentSelectionStatus {
  final int characterCount;
  final int wordCount;
  final int lineCount;
  final int paragraphCount;

  const DocumentSelectionStatus({
    required this.characterCount,
    required this.wordCount,
    required this.lineCount,
    required this.paragraphCount,
  });

  const DocumentSelectionStatus.empty()
    : characterCount = 0,
      wordCount = 0,
      lineCount = 0,
      paragraphCount = 0;

  bool get hasSelection => characterCount > 0;

  String get wordCountLabel => _pluralized(wordCount, 'word');

  String get characterCountLabel => _pluralized(characterCount, 'character');

  String get lineCountLabel => _pluralized(lineCount, 'line');

  String get paragraphCountLabel => _pluralized(paragraphCount, 'paragraph');

  String get label {
    if (wordCount > 0) {
      return '$wordCountLabel selected';
    }
    return '$characterCountLabel selected';
  }

  String get tooltip {
    if (!hasSelection) return 'No text selected';

    return 'Selected: ${detailParts.join(', ')}';
  }

  List<String> get detailParts {
    return [
      if (wordCount > 0) wordCountLabel,
      characterCountLabel,
      if (lineCount > 1) lineCountLabel,
      if (paragraphCount > 1) paragraphCountLabel,
    ];
  }

  factory DocumentSelectionStatus.fromSelection({
    required String text,
    required TextSelection selection,
  }) {
    if (!selection.isValid || selection.isCollapsed || text.isEmpty) {
      return const DocumentSelectionStatus.empty();
    }

    final start = selection.start.clamp(0, text.length);
    final end = selection.end.clamp(0, text.length);
    if (end <= start) return const DocumentSelectionStatus.empty();

    final selectedText = text.substring(start, end);
    return DocumentSelectionStatus(
      characterCount: end - start,
      wordCount: _countWords(selectedText),
      lineCount: _countLines(selectedText),
      paragraphCount: _countParagraphs(selectedText),
    );
  }

  static int _countWords(String text) {
    return text.trim().split(RegExp(r'\s+')).where((word) {
      return word
          .replaceAll(RegExp(r'[^\p{L}\p{N}]', unicode: true), '')
          .isNotEmpty;
    }).length;
  }

  static int _countLines(String text) {
    if (text.isEmpty) return 0;
    return '\n'.allMatches(text).length + 1;
  }

  static int _countParagraphs(String text) {
    return text
        .split(RegExp(r'\n+'))
        .where((paragraph) => paragraph.trim().isNotEmpty)
        .length;
  }

  static String _pluralized(int count, String unit) {
    return count == 1 ? '1 $unit' : '$count ${unit}s';
  }
}
