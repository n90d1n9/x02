import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/models/component.dart';
import 'package:ky_slide/models/presentation.dart';
import 'package:ky_slide/models/presentation_component.dart';
import 'package:ky_slide/models/slide.dart';
import 'package:ky_slide/models/slide_layout.dart';
import 'package:ky_slide/models/slide_template.dart';
import 'package:ky_slide/models/style/presentation_theme.dart';
import 'package:ky_slide/services/slide_layout_service.dart';
import 'package:ky_slide/services/slide_template_service.dart';
import 'package:ky_slide/states/component_provider.dart';
import 'package:ky_slide/states/history_provider.dart';
import 'package:ky_slide/states/presentation_provider.dart';
import 'package:ky_slide/states/slide_actions_provider.dart';

void main() {
  test('adds duplicates and deletes slides with history labels', () {
    final container = _container();
    addTearDown(container.dispose);
    container.read(selectedComponentProvider.notifier).state = 'title';
    final actions = container.read(slideActionsProvider);

    final newIndex = actions.addSlide();

    expect(newIndex, 2);
    expect(container.read(presentationProvider).slides.length, 3);
    expect(container.read(presentationProvider).currentSlideIndex, 2);
    expect(container.read(selectedComponentProvider), isNull);
    expect(container.read(historyProvider).undoLabel, 'Add slide');

    expect(actions.duplicateSlide(), isTrue);

    expect(container.read(presentationProvider).slides.length, 4);
    expect(container.read(presentationProvider).currentSlideIndex, 3);
    expect(container.read(historyProvider).undoLabel, 'Duplicate slide');

    expect(actions.deleteSlide(), isTrue);

    expect(container.read(presentationProvider).slides.length, 3);
    expect(container.read(presentationProvider).currentSlideIndex, 2);
    expect(container.read(historyProvider).undoLabel, 'Delete slide');
  });

  test('refuses invalid slide deletes and moves without history churn', () {
    final container = _container(slides: 1);
    addTearDown(container.dispose);
    final actions = container.read(slideActionsProvider);

    expect(actions.canDeleteCurrentSlide, isFalse);
    expect(actions.deleteSlide(), isFalse);
    expect(actions.duplicateSlide(index: 99), isFalse);
    expect(actions.moveSlide(0, 0), isFalse);
    expect(container.read(historyProvider).entries, isEmpty);
  });

  test(
    'duplicates and deletes selected slides with single history entries',
    () {
      final container = _container(slides: 4);
      addTearDown(container.dispose);
      container.read(selectedComponentProvider.notifier).state = 'title';
      final actions = container.read(slideActionsProvider);

      expect(actions.duplicateSlides([0, 2, 99]), isTrue);

      var presentation = container.read(presentationProvider);
      expect(presentation.slides.map((slide) => slide.title), [
        'Slide 0',
        'Slide 0 (Copy)',
        'Slide 1',
        'Slide 2',
        'Slide 2 (Copy)',
        'Slide 3',
      ]);
      expect(presentation.currentSlideIndex, 4);
      expect(container.read(selectedComponentProvider), isNull);
      expect(container.read(historyProvider).undoLabel, 'Duplicate slides');

      expect(actions.deleteSlides([1, 3]), isTrue);

      presentation = container.read(presentationProvider);
      expect(presentation.slides.map((slide) => slide.title), [
        'Slide 0',
        'Slide 1',
        'Slide 2 (Copy)',
        'Slide 3',
      ]);
      expect(container.read(historyProvider).undoLabel, 'Delete slides');

      final historyLength = container.read(historyProvider).entries.length;
      expect(actions.deleteSlides([0, 1, 2, 3]), isFalse);
      expect(container.read(historyProvider).entries, hasLength(historyLength));
    },
  );

  test('moves selected slides with single history entries', () {
    final container = _container(slides: 5);
    addTearDown(container.dispose);
    final actions = container.read(slideActionsProvider);

    expect(actions.moveSlidesEarlier([2, 3]), isTrue);

    var presentation = container.read(presentationProvider);
    expect(presentation.slides.map((slide) => slide.title), [
      'Slide 0',
      'Slide 2',
      'Slide 3',
      'Slide 1',
      'Slide 4',
    ]);
    expect(container.read(historyProvider).undoLabel, 'Move slides earlier');

    expect(actions.moveSlidesLater([1, 2]), isTrue);

    presentation = container.read(presentationProvider);
    expect(presentation.slides.map((slide) => slide.title), [
      'Slide 0',
      'Slide 1',
      'Slide 2',
      'Slide 3',
      'Slide 4',
    ]);
    expect(container.read(historyProvider).undoLabel, 'Move slides later');

    final historyLength = container.read(historyProvider).entries.length;
    expect(actions.moveSlidesEarlier([0, 1]), isFalse);
    expect(container.read(historyProvider).entries, hasLength(historyLength));
  });

  test('adds template slides through the shared slide action path', () {
    final container = _container();
    addTearDown(container.dispose);
    container.read(selectedComponentProvider.notifier).state = 'title';
    final actions = container.read(slideActionsProvider);

    final newIndex = actions.addTemplateSlide(SlideTemplateType.metricStory);
    final presentation = container.read(presentationProvider);

    expect(newIndex, 1);
    expect(presentation.slides.length, 3);
    expect(presentation.currentSlideIndex, 1);
    expect(
      presentation.slides[1].title,
      SlideTemplateService.recipeFor(SlideTemplateType.metricStory).name,
    );
    expect(container.read(selectedComponentProvider), isNull);
    expect(container.read(historyProvider).undoLabel, 'Add template slide');
  });

  test('adds layout slides through the shared slide action path', () {
    final container = _container();
    addTearDown(container.dispose);
    container.read(selectedComponentProvider.notifier).state = 'title';
    final actions = container.read(slideActionsProvider);

    final newIndex = actions.addLayoutSlide(SlideLayoutType.twoColumn);
    final presentation = container.read(presentationProvider);

    expect(newIndex, 1);
    expect(presentation.slides.length, 3);
    expect(presentation.currentSlideIndex, 1);
    expect(
      presentation.slides[1].title,
      SlideLayoutService.recipeFor(SlideLayoutType.twoColumn).name,
    );
    expect(presentation.slides[1].components, hasLength(3));
    expect(container.read(selectedComponentProvider), isNull);
    expect(container.read(historyProvider).undoLabel, 'Add layout slide');
  });
}

ProviderContainer _container({int slides = 2}) {
  return ProviderContainer(
    overrides: [
      presentationProvider.overrideWith(
        (ref) => PresentationNotifier(
          initialPresentation: _presentation(slides: slides),
        ),
      ),
    ],
  );
}

Presentation _presentation({required int slides}) {
  return Presentation(
    id: 'slide-actions-test',
    title: 'Slide Actions Test',
    slides: [
      for (var index = 0; index < slides; index++)
        Slide(
          id: 'slide-$index',
          title: 'Slide $index',
          components: index == 0
              ? [
                  PresentationComponent(
                    id: 'title',
                    type: ComponentType.richText,
                    position: const Offset(40, 40),
                    size: const Size(240, 80),
                  ),
                ]
              : [],
        ),
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
      colorPalette: const [
        Color(0xFF2563EB),
        Color(0xFF14B8A6),
        Color(0xFFF59E0B),
      ],
    ),
  );
}
