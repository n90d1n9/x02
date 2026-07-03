import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/widgets/status_bar/document_selection_status.dart';

void main() {
  group('DocumentSelectionStatus', () {
    test('counts selected words and characters', () {
      final status = DocumentSelectionStatus.fromSelection(
        text: 'One two three',
        selection: const TextSelection(baseOffset: 0, extentOffset: 7),
      );

      expect(status.hasSelection, isTrue);
      expect(status.characterCount, 7);
      expect(status.wordCount, 2);
      expect(status.lineCount, 1);
      expect(status.paragraphCount, 1);
      expect(status.wordCountLabel, '2 words');
      expect(status.characterCountLabel, '7 characters');
      expect(status.lineCountLabel, '1 line');
      expect(status.paragraphCountLabel, '1 paragraph');
      expect(status.label, '2 words selected');
      expect(status.tooltip, 'Selected: 2 words, 7 characters');
      expect(status.detailParts, ['2 words', '7 characters']);
    });

    test('adds line and paragraph details for multi-line selections', () {
      final status = DocumentSelectionStatus.fromSelection(
        text: 'One\n\nTwo three',
        selection: const TextSelection(baseOffset: 0, extentOffset: 14),
      );

      expect(status.characterCount, 14);
      expect(status.wordCount, 3);
      expect(status.lineCount, 3);
      expect(status.paragraphCount, 2);
      expect(
        status.tooltip,
        'Selected: 3 words, 14 characters, 3 lines, 2 paragraphs',
      );
    });

    test('falls back to character label for symbol-only selections', () {
      final status = DocumentSelectionStatus.fromSelection(
        text: '*** hello',
        selection: const TextSelection(baseOffset: 0, extentOffset: 3),
      );

      expect(status.wordCount, 0);
      expect(status.label, '3 characters selected');
      expect(status.tooltip, 'Selected: 3 characters');
    });

    test('returns empty status for collapsed selections', () {
      final status = DocumentSelectionStatus.fromSelection(
        text: 'No selection',
        selection: const TextSelection.collapsed(offset: 2),
      );

      expect(status.hasSelection, isFalse);
      expect(status.label, '0 characters selected');
    });
  });
}
