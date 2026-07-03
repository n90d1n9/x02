import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/models/component.dart';
import 'package:ky_slide/models/presentation.dart';
import 'package:ky_slide/models/presentation_component.dart';
import 'package:ky_slide/models/rich_text_content.dart';
import 'package:ky_slide/models/slide.dart';
import 'package:ky_slide/models/style/presentation_theme.dart';
import 'package:ky_slide/states/command_palette_provider.dart';
import 'package:ky_slide/states/component_provider.dart';
import 'package:ky_slide/states/editor_view_provider.dart';
import 'package:ky_slide/states/history_provider.dart';
import 'package:ky_slide/states/presentation_provider.dart';
import 'package:ky_slide/widgets/editor/presentation_command_palette_overlay.dart';

void main() {
  testWidgets('presentation command palette duplicates the selected object', (
    tester,
  ) async {
    final container = _container();
    addTearDown(container.dispose);

    container.read(commandPaletteVisibleProvider.notifier).state = true;
    container.read(selectedComponentProvider.notifier).state = 'title';

    await _pumpCommandPalette(tester, container);

    await tester.enterText(_commandPaletteSearchField(), 'duplicate object');
    await tester.pump();

    expect(find.text('Cmd/Ctrl+D'), findsOneWidget);
    expect(find.text('Selected'), findsOneWidget);

    await tester.tap(_commandText('Duplicate Selected Object'));
    await tester.pump();

    final components = _components(container);
    final selectedId = container.read(selectedComponentProvider);

    expect(components.length, 2);
    expect(selectedId, isNotNull);
    expect(selectedId, isNot('title'));
    expect(
      components
          .firstWhere((component) => component.id == selectedId)
          .richText
          ?.text,
      'Quarterly update',
    );
    expect(container.read(commandPaletteVisibleProvider), isFalse);
    expect(container.read(historyProvider).undoLabel, 'Duplicate layer');
    expect(container.read(commandPaletteRecentCommandIdsProvider), [
      'duplicate-selected-object',
    ]);
  });

  testWidgets('presentation command palette toggles selected object state', (
    tester,
  ) async {
    final container = _container();
    addTearDown(container.dispose);

    container.read(commandPaletteVisibleProvider.notifier).state = true;
    container.read(selectedComponentProvider.notifier).state = 'title';

    await _pumpCommandPalette(tester, container);

    await tester.enterText(_commandPaletteSearchField(), 'lock object');
    await tester.pump();

    expect(find.text('Toggle'), findsOneWidget);

    await tester.tap(_commandText('Lock Selected Object'));
    await tester.pump();

    expect(_component(container, 'title').isLocked, isTrue);
    expect(container.read(commandPaletteVisibleProvider), isFalse);
    expect(container.read(historyProvider).undoLabel, 'Lock layer');
    expect(container.read(commandPaletteRecentCommandIdsProvider), [
      'toggle-selected-object-lock',
    ]);
  });

  testWidgets('presentation command palette adds a blank slide', (
    tester,
  ) async {
    final container = _container(slideCount: 2);
    addTearDown(container.dispose);

    container.read(commandPaletteVisibleProvider.notifier).state = true;

    await _pumpCommandPalette(tester, container);
    await tester.enterText(_commandPaletteSearchField(), 'new blank slide');
    await tester.pump();

    expect(find.text('Blank'), findsOneWidget);

    await tester.tap(_commandText('New Blank Slide'));
    await tester.pump();

    final presentation = container.read(presentationProvider);

    expect(presentation.slides.length, 3);
    expect(presentation.currentSlideIndex, 2);
    expect(presentation.slides.last.title, 'Slide 3');
    expect(container.read(commandPaletteVisibleProvider), isFalse);
    expect(container.read(historyProvider).undoLabel, 'Add slide');
    expect(container.read(commandPaletteRecentCommandIdsProvider), [
      'add-blank-slide',
    ]);
  });

  testWidgets('presentation command palette duplicates and moves a slide', (
    tester,
  ) async {
    final container = _container(slideCount: 2);
    addTearDown(container.dispose);

    container.read(commandPaletteVisibleProvider.notifier).state = true;

    await _pumpCommandPalette(tester, container);
    await tester.enterText(_commandPaletteSearchField(), 'duplicate current');
    await tester.pump();

    expect(find.text('Slide 1'), findsOneWidget);

    await tester.tap(_commandText('Duplicate Current Slide'));
    await tester.pump();

    var presentation = container.read(presentationProvider);

    expect(presentation.slides.map((slide) => slide.title), [
      'Intro',
      'Intro (Copy)',
      'Plan',
    ]);
    expect(presentation.currentSlideIndex, 1);
    expect(container.read(historyProvider).undoLabel, 'Duplicate slide');

    container.read(commandPaletteVisibleProvider.notifier).state = true;
    await _pumpCommandPalette(tester, container);
    await tester.enterText(_commandPaletteSearchField(), 'move slide later');
    await tester.pump();

    await tester.tap(_commandText('Move Slide Later'));
    await tester.pump();

    presentation = container.read(presentationProvider);

    expect(presentation.slides.map((slide) => slide.title), [
      'Intro',
      'Plan',
      'Intro (Copy)',
    ]);
    expect(presentation.currentSlideIndex, 2);
    expect(container.read(historyProvider).undoLabel, 'Move slide');
    expect(container.read(commandPaletteRecentCommandIdsProvider), [
      'move-current-slide-later',
      'duplicate-current-slide',
    ]);
  });

  testWidgets('presentation command palette disables deleting the last slide', (
    tester,
  ) async {
    final container = _container();
    addTearDown(container.dispose);

    container.read(commandPaletteVisibleProvider.notifier).state = true;

    await _pumpCommandPalette(tester, container);
    await tester.enterText(_commandPaletteSearchField(), 'delete current');
    await tester.pump();

    expect(_commandText('Delete Current Slide'), findsOneWidget);
    expect(_commandText('A deck needs at least one slide'), findsOneWidget);

    await tester.tap(_commandText('Delete Current Slide'));
    await tester.pump();

    expect(container.read(presentationProvider).slides.length, 1);
    expect(container.read(commandPaletteVisibleProvider), isTrue);
    expect(container.read(commandPaletteRecentCommandIdsProvider), isEmpty);
  });
}

