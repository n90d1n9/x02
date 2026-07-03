/// Derived speaker-note metadata used by presenter-facing editor chrome.
class SpeakerNotesMetrics {
  static const int defaultWordsPerMinute = 130;

  final int wordCount;
  final int characterCount;
  final int wordsPerMinute;

  const SpeakerNotesMetrics({
    required this.wordCount,
    required this.characterCount,
    this.wordsPerMinute = defaultWordsPerMinute,
  });

  factory SpeakerNotesMetrics.fromText(
    String text, {
    int wordsPerMinute = defaultWordsPerMinute,
  }) {
    final trimmedText = text.trim();
    return SpeakerNotesMetrics(
      wordCount: trimmedText.isEmpty
          ? 0
          : trimmedText.split(RegExp(r'\s+')).length,
      characterCount: text.trimRight().length,
      wordsPerMinute: wordsPerMinute,
    );
  }

  String get wordLabel => '$wordCount ${wordCount == 1 ? 'word' : 'words'}';

  String get characterLabel {
    return '$characterCount ${characterCount == 1 ? 'char' : 'chars'}';
  }

  String get speakingTimeLabel {
    if (wordCount == 0) return '0 min talk';
    final safeWordsPerMinute = wordsPerMinute <= 0
        ? defaultWordsPerMinute
        : wordsPerMinute;
    final minutes = wordCount / safeWordsPerMinute;
    if (minutes < 1) return '<1 min talk';
    final roundedMinutes = minutes.ceil();
    return '$roundedMinutes min talk';
  }
}
