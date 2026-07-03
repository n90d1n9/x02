import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/models/component.dart';
import 'package:ky_slide/models/presentation.dart';
import 'package:ky_slide/models/slide.dart';
import 'package:ky_slide/models/slide_layout.dart';
import 'package:ky_slide/models/style/presentation_theme.dart';
import 'package:ky_slide/services/slide_layout_service.dart';
import 'package:ky_slide/states/presentation_provider.dart';

void main() {
  test('layout catalog includes every supported slide layout', () {
    expect(
      SlideLayoutService.recipes,
      hasLength(SlideLayoutType.values.length),
    );
    expect(
      SlideLayoutService.recipes.map((recipe) => recipe.type),
      containsAll(SlideLayoutType.values),
    );
  });

  test('title and content layout creates editable placeholders', () {
    final slide = SlideLayoutService.createSlide(
      type: SlideLayoutType.titleAndContent,
      presentation: _presentation(),
    );

    expect(slide.title, 'Title + Content');
    expect(slide.components, hasLength(2));
    expect(
      slide.components.every((c) => c.type == ComponentType.richText),
      true,
    );
    expect(slide.components.first.richText?.text, 'Click to add title');
    expect(slide.components.last.richText?.text, 'Click to add text');
    expect(slide.components.last.border, isNotNull);
  });

  test('comparison layout creates side-by-side placeholders', () {
    final slide = SlideLayoutService.createSlide(
      type: SlideLayoutType.comparison,
      presentation: _presentation(),
    );

    final texts = slide.components
        .map((component) => component.richText?.text)
        .whereType<String>()
        .toList();

    expect(slide.components, hasLength(5));
    expect(texts, containsAll(['Option A', 'Option B']));
    expect(
      slide.components[1].position.dx,
      lessThan(slide.components[2].position.dx),
    );
  });

  test('provider inserts a layout after the current slide', () {
    final notifier = PresentationNotifier(initialPresentation: _presentation());

    notifier.addSlide();
    notifier.setCurrentSlide(0);
    notifier.addSlideFromLayout(SlideLayoutType.sectionHeader);

    expect(notifier.state.slides, hasLength(3));
    expect(notifier.state.currentSlideIndex, 1);
    expect(notifier.state.slides[1].title, 'Section Header');
  });
}

Presentation _presentation() {
  return Presentation(
    id: 'layout-test',
    title: 'Layout Test',
    slides: [Slide(id: 'slide-test', components: [], title: 'Title Slide')],
    theme: PresentationTheme(
      id: 'layout-theme',
      name: 'Layout Theme',
      primaryColor: const Color(0xFF2563EB),
      secondaryColor: const Color(0xFF14B8A6),
      backgroundColor: const Color(0xFF0F172A),
      textColor: Colors.white,
      titleStyle: const TextStyle(color: Colors.white, fontSize: 48),
      bodyStyle: const TextStyle(color: Colors.white70, fontSize: 20),
      colorPalette: const [
        Color(0xFF2563EB),
        Color(0xFF14B8A6),
        Color(0xFFF59E0B),
      ],
    ),
  );
}
