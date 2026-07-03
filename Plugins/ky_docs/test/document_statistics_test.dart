import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/services/document_statistics.dart';

void main() {
  group('DocumentTextStatistics', () {
    test('calculates text metrics without a controller dependency', () {
      final statistics = DocumentTextStatistics.fromText(
        'Hello world.\n\nSecond paragraph!',
      );

      expect(statistics.wordCount, 4);
      expect(
        statistics.characterCount,
        'Hello world.\n\nSecond paragraph!'.length,
      );
      expect(
        statistics.characterCountNoSpaces,
        'Helloworld.Secondparagraph!'.length,
      );
      expect(statistics.paragraphCount, 2);
      expect(statistics.sentenceCount, 2);
      expect(statistics.estimatedReadingTime.inMinutes, 1);
      expect(statistics.readingTimeLabel, '1 min');
      expect(statistics.wordCountLabel, '4 words');
      expect(statistics.characterCountLabel, '31 characters');
      expect(statistics.paragraphCountLabel, '2 paragraphs');
      expect(statistics.sentenceCountLabel, '2 sentences');
      expect(
        statistics.summaryTooltip,
        'Document statistics: 4 words, 31 characters, 2 paragraphs, '
        '2 sentences, 1 min read',
      );
      expect(statistics.sourceText, 'Hello world.\n\nSecond paragraph!');
      expect(statistics.writingInsights.qualityLabel, 'Polished');
    });

    test('handles empty text as zero content with no reading time', () {
      final statistics = DocumentTextStatistics.fromText('   \n  ');

      expect(statistics.wordCount, 0);
      expect(statistics.characterCount, 6);
      expect(statistics.characterCountNoSpaces, 0);
      expect(statistics.paragraphCount, 0);
      expect(statistics.sentenceCount, 0);
      expect(statistics.estimatedReadingTime, Duration.zero);
      expect(statistics.readingTimeLabel, '0 min');
      expect(statistics.wordCountLabel, '0 words');
      expect(statistics.paragraphCountLabel, '0 paragraphs');
    });

    test('counts unpunctuated drafts as a sentence for document stats', () {
      final statistics = DocumentTextStatistics.fromText('one two three');

      expect(statistics.wordCount, 3);
      expect(statistics.sentenceCount, 1);
      expect(statistics.writingInsights.metrics.sentenceCount, 1);
    });
  });
}
