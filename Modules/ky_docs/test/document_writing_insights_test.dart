import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/services/document_writing_insights.dart';

void main() {
  group('DocumentWritingInsights', () {
    test('describes empty drafts without scoring them as ready', () {
      final insights = DocumentWritingInsights.fromText('   \n  ');

      expect(insights.score, 0);
      expect(insights.qualityLabel, 'Empty draft');
      expect(insights.metrics.wordCount, 0);
      expect(insights.metrics.averageWordsPerSentenceLabel, '0');
      expect(insights.highlights.single.value, 'No content');
      expect(
        insights.recommendations,
        contains('Add content to unlock writing insights'),
      );
    });

    test('scores balanced writing as polished', () {
      final insights = DocumentWritingInsights.fromText(
        'This proposal is clear. It explains the market.\n\n'
        'Teams can act quickly.',
      );

      expect(insights.score, 100);
      expect(insights.qualityLabel, 'Polished');
      expect(insights.metrics.wordCount, 12);
      expect(insights.metrics.sentenceCount, 3);
      expect(insights.metrics.paragraphCount, 2);
      expect(insights.metrics.averageWordsPerSentence, 4);
      expect(insights.metrics.averageWordsPerSentenceLabel, '4');
      expect(insights.metrics.longSentenceCount, 0);
      expect(
        insights.highlights.map((insight) => insight.value),
        containsAll(['Easy', 'Structured', 'Steady']),
      );
      expect(insights.recommendations, isEmpty);
    });

    test('flags dense writing with actionable recommendations', () {
      final longSentence = List.filled(38, 'strategy').join(' ');
      final insights = DocumentWritingInsights.fromText(longSentence);

      expect(insights.score, lessThan(72));
      expect(insights.qualityLabel, 'Needs review');
      expect(insights.metrics.wordCount, 38);
      expect(insights.metrics.sentenceCount, 1);
      expect(insights.metrics.longSentenceCount, 1);
      expect(insights.metrics.longestSentenceWordCount, 38);
      expect(
        insights.recommendations,
        contains('Break up long sentences for easier scanning'),
      );
      expect(
        insights.recommendations,
        contains('Add punctuation to clarify sentence boundaries'),
      );
      expect(
        insights.recommendationsText,
        contains('Break up long sentences for easier scanning'),
      );
    });
  });
}
