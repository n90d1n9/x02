import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/models/slide_template.dart';
import 'package:ky_slide/services/slide_template_visual_service.dart';

void main() {
  test('accentFor maps template types onto the theme palette', () {
    const palette = [
      Color(0xFF111111),
      Color(0xFF222222),
      Color(0xFF333333),
      Color(0xFF444444),
    ];

    expect(
      SlideTemplateVisualService.accentFor(
        SlideTemplateType.executiveCover,
        palette,
      ),
      palette[0],
    );
    expect(
      SlideTemplateVisualService.accentFor(SlideTemplateType.agenda, palette),
      palette[1],
    );
    expect(
      SlideTemplateVisualService.accentFor(
        SlideTemplateType.metricStory,
        palette,
      ),
      palette[2],
    );
    expect(
      SlideTemplateVisualService.accentFor(
        SlideTemplateType.comparison,
        palette,
      ),
      palette[3],
    );
  });

  test('accentFor falls back when the theme palette is empty', () {
    expect(
      SlideTemplateVisualService.accentFor(
        SlideTemplateType.executiveCover,
        const [],
      ),
      SlideTemplateVisualService.fallbackPalette.first,
    );
  });

  test('iconForCategory returns stable category icons', () {
    expect(
      SlideTemplateVisualService.iconForCategory(SlideTemplateCategory.cover),
      Icons.article_outlined,
    );
    expect(
      SlideTemplateVisualService.iconForCategory(
        SlideTemplateCategory.structure,
      ),
      Icons.view_agenda_outlined,
    );
    expect(
      SlideTemplateVisualService.iconForCategory(SlideTemplateCategory.metrics),
      Icons.bar_chart,
    );
    expect(
      SlideTemplateVisualService.iconForCategory(
        SlideTemplateCategory.decision,
      ),
      Icons.compare_arrows,
    );
  });
}
