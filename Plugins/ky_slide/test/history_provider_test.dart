import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/models/presentation.dart';
import 'package:ky_slide/models/sidebar_menu_item.dart';
import 'package:ky_slide/models/slide.dart';
import 'package:ky_slide/models/slide_navigator_density.dart';
import 'package:ky_slide/models/style/presentation_theme.dart';
import 'package:ky_slide/services/slide_template_service.dart';
import 'package:ky_slide/states/history_provider.dart';
import 'package:ky_slide/states/presentation_provider.dart';
import 'package:ky_slide/states/sidebar_panel_provider.dart';
import 'package:ky_slide/widgets/slide_panel.dart';

void main() {
  test('recordChange makes the first mutation undoable', () {
    final container = _container(_presentation(['Opening']));
    addTearDown(container.dispose);

    final before = container.read(presentationProvider);
    container.read(presentationProvider.notifier).addSlide();
    final after = container.read(presentationProvider);

    container
        .read(historyProvider.notifier)
        .recordChange(before: before, after: after, label: 'Add slide');

    var history = container.read(historyProvider);
    expect(history.canUndo, isTrue);
    expect(history.undoLabel, 'Add slide');
    expect(container.read(presentationProvider).slides.length, 2);

    container.read(historyProvider.notifier).undo();

    expect(container.read(presentationProvider).slides.length, 1);
    history = container.read(historyProvider);
    expect(history.canRedo, isTrue);
    expect(history.redoLabel, 'Add slide');

    container.read(historyProvider.notifier).redo();

    expect(container.read(presentationProvider).slides.length, 2);
  });

  test('recordChange clears redo history when branching after undo', () {
    final container = _container(_presentation(['Opening']));
    addTearDown(container.dispose);

    _recordedMutation(
      container,
      'Add slide',
      (notifier) => notifier.addSlide(),
    );
    _recordedMutation(
      container,
      'Duplicate slide',
      (notifier) => notifier.duplicateSlide(0),
    );

    container.read(historyProvider.notifier).undo();

    expect(container.read(presentationProvider).slides.length, 2);
    expect(container.read(historyProvider).canRedo, isTrue);
    expect(container.read(historyProvider).redoLabel, 'Duplicate slide');

    _recordedMutation(
      container,
      'Delete slide',
      (notifier) => notifier.deleteSlide(1),
    );

    final history = container.read(historyProvider);

    expect(container.read(presentationProvider).slides.length, 1);
    expect(history.canRedo, isFalse);
    expect(history.undoLabel, 'Delete slide');
    expect(history.states.length, 3);
  });

  test('jumpTo restores an entry without clearing redo history', () {
    final container = _container(_presentation(['Opening']));
    addTearDown(container.dispose);

    _recordedMutation(
      container,
      'Add slide',
      (notifier) => notifier.addSlide(),
    );
    _recordedMutation(
      container,
      'Duplicate slide',
      (notifier) => notifier.duplicateSlide(0),
    );

    expect(container.read(presentationProvider).slides.length, 3);

    container.read(historyProvider.notifier).jumpTo(1);

    final history = container.read(historyProvider);

    expect(container.read(presentationProvider).slides.length, 2);
    expect(history.canUndo, isTrue);
    expect(history.canRedo, isTrue);
    expect(history.undoLabel, 'Add slide');
    expect(history.redoLabel, 'Duplicate slide');
    expect(history.states.length, 3);
  });

  test('recordChange ignores mutations that leave state unchanged', () {
    final container = _container(_presentation(['Opening']));
    addTearDown(container.dispose);

    _recordedMutation(
      container,
      'Move slide',
      (notifier) => notifier.moveSlide(0, 0),
    );

    expect(container.read(historyProvider).states, isEmpty);
  });

  testWidgets('slide panel new slide action records an undo checkpoint', (
    tester,
  ) async {
    final container = _container(_presentation(['Opening']));
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 320, height: 700, child: SlidePanel()),
          ),
        ),
      ),
    );

    await tester.tap(find.text('New Slide'));
    await tester.pump();

    expect(container.read(presentationProvider).slides.length, 2);
    expect(container.read(historyProvider).canUndo, isTrue);
    expect(container.read(historyProvider).undoLabel, 'Add slide');

    container.read(historyProvider.notifier).undo();
    await tester.pump();

    expect(container.read(presentationProvider).slides.length, 1);
  });

  testWidgets('slide panel new slide menu reaches design assist', (
    tester,
  ) async {
    final container = _container(_presentation(['Opening']));
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 320, height: 700, child: SlidePanel()),
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('New slide options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Browse templates'));
    await tester.pumpAndSettle();

    expect(container.read(activeSidebarMenuProvider), SidebarMenuItem.design);
    expect(find.text('Design Assist'), findsOneWidget);
  });

  testWidgets('slide panel new slide menu inserts template slides', (
    tester,
  ) async {
    final container = _container(_presentation(['Opening']));
    addTearDown(container.dispose);
    final templateName = SlideTemplateService.recipes.first.name;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 320, height: 700, child: SlidePanel()),
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('New slide options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(templateName));
    await tester.pumpAndSettle();

    final presentation = container.read(presentationProvider);

    expect(presentation.slides.length, 2);
    expect(presentation.currentSlideIndex, 1);
    expect(presentation.slides[1].title, templateName);
    expect(container.read(historyProvider).undoLabel, 'Add template slide');
  });

  testWidgets('slide panel new slide menu inserts layout slides', (
    tester,
  ) async {
    final container = _container(_presentation(['Opening']));
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 320, height: 700, child: SlidePanel()),
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('New slide options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Two Columns'));
    await tester.pumpAndSettle();

    final presentation = container.read(presentationProvider);

    expect(presentation.slides.length, 2);
    expect(presentation.currentSlideIndex, 1);
    expect(presentation.slides[1].title, 'Two Columns');
    expect(presentation.slides[1].components, hasLength(3));
    expect(container.read(historyProvider).undoLabel, 'Add layout slide');
  });

  testWidgets('slide panel filters slide thumbnails and clears search', (
    tester,
  ) async {
    final container = _container(
      _presentation(['Opening', 'Follow up', 'Decision']),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 320, height: 700, child: SlidePanel()),
          ),
        ),
      ),
    );

    expect(find.text('Opening'), findsOneWidget);
    expect(find.text('Decision'), findsOneWidget);
    expect(find.text('3 slides'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'decision');
    await tester.pumpAndSettle();

    expect(container.read(slideSearchQueryProvider), 'decision');
    expect(find.text('Opening'), findsNothing);
    expect(find.text('Decision'), findsOneWidget);
    expect(find.text('1 match'), findsOneWidget);

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();

    expect(container.read(slideSearchQueryProvider), isEmpty);
    expect(find.text('Opening'), findsOneWidget);
    expect(find.text('Decision'), findsOneWidget);
    expect(find.text('3 slides'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'missing');
    await tester.pumpAndSettle();

    expect(find.text('No matching slides'), findsOneWidget);

    await tester.tap(find.text('Clear search'));
    await tester.pumpAndSettle();

    expect(container.read(slideSearchQueryProvider), isEmpty);
    expect(find.text('Opening'), findsOneWidget);
  });

  testWidgets('slide panel switches thumbnail density from the rail', (
    tester,
  ) async {
    final container = _container(_presentation(['Opening', 'Follow up']));
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 320, height: 700, child: SlidePanel()),
          ),
        ),
      ),
    );

    expect(
      container.read(slideNavigatorDensityProvider),
      SlideNavigatorDensity.comfortable,
    );

    await tester.tap(find.byTooltip('Compact thumbnails'));
    await tester.pumpAndSettle();

    expect(
      container.read(slideNavigatorDensityProvider),
      SlideNavigatorDensity.compact,
    );
  });

  testWidgets('slide panel history menu shows labeled actions and undo', (
    tester,
  ) async {
    final container = _container(_presentation(['Opening']));
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 320, height: 700, child: SlidePanel()),
          ),
        ),
      ),
    );

    await tester.tap(find.text('New Slide'));
    await tester.pump();

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    expect(find.text('History'), findsWidgets);
    expect(find.text('Add slide'), findsWidgets);
    expect(find.text('2 slides - Slide 2/2: Slide 2'), findsOneWidget);
    expect(find.text('Current'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.undo));
    await tester.pumpAndSettle();

    expect(container.read(presentationProvider).slides.length, 1);
    expect(container.read(historyProvider).canRedo, isTrue);
    expect(container.read(historyProvider).redoLabel, 'Add slide');
  });

  testWidgets('slide panel history menu restores selected action', (
    tester,
  ) async {
    final container = _container(_presentation(['Opening']));
    addTearDown(container.dispose);

    _recordedMutation(
      container,
      'Add slide',
      (notifier) => notifier.addSlide(),
    );
    _recordedMutation(
      container,
      'Duplicate slide',
      (notifier) => notifier.duplicateSlide(0),
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 320, height: 700, child: SlidePanel()),
          ),
        ),
      ),
    );

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    expect(find.text('Add slide'), findsOneWidget);
    expect(find.text('Duplicate slide'), findsWidgets);

    await tester.tap(find.text('Add slide'));
    await tester.pumpAndSettle();

    final history = container.read(historyProvider);

    expect(container.read(presentationProvider).slides.length, 2);
    expect(history.currentIndex, 1);
    expect(history.canRedo, isTrue);
    expect(history.redoLabel, 'Duplicate slide');
    expect(find.text('Current'), findsOneWidget);
  });

  testWidgets('slide panel sidebar menu reaches design and outline', (
    tester,
  ) async {
    final container = _container(_presentation(['Opening', 'Follow up']));
    addTearDown(container.dispose);
    final firstTemplateName = SlideTemplateService.recipes.first.name;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 320, height: 700, child: SlidePanel()),
          ),
        ),
      ),
    );

    expect(find.text('Slides'), findsOneWidget);
    expect(find.text('Opening'), findsOneWidget);
    expect(find.text(firstTemplateName), findsNothing);

    await tester.tap(find.text('Design'));
    await tester.pumpAndSettle();

    expect(find.text('Design Assist'), findsOneWidget);
    expect(find.text(firstTemplateName), findsOneWidget);

    await tester.tap(find.text('Outline'));
    await tester.pumpAndSettle();

    expect(find.text('Outline'), findsWidgets);
    expect(find.text('Follow up'), findsOneWidget);

    await tester.tap(find.text('File'));
    await tester.pumpAndSettle();

    expect(find.text('PowerPoint Files'), findsOneWidget);
    expect(find.text('Import PPTX'), findsOneWidget);
    expect(find.text('Export PPTX'), findsOneWidget);
  });

  testWidgets('slide panel explains why the last slide cannot be deleted', (
    tester,
  ) async {
    final container = _container(_presentation(['Opening']));
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 320, height: 700, child: SlidePanel()),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep last slide'));
    await tester.pumpAndSettle();

    expect(
      find.text('A presentation needs at least one slide.'),
      findsOneWidget,
    );
    expect(container.read(presentationProvider).slides.length, 1);
    expect(container.read(historyProvider).states, isEmpty);
  });
}

ProviderContainer _container(Presentation presentation) {
  return ProviderContainer(
    overrides: [
      presentationProvider.overrideWith(
        (ref) => PresentationNotifier(initialPresentation: presentation),
      ),
    ],
  );
}

void _recordedMutation(
  ProviderContainer container,
  String label,
  void Function(PresentationNotifier notifier) mutate,
) {
  container
      .read(historyProvider.notifier)
      .recordPresentationMutation(mutate, label: label);
}

Presentation _presentation(List<String> titles) {
  return Presentation(
    id: 'history-test',
    title: 'History Test',
    slides: [
      for (final (index, title) in titles.indexed)
        Slide(id: 'slide-$index', title: title, components: []),
    ],
    theme: PresentationTheme(
      id: 'history-theme',
      name: 'History Theme',
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
