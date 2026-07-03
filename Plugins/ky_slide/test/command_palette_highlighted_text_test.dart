import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/widgets/editor/command_palette_highlighted_text.dart';

void main() {
  test('segments marks case-insensitive non-overlapping query matches', () {
    final segments = CommandPaletteHighlightedText.segments(
      text: 'Open Import / Export',
      query: 'import open',
    );

    expect(segments.map((segment) => segment.text), [
      'Open',
      ' ',
      'Import',
      ' / Export',
    ]);
    expect(segments.map((segment) => segment.isHighlighted), [
      true,
      false,
      true,
      false,
    ]);
  });

  test('segments prefers the longest overlapping query term', () {
    final segments = CommandPaletteHighlightedText.segments(
      text: 'Duplicate',
      query: 'dup duplicate',
    );

    expect(segments.length, 1);
    expect(segments.single.text, 'Duplicate');
    expect(segments.single.isHighlighted, isTrue);
  });

  test('segments returns plain text when the query does not match', () {
    final segments = CommandPaletteHighlightedText.segments(
      text: 'Start Presenting',
      query: 'export',
    );

    expect(segments.length, 1);
    expect(segments.single.text, 'Start Presenting');
    expect(segments.single.isHighlighted, isFalse);
  });
}
