import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/models/component.dart';
import 'package:ky_slide/models/presentation.dart';
import 'package:ky_slide/models/slide.dart';
import 'package:ky_slide/models/slide_template.dart';
import 'package:ky_slide/models/style/presentation_theme.dart';
import 'package:ky_slide/services/slide_template_service.dart';
import 'package:ky_slide/states/presentation_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('catalog exposes practical feature slide recipes', () {
    expect(SlideTemplateService.recipes, hasLength(4));
    expect(
      SlideTemplateService.recipes.map((recipe) => recipe.type),
      containsAll(SlideTemplateType.values),
    );
    expect(
      SlideTemplateService.recipes.map((recipe) => recipe.category),
      containsAll(SlideTemplateCategory.values),
    );
  });

  test('filterRecipes matches recipe names, summaries, and action labels', () {
    expect(
      SlideTemplateService.filterRecipes('metric').map((recipe) => recipe.type),
      [SlideTemplateType.metricStory],
    );
    expect(
      SlideTemplateService.filterRecipes(
        'side-by-side',
      ).map((recipe) => recipe.type),
      [SlideTemplateType.comparison],
    );
    expect(
      SlideTemplateService.filterRecipes(
        'add agenda',
      ).map((recipe) => recipe.type),
      [SlideTemplateType.agenda],
    );
    expect(SlideTemplateService.filterRecipes('unknown'), isEmpty);
  });

  test('filterRecipes combines category and search filters', () {
    expect(
      SlideTemplateService.filterRecipes(
        '',
        category: SlideTemplateCategory.metrics,
      ).map((recipe) => recipe.type),
      [SlideTemplateType.metricStory],
    );
    expect(
      SlideTemplateService.filterRecipes(
        'side-by-side',
        category: SlideTemplateCategory.decision,
      ).map((recipe) => recipe.type),
      [SlideTemplateType.comparison],
    );
    expect(
      SlideTemplateService.filterRecipes(
        'cover',
        category: SlideTemplateCategory.metrics,
      ),
      isEmpty,
    );
  });

  test('categoryCounts groups query matches by template category', () {
    expect(SlideTemplateService.categoryCounts(''), {
      SlideTemplateCategory.cover: 1,
      SlideTemplateCategory.structure: 1,
      SlideTemplateCategory.metrics: 1,
      SlideTemplateCategory.decision: 1,
    });
    expect(SlideTemplateService.categoryCounts('metric'), {
      SlideTemplateCategory.cover: 0,
      SlideTemplateCategory.structure: 0,
      SlideTemplateCategory.metrics: 1,
      SlideTemplateCategory.decision: 0,
    });
  });

  test('metric story template creates a chart-backed slide', () {
    final notifier = PresentationNotifier(initialPresentation: _presentation());
    final presentation = notifier.state;
    final recipe = SlideTemplateService.recipeFor(
      SlideTemplateType.metricStory,
    );

    final slide = SlideTemplateService.createSlide(
      type: SlideTemplateType.metricStory,
      presentation: presentation,
    );

    expect(slide.title, recipe.name);
    expect(slide.components, hasLength(recipe.componentCount));
    expect(
      slide.components.any(
        (component) => component.type == ComponentType.chart,
      ),
      isTrue,
    );
  });

  test('customization replaces generated slide copy', () {
    final customization =
        SlideTemplateCustomization.defaultsFor(
          SlideTemplateType.executiveCover,
        ).copyWith(
          headline: 'Launch the merchant command center',
          footer: 'Prepared for product council',
        );

    final slide = SlideTemplateService.createSlide(
      type: SlideTemplateType.executiveCover,
      presentation: _presentation(),
      customization: customization,
    );
    final text = _slideText(slide);

    expect(text, contains('Launch the merchant command center'));
    expect(text, contains('Prepared for product council'));
  });

  test('provider inserts a template after the current slide', () {
    final notifier = PresentationNotifier(initialPresentation: _presentation());

    notifier.addSlide();
    notifier.setCurrentSlide(0);
    notifier.addSlideFromTemplate(SlideTemplateType.comparison);

    expect(notifier.state.slides, hasLength(3));
    expect(notifier.state.currentSlideIndex, 1);
    expect(notifier.state.slides[1].title, 'Comparison Board');
  });

  test('provider inserts customized template content', () {
    final notifier = PresentationNotifier(initialPresentation: _presentation());
    final customization = SlideTemplateCustomization.defaultsFor(
      SlideTemplateType.comparison,
    ).copyWith(headline: 'Choose the rollout path');

    notifier.addSlideFromTemplate(
      SlideTemplateType.comparison,
      customization: customization,
    );

    expect(
      _slideText(notifier.state.slides[1]),
      contains('Choose the rollout path'),
    );
  });
}

String _slideText(Slide slide) {
  return slide.components
      .map((component) => component.richText?.text ?? '')
      .where((text) => text.isNotEmpty)
      .join('\n');
}

Presentation _presentation() {
  return Presentation(
    id: 'presentation-test',
    title: 'Test Presentation',
    slides: [Slide(id: 'slide-test', components: [], title: 'Title Slide')],
    theme: PresentationTheme(
      id: 'test-theme',
      name: 'Test Theme',
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
        Color(0xFFEC4899),
      ],
    ),
  );
}
