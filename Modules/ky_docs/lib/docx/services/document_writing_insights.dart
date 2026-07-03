enum DocumentWritingInsightTone { positive, neutral, caution }

enum DocumentWritingInsightKind { readability, structure, rhythm }

class DocumentWritingInsight {
  final DocumentWritingInsightKind kind;
  final String label;
  final String value;
  final DocumentWritingInsightTone tone;

  const DocumentWritingInsight({
    required this.kind,
    required this.label,
    required this.value,
    required this.tone,
  });
}

class DocumentWritingInsightMetrics {
  final int wordCount;
  final int sentenceCount;
  final int paragraphCount;
  final double averageWordsPerSentence;
  final double averageSentencesPerParagraph;
  final int longSentenceCount;
  final int longestSentenceWordCount;

  const DocumentWritingInsightMetrics({
    required this.wordCount,
    required this.sentenceCount,
    required this.paragraphCount,
    required this.averageWordsPerSentence,
    required this.averageSentencesPerParagraph,
    required this.longSentenceCount,
    required this.longestSentenceWordCount,
  });

  const DocumentWritingInsightMetrics.empty()
    : wordCount = 0,
      sentenceCount = 0,
      paragraphCount = 0,
      averageWordsPerSentence = 0,
      averageSentencesPerParagraph = 0,
      longSentenceCount = 0,
      longestSentenceWordCount = 0;

  String get averageWordsPerSentenceLabel {
    return _compactDecimalLabel(averageWordsPerSentence);
  }

  String get averageSentencesPerParagraphLabel {
    return _compactDecimalLabel(averageSentencesPerParagraph);
  }

  static String _compactDecimalLabel(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }
}

class DocumentWritingInsights {
  static const int _longSentenceWordThreshold = 30;

  final int score;
  final String qualityLabel;
  final DocumentWritingInsightMetrics metrics;
  final List<DocumentWritingInsight> highlights;
  final List<String> recommendations;

  const DocumentWritingInsights({
    required this.score,
    required this.qualityLabel,
    required this.metrics,
    required this.highlights,
    required this.recommendations,
  });

  factory DocumentWritingInsights.fromText(String text) {
    final words = _words(text);
    if (words.isEmpty) {
      return const DocumentWritingInsights(
        score: 0,
        qualityLabel: 'Empty draft',
        metrics: DocumentWritingInsightMetrics.empty(),
        highlights: [
          DocumentWritingInsight(
            kind: DocumentWritingInsightKind.readability,
            label: 'Readability',
            value: 'No content',
            tone: DocumentWritingInsightTone.neutral,
          ),
        ],
        recommendations: ['Add content to unlock writing insights'],
      );
    }

    final paragraphCount = _paragraphCount(text);
    final sentenceWordCounts = _sentenceWordCounts(text);
    final sentenceCount = sentenceWordCounts.length;
    final averageWordsPerSentence = words.length / sentenceCount;
    final averageSentencesPerParagraph = sentenceCount / paragraphCount;
    final metrics = DocumentWritingInsightMetrics(
      wordCount: words.length,
      sentenceCount: sentenceCount,
      paragraphCount: paragraphCount,
      averageWordsPerSentence: averageWordsPerSentence,
      averageSentencesPerParagraph: averageSentencesPerParagraph,
      longSentenceCount: sentenceWordCounts
          .where((count) => count > _longSentenceWordThreshold)
          .length,
      longestSentenceWordCount: _maxSentenceWordCount(sentenceWordCounts),
    );
    final recommendations = <String>[];
    var score = 100;

    if (averageWordsPerSentence > 30) {
      score -= 24;
      recommendations.add('Break up long sentences for easier scanning');
    } else if (averageWordsPerSentence > 24) {
      score -= 12;
      recommendations.add('Tighten a few longer sentences');
    } else if (averageWordsPerSentence < 7 && words.length > 30) {
      score -= 6;
      recommendations.add('Vary sentence length to improve flow');
    }

    if (paragraphCount == 1 && words.length > 80) {
      score -= 18;
      recommendations.add('Split long blocks into shorter paragraphs');
    } else if (averageSentencesPerParagraph > 6) {
      score -= 12;
      recommendations.add('Use more paragraph breaks for structure');
    }

    if (!_hasSentencePunctuation(text) && words.length > 30) {
      score -= 10;
      recommendations.add('Add punctuation to clarify sentence boundaries');
    }

    final boundedScore = score.clamp(0, 100).toInt();
    return DocumentWritingInsights(
      score: boundedScore,
      qualityLabel: _qualityLabel(boundedScore),
      metrics: metrics,
      highlights: [
        DocumentWritingInsight(
          kind: DocumentWritingInsightKind.readability,
          label: 'Readability',
          value: _readabilityLabel(averageWordsPerSentence),
          tone: _readabilityTone(averageWordsPerSentence),
        ),
        DocumentWritingInsight(
          kind: DocumentWritingInsightKind.structure,
          label: 'Structure',
          value: _structureLabel(
            wordCount: words.length,
            paragraphCount: paragraphCount,
          ),
          tone: _structureTone(
            wordCount: words.length,
            paragraphCount: paragraphCount,
          ),
        ),
        DocumentWritingInsight(
          kind: DocumentWritingInsightKind.rhythm,
          label: 'Rhythm',
          value: _rhythmLabel(averageSentencesPerParagraph),
          tone: _rhythmTone(averageSentencesPerParagraph),
        ),
      ],
      recommendations: List.unmodifiable(recommendations),
    );
  }

