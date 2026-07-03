import 'package:flutter_quill/flutter_quill.dart' as quill;

import 'document_writing_insights.dart';

/// Captures a point-in-time set of document text metrics and writing insights.
class DocumentTextStatistics {
  final String sourceText;
  final int wordCount;
  final int characterCount;
  final int characterCountNoSpaces;
  final int paragraphCount;
  final int sentenceCount;
  final DocumentWritingInsights writingInsights;

  const DocumentTextStatistics({
    required this.sourceText,
    required this.wordCount,
    required this.characterCount,
    required this.characterCountNoSpaces,
    required this.paragraphCount,
    required this.sentenceCount,
    required this.writingInsights,
  });

  factory DocumentTextStatistics.fromText(String text) {
    final writingInsights = DocumentWritingInsights.fromText(text);
    final metrics = writingInsights.metrics;

    return DocumentTextStatistics(
      sourceText: text,
      wordCount: metrics.wordCount,
      characterCount: text.length,
      characterCountNoSpaces: text.replaceAll(RegExp(r'\s'), '').length,
      paragraphCount: metrics.paragraphCount,
      sentenceCount: metrics.sentenceCount,
      writingInsights: writingInsights,
    );
  }

  Duration get estimatedReadingTime {
    if (wordCount == 0) return Duration.zero;

    // Average reading speed: 200 words per minute.
    final minutes = (wordCount / 200).ceil();
    return Duration(minutes: minutes.clamp(1, 999));
  }

  String get readingTimeLabel {
    final minutes = estimatedReadingTime.inMinutes;
    return '$minutes min';
  }

  String get wordCountLabel => _pluralized(wordCount, 'word');

  String get characterCountLabel => _pluralized(characterCount, 'character');

  String get characterCountNoSpacesLabel {
    return _pluralized(characterCountNoSpaces, 'non-space character');
  }

  String get paragraphCountLabel => _pluralized(paragraphCount, 'paragraph');

  String get sentenceCountLabel => _pluralized(sentenceCount, 'sentence');

  String get summaryTooltip {
    return 'Document statistics: $wordCountLabel, $characterCountLabel, '
        '$paragraphCountLabel, $sentenceCountLabel, $readingTimeLabel read';
  }

  String get characterCountTooltip {
    return 'Characters: $characterCountLabel, '
        '$characterCountNoSpacesLabel';
  }

  String get readingTimeTooltip {
    return 'Estimated reading time: $readingTimeLabel at 200 words per minute';
  }

  static String _pluralized(int count, String unit) {
    return count == 1 ? '1 $unit' : '$count ${unit}s';
  }
}

/// Derives live document statistics from the active Quill editor controller.
class DocumentStatistics {
  final quill.QuillController controller;

  DocumentStatistics(this.controller);

  DocumentTextStatistics get snapshot {
    return DocumentTextStatistics.fromText(controller.document.toPlainText());
  }

  int get wordCount => snapshot.wordCount;

  int get characterCount => snapshot.characterCount;

  int get characterCountNoSpaces => snapshot.characterCountNoSpaces;

  int get paragraphCount => snapshot.paragraphCount;

  int get sentenceCount => snapshot.sentenceCount;

  Duration get estimatedReadingTime => snapshot.estimatedReadingTime;

  String get readingTimeLabel => snapshot.readingTimeLabel;

  DocumentWritingInsights get writingInsights => snapshot.writingInsights;
}
