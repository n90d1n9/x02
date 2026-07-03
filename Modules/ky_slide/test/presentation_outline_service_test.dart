import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/models/component.dart';
import 'package:ky_slide/models/presentation.dart';
import 'package:ky_slide/models/presentation_component.dart';
import 'package:ky_slide/models/rich_text_content.dart';
import 'package:ky_slide/models/slide.dart';
import 'package:ky_slide/models/style/presentation_theme.dart';
import 'package:ky_slide/services/presentation_outline_service.dart';

void main() {
  test('outline extracts slide titles, snippets, and component counts', () {
    final outline = PresentationOutlineService.build(_presentation());

    expect(outline, hasLength(3));
    expect(outline[0].title, 'Opening');
    expect(outline[0].snippet, 'Why this matters for the operating plan.');
    expect(outline[0].componentCount, 2);
    expect(outline[1].title, startsWith('Untitled slide title fallback'));
    expect(outline[1].snippet, startsWith('Untitled slide title fallback'));
    expect(outline[2].title, 'Slide 3');
    expect(outline[2].snippet, 'No text content yet');
  });

  test('filter matches slide title, snippet, and exact slide number', () {
    final outline = PresentationOutlineService.build(_presentation());

    expect(
      PresentationOutlineService.filter(
        outline,
        'opening',
      ).map((item) => item.title),
      ['Opening'],
    );
    expect(
      PresentationOutlineService.filter(
        outline,
        'operating',
      ).map((item) => item.title),
      ['Opening'],
    );
    expect(
      PresentationOutlineService.filter(outline, '3').map((item) => item.title),
      ['Slide 3'],
    );
    expect(PresentationOutlineService.filter(outline, 'missing'), isEmpty);
  });
}

Presentation _presentation() {
  return Presentation(
    id: 'presentation-outline',
    title: 'Outline',
    slides: [
      Slide(
        id: 'slide-a',
        title: 'Opening',
        components: [
          _text('Opening'),
          _text('Why this matters for the operating plan.'),
        ],
      ),
      Slide(
        id: 'slide-b',
        title: '',
        components: [
          _text(
            'Untitled slide title fallback should compact long text into a title.',
          ),
        ],
      ),
      Slide(id: 'slide-c', components: []),
    ],
    theme: PresentationTheme(
      id: 'test-theme',
      name: 'Test Theme',
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