  bool get hasRecommendations => recommendations.isNotEmpty;

  String get recommendationsText => recommendations.join('\n');

  static List<String> _words(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return const [];
    return trimmed.split(RegExp(r'\s+'));
  }

  static int _paragraphCount(String text) {
    final count = text
        .split(RegExp(r'\n+'))
        .map((paragraph) => paragraph.trim())
        .where((paragraph) => paragraph.isNotEmpty)
        .length;
    return count == 0 ? 1 : count;
  }

  static List<int> _sentenceWordCounts(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return const [];

    final counts = <int>[];
    final fragments = trimmed
        .split(RegExp(r'[.!?]+'))
        .map((sentence) => sentence.trim())
        .where((sentence) => sentence.isNotEmpty);

    for (final fragment in fragments) {
      final count = _words(fragment).length;
      if (count > 0) counts.add(count);
    }

    if (counts.isEmpty) return [_words(trimmed).length];
    return counts;
  }

  static int _maxSentenceWordCount(List<int> sentenceWordCounts) {
    var maxCount = 0;
    for (final count in sentenceWordCounts) {
      if (count > maxCount) maxCount = count;
    }
    return maxCount;
  }

  static bool _hasSentencePunctuation(String text) {
    return RegExp(r'[.!?]').hasMatch(text);
  }

  static String _qualityLabel(int score) {
    if (score >= 88) return 'Polished';
    if (score >= 72) return 'Clear';
    if (score >= 50) return 'Needs review';
    return 'Draft';
  }

  static String _readabilityLabel(double averageWordsPerSentence) {
    if (averageWordsPerSentence <= 18) return 'Easy';
    if (averageWordsPerSentence <= 24) return 'Balanced';
    if (averageWordsPerSentence <= 30) return 'Dense';
    return 'Heavy';
  }

  static DocumentWritingInsightTone _readabilityTone(
    double averageWordsPerSentence,
  ) {
    if (averageWordsPerSentence <= 24) {
      return DocumentWritingInsightTone.positive;
    }
    return DocumentWritingInsightTone.caution;
  }

  static String _structureLabel({
    required int wordCount,
    required int paragraphCount,
  }) {
    if (wordCount <= 80 && paragraphCount == 1) return 'Light';
    if (paragraphCount >= 3) return 'Layered';
    if (paragraphCount >= 2) return 'Structured';
    return 'Single block';
  }

  static DocumentWritingInsightTone _structureTone({
    required int wordCount,
    required int paragraphCount,
  }) {
    if (paragraphCount >= 2 || wordCount <= 80) {
      return DocumentWritingInsightTone.positive;
    }
    return DocumentWritingInsightTone.caution;
  }

  static String _rhythmLabel(double averageSentencesPerParagraph) {
    if (averageSentencesPerParagraph <= 3) return 'Steady';
    if (averageSentencesPerParagraph <= 6) return 'Moderate';
    return 'Long blocks';
  }

  static DocumentWritingInsightTone _rhythmTone(
    double averageSentencesPerParagraph,
  ) {
    if (averageSentencesPerParagraph <= 3) {
      return DocumentWritingInsightTone.positive;
    }
    if (averageSentencesPerParagraph <= 6) {
      return DocumentWritingInsightTone.neutral;
    }
    return DocumentWritingInsightTone.caution;
  }
}
