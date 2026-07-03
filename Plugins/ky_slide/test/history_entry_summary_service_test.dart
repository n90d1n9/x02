import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/models/history_entry.dart';
import 'package:ky_slide/models/presentation.dart';
import 'package:ky_slide/models/slide.dart';
import 'package:ky_slide/models/style/presentation_theme.dart';
import 'package:ky_slide/services/history_entry_summary_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('describe includes slide count and selected slide title', () {
    final entry = HistoryEntry(
      presentation: _presentation([
        'Opening',
        'Follow up',
      ], currentSlideIndex: 1),
    );

    expect(
      HistoryEntrySummaryService.describe(entry),
      '2 slides - Slide 2/2: Follow up',
    );
  });

  test('describe handles empty titles and out-of-range selected slides', () {
    final entry = HistoryEntry(
      presentation: _presentation([''], currentSlideIndex: 8),
    );

    expect(
      HistoryEntrySummaryService.describe(entry),
      '1 slide - Slide 1/1: Untitled slide',
    );
  });

  test('describe handles presentations without slides', () {
    final entry = HistoryEntry(
      presentation: _presentation(const [], currentSlideIndex: 0),
    );

    expect(HistoryEntrySummaryService.describe(entry), 'No slides');
  });
}

Presentation _presentation(
  List<String> titles, {
  required int currentSlideIndex,
}) {
  return Presentation(
    id: 'summary-test',
    title: 'Summary Test',
    currentSlideIndex: currentSlideIndex,
    slides: [
      for (final (index, title) in titles.indexed)
        Slide(id: 'slide-$index', title: title, components: []),
    ],
    theme: PresentationTheme(
      id: 'summary-theme',
      name: 'Summary Theme',
      primaryColor: const Color(0xFF2563EB),
      secondaryColor: const Color(0xFF14B8A6),
      backgroundColor: const Color(0xFF0F172A),
      textColor: Colors.white,
      titleStyle: const TextStyle(color: Colors.white, fontSize: 48),
      bodyStyle: const TextStyle(color: Colors.white70, fontSize: 20),
      colorPalette: const [Color(0xFF2563EB), Color(0xFF14B8A6)],
    ),
  );
}
