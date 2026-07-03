import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/models/component.dart';
import 'package:ky_slide/models/presentation.dart';
import 'package:ky_slide/models/presentation_component.dart';
import 'package:ky_slide/models/rich_text_content.dart';
import 'package:ky_slide/models/slide.dart';
import 'package:ky_slide/models/style/presentation_theme.dart';
import 'package:ky_slide/services/slide_search_service.dart';

void main() {
  test('matchingIndexes returns every slide for an empty query', () {
    expect(SlideSearchService.matchingIndexes(_presentation(), ''), [0, 1, 2]);
  });

  test('matchingIndexes matches title, notes, body text, and slide number', () {
    final presentation = _presentation();

    expect(SlideSearchService.matchingIndexes(presentation, 'opening'), [0]);
    expect(SlideSearchService.matchingIndexes(presentation, 'handoff'), [1]);
    expect(SlideSearchService.matchingIndexes(presentation, 'risk'), [2]);
    expect(SlideSearchService.matchingIndexes(presentation, '2'), [1]);
    expect(
      SlideSearchService.matchingIndexes(presentation, 'unknown'),
      isEmpty,
    );
  });
}

Presentation _presentation() {
  return Presentation(
    id: 'slide-search-test',
    title: 'Slide Search Test',
    slides: [
      Slide(id: 'slide-1', title: 'Opening', components: [_text('Welcome')]),
      Slide(
        id: 'slide-2',
        title: 'Delivery',
        notes: 'Owner handoff checklist',
        components: [],
      ),
      Slide(
        id: 'slide-3',
        title: 'Decision',
        components: [_text('Risk and rollout options')],
      ),
    ],
    theme: PresentationTheme(
      id: 'search-theme',
      name: 'Search Theme',
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

PresentationComponent _text(String value) {
  return PresentationComponent(
    id: value,
    type: ComponentType.richText,
    position: Offset.zero,
    size: const Size(100, 40),
    richText: RichTextContent(
      text: value,
      style: const TextStyle(color: Colors.white),
    ),
  );
}