Finder _commandText(String text) => find.text(text, findRichText: true);

Finder _commandPaletteSearchField() {
  return find.byWidgetPredicate((widget) {
    return widget is TextField &&
        widget.decoration?.hintText == 'Search commands';
  });
}

List<PresentationComponent> _components(ProviderContainer container) {
  final presentation = container.read(presentationProvider);
  return presentation.slides[presentation.currentSlideIndex].components;
}

PresentationComponent _component(ProviderContainer container, String id) {
  return _components(container).firstWhere((component) => component.id == id);
}

ProviderContainer _container({int slideCount = 1, int currentSlideIndex = 0}) {
  return ProviderContainer(
    overrides: [
      presentationProvider.overrideWith(
        (ref) => PresentationNotifier(
          initialPresentation: _presentation(
            slideCount: slideCount,
            currentSlideIndex: currentSlideIndex,
          ),
        ),
      ),
    ],
  );
}

Future<void> _pumpCommandPalette(
  WidgetTester tester,
  ProviderContainer container,
) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          body: Stack(
            children: [
              PresentationCommandPaletteOverlay(
                onShowThemes: () {},
                onShowEffects: () {},
                onPresent: () {},
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Presentation _presentation({
  required int slideCount,
  required int currentSlideIndex,
}) {
  return Presentation(
    id: 'presentation-command-palette-test',
    title: 'Command Palette Test',
    slides: [
      for (var index = 0; index < slideCount; index++)
        Slide(
          id: 'slide-$index',
          title: index == 0 ? 'Intro' : 'Plan',
          components: index == 0
              ? [
                  PresentationComponent(
                    id: 'title',
                    type: ComponentType.richText,
                    position: const Offset(40, 40),
                    size: const Size(240, 80),
                    richText: RichTextContent(
                      text: 'Quarterly update',
                      style: const TextStyle(color: Colors.white, fontSize: 24),
                    ),
                  ),
                ]
              : [],
        ),
    ],
    currentSlideIndex: currentSlideIndex,
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
