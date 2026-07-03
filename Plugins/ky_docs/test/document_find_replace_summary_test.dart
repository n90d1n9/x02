import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/widgets/find_replace/find_replace_summary.dart';

void main() {
  group('DocxFindReplaceSummary', () {
    test('prompts for a query before replacements can be previewed', () {
      const summary = DocxFindReplaceSummary(
        hasQuery: false,
        matchCount: 0,
        replacementText: 'omega',
      );

      expect(summary.shouldShow, isTrue);
      expect(summary.actionLabel, 'Type a search term to preview replacements');
      expect(
        summary.detailLabel,
        'Replacement actions stay disabled until a match is found.',
      );
    });

    test('describes empty and populated replacement targets', () {
      const emptyReplacement = DocxFindReplaceSummary(
        hasQuery: true,
        matchCount: 2,
        replacementText: '',
      );
      const populatedReplacement = DocxFindReplaceSummary(
        hasQuery: true,
        matchCount: 1,
        replacementText: 'omega',
      );

      expect(emptyReplacement.actionLabel, 'Replace 2 matches with empty text');
      expect(emptyReplacement.detailLabel, 'Current matches will be removed.');
      expect(populatedReplacement.actionLabel, 'Replace 1 match with "omega"');
      expect(
        populatedReplacement.detailLabel,
        'Current matches will become "omega".',
      );
    });

    test('explains searches that have no replacement targets', () {
      const summary = DocxFindReplaceSummary(
        hasQuery: true,
        matchCount: 0,
        replacementText: 'omega',
      );

      expect(summary.hasMatches, isFalse);
      expect(summary.actionLabel, 'No replacements available');
      expect(summary.detailLabel, 'Try changing search options or the query.');
    });
  });
}
