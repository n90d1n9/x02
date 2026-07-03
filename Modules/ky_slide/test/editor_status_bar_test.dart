import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/models/component.dart';
import 'package:ky_slide/models/editor_slide_insight.dart';
import 'package:ky_slide/models/presentation.dart';
import 'package:ky_slide/models/presentation_component.dart';
import 'package:ky_slide/models/slide.dart';
import 'package:ky_slide/models/style/presentation_theme.dart';
import 'package:ky_slide/states/component_provider.dart';
import 'package:ky_slide/states/editor_view_provider.dart';
import 'package:ky_slide/states/presentation_provider.dart';
import 'package:ky_slide/widgets/editor/editor_selection_geometry_chip.dart';
import 'package:ky_slide/widgets/editor/editor_slide_insight_chip.dart';
import 'package:ky_slide/widgets/editor/editor_status_bar.dart';
import 'package:ky_slide/widgets/editor/editor_status_bar_widgets.dart';
import 'package:ky_slide/widgets/editor/editor_status_view_switcher.dart';

void main() {
  testWidgets('editor status widgets render text and zoom controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          body: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                EditorStatusText('Selected: Hero title'),
                EditorStatusDivider(),
                EditorZoomIndicator(zoom: 1.25),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Selected: Hero title'), findsOneWidget);
    expect(find.text('125%'), findsOneWidget);
  });

  testWidgets('editor selection geometry chip renders frame metrics', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          body: Center(
            child: EditorSelectionGeometryChip(
              component: PresentationComponent(
                id: 'shape',
                type: ComponentType.shape,
                position: const Offset(42, 56),
                size: const Size(240, 120),
                rotation: 15,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byTooltip('Selection geometry'), findsOneWidget);
    expect(find.text('240 x 120'), findsOneWidget);
    expect(find.text('X 42 Y 56'), findsOneWidget);
    expect(find.text('15 deg'), findsOneWidget);
  });

  test('editor slide insight summarizes current slide edit state', () {
    final insight = EditorSlideInsight.fromSlide(
      Slide(
        id: 'slide',
        notes: 'Mention launch timing.',
        components: [
          _component('title'),
          _component('hidden', isVisible: false),
          _component('locked', isLocked: true),
        ],
      ),
    );

    expect(insight.objectLabel, '3 objects');
    expect(insight.hiddenLabel, '1 hidden object');
    expect(insight.lockedLabel, '1 locked object');
    expect(insight.notesLabel, 'Speaker notes');
    expect(insight.tooltipLabel, contains('Speaker notes'));
  });

  testWidgets('editor slide insight chip renders slide state badges', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          backgroundColor: Color(0xFF0F172A),
          body: Center(
            child: EditorSlideInsightChip(
              insight: EditorSlideInsight(
                objectCount: 5,
                hiddenObjectCount: 1,
                lockedObjectCount: 2,
                hasSpeakerNotes: true,
              ),
              accentColor: Color(0xFF38BDF8),
            ),
          ),
        ),
      ),
    );

    expect(_slideInsightTooltip(), findsOneWidget);
    expect(find.text('5 objects'), findsOneWidget);
    expect(find.text('1 hidden'), findsOneWidget);
    expect(find.text('2 locked'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
  });

  testWidgets('editor status view switcher dispatches view shortcuts', (
    tester,
  ) async {
    final selectedModes = <EditorStatusViewMode>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          body: Center(
            child: EditorStatusControlGroup(
              children: [
                EditorStatusViewSwitcher(
                  activeMode: EditorStatusViewMode.slideBoard,
                  onEditSelected: () {
                    selectedModes.add(EditorStatusViewMode.edit);
                  },
                  onSlideBoardSelected: () {
                    selectedModes.add(EditorStatusViewMode.slideBoard);
                  },
                  onPresentSelected: () {
                    selectedModes.add(EditorStatusViewMode.present);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byTooltip('Normal editing view'), findsOneWidget);
    expect(find.byTooltip('Open slide board'), findsOneWidget);
    expect(find.byTooltip('Start presenter view'), findsOneWidget);
    expect(find.byTooltip('Active view: Slide board'), findsOneWidget);
    expect(find.text('Slide board'), findsOneWidget);

    await tester.tap(find.byTooltip('Normal editing view'));
    await tester.tap(find.byTooltip('Open slide board'));
    await tester.tap(find.byTooltip('Start presenter view'));
    await tester.pumpAndSettle();

    expect(selectedModes, [
      EditorStatusViewMode.edit,
      EditorStatusViewMode.slideBoard,
      EditorStatusViewMode.present,
    ]);
  });

  testWidgets('editor status view mode pill renders the active mode', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          backgroundColor: Color(0xFF0F172A),
          body: Center(
            child: EditorStatusViewModePill(
              activeMode: EditorStatusViewMode.present,
            ),
          ),
        ),
      ),
    );

    expect(find.byTooltip('Active view: Presenting'), findsOneWidget);
    expect(find.text('Presenting'), findsOneWidget);
  });

  testWidgets('editor status control widgets dispatch actions', (tester) async {
    var toggleRequests = 0;
    var snapRequests = 0;
    var zoomRequests = 0;
    var fitRequests = 0;
    double? sliderZoom;
    double? selectedPreset;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          body: Center(
            child: EditorStatusControlGroup(
              children: [
                EditorStatusToggleButton(
                  tooltip: 'Toggle grid',
                  icon: Icons.grid_on,
                  isActive: true,
                  onPressed: () => toggleRequests++,
                ),
                EditorStatusToggleButton(
                  tooltip: 'Toggle snap to grid',
                  icon: Icons.center_focus_strong,
                  isActive: false,
                  onPressed: () => snapRequests++,
                ),
                EditorZoomButton(
                  tooltip: 'Zoom in',
                  icon: Icons.add,
                  onPressed: () => zoomRequests++,
                ),
                EditorZoomSlider(
                  zoom: 1,
                  onChanged: (zoom) => sliderZoom = zoom,
                ),
                EditorZoomPresetMenu(
                  zoom: 1,
                  onZoomSelected: (zoom) => selectedPreset = zoom,
                  onFitToWindow: () => fitRequests++,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Toggle grid'));
    await tester.tap(find.byTooltip('Toggle snap to grid'));
    await tester.tap(find.byTooltip('Zoom in'));
    tester
        .widget<Slider>(find.byKey(const ValueKey('editor-zoom-slider')))
        .onChanged
        ?.call(1.75);
    await tester.pump();
    await tester.tap(find.byTooltip('Zoom presets'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fit to window'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Zoom presets'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('150%'));
    await tester.pumpAndSettle();

    expect(toggleRequests, 1);
    expect(snapRequests, 1);
    expect(zoomRequests, 1);
    expect(fitRequests, 1);
    expect(sliderZoom, 1.75);
    expect(selectedPreset, 1.5);
  });

  testWidgets('editor status bar shows context and toggles view state', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1680, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = _container();
    addTearDown(container.dispose);
    container.read(selectedComponentProvider.notifier).state = 'title';
    container.read(cursorPositionProvider.notifier).state = const Offset(
      123.4,
      56.7,
    );
    container.read(canvasViewportSizeProvider.notifier).state = const Size(
      1056,
      636,
    );

    await _pumpStatusBar(tester, container, width: 1580);

    expect(find.text('Slide 1 of 2'), findsOneWidget);
    expect(_slideInsightTooltip(), findsOneWidget);
    expect(find.text('1 object'), findsOneWidget);
    expect(find.text('Selected: Hero title'), findsOneWidget);
    expect(find.byTooltip('Selection geometry'), findsOneWidget);
    expect(find.text('240 x 80'), findsOneWidget);
    expect(find.text('X 40 Y 40'), findsOneWidget);
    expect(find.text('0 deg'), findsOneWidget);
    expect(find.text('X 123  Y 57'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
    expect(find.byTooltip('Zoom slider'), findsOneWidget);
    expect(find.byTooltip('Normal editing view'), findsOneWidget);
    expect(find.byTooltip('Open slide board'), findsOneWidget);
    expect(find.byTooltip('Start presenter view'), findsOneWidget);
    expect(find.byTooltip('Active view: Editing'), findsOneWidget);
    expect(find.text('Editing'), findsOneWidget);

    await tester.tap(find.byTooltip('Next slide'));
    await tester.pumpAndSettle();
    expect(container.read(presentationProvider).currentSlideIndex, 1);
    expect(find.text('Slide 2 of 2'), findsOneWidget);

    await tester.tap(find.byTooltip('Previous slide'));
    await tester.pumpAndSettle();
    expect(container.read(presentationProvider).currentSlideIndex, 0);
    expect(find.text('Slide 1 of 2'), findsOneWidget);

    await tester.tap(find.byTooltip('Jump to slide'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(container.read(presentationProvider).currentSlideIndex, 1);
    expect(find.text('Slide 2 of 2'), findsOneWidget);

    await tester.tap(find.byTooltip('Toggle notes pane'));
    await tester.pumpAndSettle();
    expect(container.read(speakerNotesVisibleProvider), isFalse);

    await tester.tap(find.byTooltip('Toggle grid'));
    await tester.pumpAndSettle();
    expect(container.read(showGridProvider), isTrue);

    await tester.tap(find.byTooltip('Toggle snap to grid'));
    await tester.pumpAndSettle();
    expect(container.read(snapToGridProvider), isTrue);

    await tester.tap(find.byTooltip('Zoom in'));
    await tester.pumpAndSettle();
    expect(container.read(zoomLevelProvider), closeTo(1.1, 0.001));

    tester
        .widget<Slider>(find.byKey(const ValueKey('editor-zoom-slider')))
        .onChanged
        ?.call(1.8);
    await tester.pumpAndSettle();
    expect(container.read(zoomLevelProvider), closeTo(1.8, 0.001));

    await tester.tap(find.byTooltip('Zoom presets'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('150%'));
    await tester.pumpAndSettle();
    expect(container.read(zoomLevelProvider), closeTo(1.5, 0.001));

    await tester.tap(find.byTooltip('Zoom presets'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fit to window'));
    await tester.pumpAndSettle();
    expect(container.read(zoomLevelProvider), closeTo(0.5, 0.001));

    tester
        .widget<Slider>(find.byKey(const ValueKey('editor-zoom-slider')))
        .onChanged
        ?.call(1.8);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Fit to window'));
    await tester.pumpAndSettle();
    expect(container.read(zoomLevelProvider), closeTo(0.5, 0.001));

    await tester.tap(find.byTooltip('Open slide board'));
    await tester.pumpAndSettle();
    expect(container.read(slideSorterVisibleProvider), isTrue);
    expect(container.read(presenterModeProvider), isFalse);

    await tester.tap(find.byTooltip('Normal editing view'));
    await tester.pumpAndSettle();
    expect(container.read(slideSorterVisibleProvider), isFalse);
    expect(container.read(presenterModeProvider), isFalse);

    await tester.tap(find.byTooltip('Start presenter view'));
    await tester.pumpAndSettle();
    expect(container.read(slideSorterVisibleProvider), isFalse);
    expect(container.read(presenterModeProvider), isTrue);
  });
}

Finder _slideInsightTooltip() {
  return find.byWidgetPredicate(
    (widget) =>
        widget is Tooltip &&
        widget.message?.startsWith('Slide insight:') == true,
  );
}

PresentationComponent _component(
  String id, {
  bool isVisible = true,
  bool isLocked = false,
}) {
  return PresentationComponent(
    id: id,
    type: ComponentType.shape,
    position: Offset.zero,
    size: const Size(120, 80),
    isVisible: isVisible,
    isLocked: isLocked,
  );
}

Future<void> _pumpStatusBar(
  WidgetTester tester,
  ProviderContainer container, {
  double width = 1320,
}) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: width,
            height: 42,
            child: const EditorStatusBar(),
          ),
        ),
      ),
    ),
  );
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
    id: 'editor-status-bar-test',
    title: 'Editor Status Bar Test',
    slides: [
      Slide(
        id: 'slide-1',
        title: 'Intro',
        components: [
          PresentationComponent(
            id: 'title',
            type: ComponentType.richText,
            layerName: 'Hero title',
            position: const Offset(40, 40),
            size: const Size(240, 80),
          ),
        ],
      ),
      Slide(id: 'slide-2', title: 'Close', components: []),
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
