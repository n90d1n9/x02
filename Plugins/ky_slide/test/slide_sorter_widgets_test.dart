import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/models/component.dart';
import 'package:ky_slide/models/editor_ribbon_tab.dart';
import 'package:ky_slide/models/presentation.dart';
import 'package:ky_slide/models/presentation_component.dart';
import 'package:ky_slide/models/slide.dart';
import 'package:ky_slide/models/slide_sorter_density.dart';
import 'package:ky_slide/models/style/presentation_theme.dart';
import 'package:ky_slide/screens/presentation_editor.dart';
import 'package:ky_slide/states/editor_view_provider.dart';
import 'package:ky_slide/states/history_provider.dart';
import 'package:ky_slide/states/presentation_provider.dart';
import 'package:ky_slide/widgets/slide_sorter/slide_sorter_density_control.dart';
import 'package:ky_slide/widgets/slide_sorter/slide_sorter_grid.dart';
import 'package:ky_slide/widgets/slide_sorter/slide_sorter_overlay.dart';
import 'package:ky_slide/widgets/slide_sorter/slide_sorter_tile.dart';

void main() {
  testWidgets('slide sorter tile dispatches selection and quick actions', (
    tester,
  ) async {
    var selected = false;
    var toggledSelection = false;
    var duplicated = false;
    var deleted = false;
    var movedEarlier = false;
    var movedLater = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          body: Center(
            child: SizedBox(
              width: 260,
              height: 230,
              child: SlideSorterTile(
                slide: _slide('slide-1', 'Opening'),
                index: 0,
                isSelected: true,
                isBatchSelected: false,
                theme: _theme(),
                slideSize: const Size(1920, 1080),
                canDelete: true,
                canMoveEarlier: true,
                canMoveLater: true,
                onSelect: () => selected = true,
                onToggleSelection: (_) => toggledSelection = true,
                onDuplicate: () => duplicated = true,
                onDelete: () => deleted = true,
                onMoveEarlier: () => movedEarlier = true,
                onMoveLater: () => movedLater = true,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Opening'), findsOneWidget);

    await tester.tap(find.byTooltip('Open slide 1'));
    await tester.tap(find.byTooltip('Select slide 1'));
    await tester.tap(find.byTooltip('Duplicate slide 1'));
    await tester.tap(find.byTooltip('Delete slide 1'));
    await tester.tap(find.byTooltip('Move slide 1 earlier'));
    await tester.tap(find.byTooltip('Move slide 1 later'));
    await tester.pumpAndSettle();

    expect(selected, isTrue);
    expect(toggledSelection, isTrue);
    expect(duplicated, isTrue);
    expect(deleted, isTrue);
    expect(movedEarlier, isTrue);
    expect(movedLater, isTrue);
  });

  testWidgets('slide sorter grid reorders slides with drag and drop', (
    tester,
  ) async {
    int? movedOldIndex;
    int? movedNewIndex;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          body: SizedBox(
            width: 760,
            height: 520,
            child: SlideSorterGrid(
              slides: _presentation().slides,
              visibleIndexes: const [0, 1, 2],
              currentSlideIndex: 0,
              selectedSlideIds: const {},
              theme: _theme(),
              slideSize: const Size(1920, 1080),
              canDeleteSlides: true,
              onSelectSlide: (_) {},
              onToggleSlideSelection: (_, _) {},
              onDuplicateSlide: (_) {},
              onDeleteSlide: (_) {},
              onMoveSlide: (oldIndex, newIndex) {
                movedOldIndex = oldIndex;
                movedNewIndex = newIndex;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final source = tester.getCenter(find.byTooltip('Open slide 1'));
    final target = tester.getCenter(find.byTooltip('Open slide 3'));
    final gesture = await tester.startGesture(source);

    await tester.pump();
    await gesture.moveTo(Offset.lerp(source, target, 0.5)!);
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.moveTo(target);
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(movedOldIndex, 0);
    expect(movedNewIndex, 2);
  });

  testWidgets('slide sorter density control selects grid density', (
    tester,
  ) async {
    var density = SlideSorterDensity.balanced;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          body: StatefulBuilder(
            builder: (context, setState) {
              return Center(
                child: SlideSorterDensityControl(
                  value: density,
                  accentColor: const Color(0xFF38BDF8),
                  onChanged: (value) {
                    setState(() => density = value);
                  },
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Compact slide grid'));
    await tester.pumpAndSettle();

    expect(density, SlideSorterDensity.compact);

    await tester.tap(find.byTooltip('Roomy slide grid'));
    await tester.pumpAndSettle();

    expect(density, SlideSorterDensity.roomy);
  });

  testWidgets('slide sorter overlay filters, selects, duplicates, and closes', (
    tester,
  ) async {
    final container = _container();
    addTearDown(container.dispose);
    container.read(slideSorterVisibleProvider.notifier).state = true;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            backgroundColor: Color(0xFF020617),
            body: SizedBox(
              width: 980,
              height: 680,
              child: SlideSorterOverlay(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Slide Board'), findsOneWidget);
    expect(find.text('Opening'), findsOneWidget);
    expect(find.text('Plan'), findsOneWidget);
    expect(find.text('Summary'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Plan');
    await tester.pumpAndSettle();

    expect(find.text('Opening'), findsNothing);
    expect(find.text('Plan'), findsWidgets);

    await tester.tap(find.byTooltip('Open slide 2'));
    await tester.pumpAndSettle();

    expect(container.read(presentationProvider).currentSlideIndex, 1);

    await tester.tap(find.byTooltip('Duplicate slide 2'));
    await tester.pumpAndSettle();

    expect(container.read(presentationProvider).slides, hasLength(4));
    expect(container.read(presentationProvider).currentSlideIndex, 2);

    await tester.tap(find.text('Open current'));
    await tester.pumpAndSettle();

    expect(container.read(slideSorterVisibleProvider), isFalse);
  });

  testWidgets('slide sorter overlay manages selected slides in batches', (
    tester,
  ) async {
    final container = _container();
    addTearDown(container.dispose);
    container.read(slideSorterVisibleProvider.notifier).state = true;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            backgroundColor: Color(0xFF020617),
            body: SizedBox(
              width: 980,
              height: 680,
              child: SlideSorterOverlay(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('0 selected'), findsOneWidget);

    await tester.tap(find.byTooltip('Select slide 1'));
    await tester.pumpAndSettle();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.tap(find.byTooltip('Select slide 3'));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pumpAndSettle();

    expect(find.text('3 selected'), findsOneWidget);

    await tester.tap(find.byTooltip('Duplicate selected slides'));
    await tester.pumpAndSettle();

    expect(container.read(presentationProvider).slides, hasLength(6));
    expect(container.read(historyProvider).undoLabel, 'Duplicate slides');
    expect(find.text('3 selected'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete selected slides'));
    await tester.pumpAndSettle();

    expect(container.read(presentationProvider).slides, hasLength(3));
    expect(container.read(historyProvider).undoLabel, 'Delete slides');
    expect(find.text('0 selected'), findsOneWidget);
  });

  testWidgets('slide sorter overlay moves selected slides in batches', (
    tester,
  ) async {
    final container = _container();
    addTearDown(container.dispose);
    container.read(slideSorterVisibleProvider.notifier).state = true;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            backgroundColor: Color(0xFF020617),
            body: SizedBox(
              width: 980,
              height: 680,
              child: SlideSorterOverlay(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Select slide 2'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Select slide 3'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Move selected slides earlier'));
    await tester.pumpAndSettle();

    expect(
      container.read(presentationProvider).slides.map((slide) => slide.title),
      ['Plan', 'Summary', 'Opening'],
    );
    expect(container.read(historyProvider).undoLabel, 'Move slides earlier');
    expect(find.text('2 selected'), findsOneWidget);

    await tester.tap(find.byTooltip('Move selected slides later'));
    await tester.pumpAndSettle();

    expect(
      container.read(presentationProvider).slides.map((slide) => slide.title),
      ['Opening', 'Plan', 'Summary'],
    );
    expect(container.read(historyProvider).undoLabel, 'Move slides later');
    expect(find.text('2 selected'), findsOneWidget);
  });

  testWidgets('slide sorter overlay handles keyboard selection shortcuts', (
    tester,
  ) async {
    final container = _container();
    addTearDown(container.dispose);
    container.read(slideSorterVisibleProvider.notifier).state = true;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            backgroundColor: Color(0xFF020617),
            body: SizedBox(
              width: 980,
              height: 680,
              child: SlideSorterOverlay(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _sendShortcut(tester, LogicalKeyboardKey.keyA, control: true);

    expect(find.text('3 selected'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.text('0 selected'), findsOneWidget);
    expect(container.read(slideSorterVisibleProvider), isTrue);

    await tester.tap(find.byTooltip('Select slide 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Select slide 2'));
    await tester.pumpAndSettle();

    await _sendShortcut(tester, LogicalKeyboardKey.keyD, control: true);

    expect(container.read(presentationProvider).slides, hasLength(5));
    expect(container.read(historyProvider).undoLabel, 'Duplicate slides');
    expect(find.text('2 selected'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pumpAndSettle();

    expect(container.read(presentationProvider).slides, hasLength(3));
    expect(container.read(historyProvider).undoLabel, 'Delete slides');
    expect(find.text('0 selected'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(container.read(slideSorterVisibleProvider), isFalse);
  });

  testWidgets('slide sorter overlay supports keyboard slide navigation', (
    tester,
  ) async {
    final container = _container();
    addTearDown(container.dispose);
    container.read(slideSorterVisibleProvider.notifier).state = true;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            backgroundColor: Color(0xFF020617),
            body: SizedBox(
              width: 980,
              height: 680,
              child: SlideSorterOverlay(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();

    expect(container.read(presentationProvider).currentSlideIndex, 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pumpAndSettle();

    expect(container.read(presentationProvider).currentSlideIndex, 0);

    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pumpAndSettle();

    expect(container.read(presentationProvider).currentSlideIndex, 2);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();

    expect(container.read(presentationProvider).currentSlideIndex, 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();

    expect(container.read(presentationProvider).currentSlideIndex, 2);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();

    expect(find.text('1 selected'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(container.read(slideSorterVisibleProvider), isFalse);
  });

  testWidgets('presentation editor opens slide board from the view ribbon', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1600, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = _container();
    addTearDown(container.dispose);
    container.read(activeRibbonTabProvider.notifier).state =
        EditorRibbonTab.view;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: PresentationEditor()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open Slide Sorter'));
    await tester.pumpAndSettle();

    expect(container.read(slideSorterVisibleProvider), isTrue);
    expect(find.text('Slide Board'), findsOneWidget);

    await tester.tap(find.byTooltip('Open slide 3'));
    await tester.pumpAndSettle();

    expect(container.read(presentationProvider).currentSlideIndex, 2);

    await tester.tap(find.byTooltip('Close slide board'));
    await tester.pumpAndSettle();

    expect(container.read(slideSorterVisibleProvider), isFalse);
  });
}

Future<void> _sendShortcut(
  WidgetTester tester,
  LogicalKeyboardKey key, {
  bool control = false,
  bool meta = false,
}) async {
  if (control) {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  }
  if (meta) {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
  }

  await tester.sendKeyEvent(key);

  if (meta) {
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
  }
  if (control) {
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  }

  await tester.pumpAndSettle();
}

ProviderContainer _container() {
  return ProviderContainer(
    overrides: [
      presentationProvider.overrideWith(
        (ref) => PresentationNotifier(initialPresentation: _presentation()),
      ),
    ],
  );
}

Presentation _presentation() {
  return Presentation(
    id: 'slide-sorter-test',
    title: 'Sorter Test',
    slides: [
      _slide('slide-1', 'Opening'),
      _slide('slide-2', 'Plan'),
      _slide('slide-3', 'Summary'),
    ],
    theme: _theme(),
  );
}

Slide _slide(String id, String title) {
  return Slide(
    id: id,
    title: title,
    backgroundColor: const Color(0xFF111827),
    components: [
      PresentationComponent(
        id: '$id-title',
        type: ComponentType.shape,
        position: const Offset(160, 120),
        size: const Size(840, 110),
        backgroundColor: Colors.white,
        zIndex: 1,
      ),
      PresentationComponent(
        id: '$id-accent',
        type: ComponentType.circle,
        position: const Offset(1080, 330),
        size: const Size(380, 380),
        backgroundColor: const Color(0xFF38BDF8),
        zIndex: 2,
      ),
    ],
  );
}

PresentationTheme _theme() {
  return PresentationTheme(
    id: 'slide-sorter-test-theme',
    name: 'Slide Sorter Test Theme',
    primaryColor: const Color(0xFF38BDF8),
    secondaryColor: const Color(0xFF14B8A6),
    backgroundColor: const Color(0xFF0F172A),
    textColor: Colors.white,
    titleStyle: const TextStyle(color: Colors.white, fontSize: 48),
    bodyStyle: const TextStyle(color: Colors.white70, fontSize: 20),
    colorPalette: const [Color(0xFF38BDF8), Color(0xFF14B8A6)],
  );
}
