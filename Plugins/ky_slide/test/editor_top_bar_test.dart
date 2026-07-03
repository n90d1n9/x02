import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/models/component.dart';
import 'package:ky_slide/models/editor_deck_insight.dart';
import 'package:ky_slide/models/presentation.dart';
import 'package:ky_slide/models/presentation_component.dart';
import 'package:ky_slide/models/sidebar_menu_item.dart';
import 'package:ky_slide/models/slide.dart';
import 'package:ky_slide/models/style/presentation_theme.dart';
import 'package:ky_slide/states/editor_view_provider.dart';
import 'package:ky_slide/states/presentation_provider.dart';
import 'package:ky_slide/states/sidebar_panel_provider.dart';
import 'package:ky_slide/widgets/editor/editor_top_bar.dart';
import 'package:ky_slide/widgets/editor/editor_top_bar_widgets.dart';

void main() {
  testWidgets('editor top bar title adapts deck context to available space', (
    tester,
  ) async {
    await tester.pumpWidget(_topBarTitleHarness(width: 420));

    expect(find.text('Quarterly Review'), findsOneWidget);
    expect(find.text('Slide 2/4'), findsOneWidget);
    expect(find.byTooltip('Theme palette'), findsOneWidget);
    expect(_deckInsightTooltip(), findsNothing);

    await tester.pumpWidget(_topBarTitleHarness(width: 620));

    expect(find.text('Slide 2/4'), findsOneWidget);
    expect(find.byTooltip('Theme palette'), findsOneWidget);
    expect(_deckInsightTooltip(), findsOneWidget);

    await tester.pumpWidget(_topBarTitleHarness(width: 240));

    expect(find.text('Quarterly Review'), findsOneWidget);
    expect(find.text('Slide 2/4'), findsNothing);
    expect(find.byTooltip('Theme palette'), findsNothing);
    expect(_deckInsightTooltip(), findsNothing);
  });

  test('editor deck insight summarizes presentation metadata', () {
    final insight = EditorDeckInsight.fromPresentation(_presentation());

    expect(insight.slideLabel, '2 slides');
    expect(insight.objectLabel, '3 objects');
    expect(insight.notesLabel, '1 note');
    expect(insight.aspectRatioLabel, '16:9');
    expect(insight.tooltipLabel, contains('Test Theme theme'));
  });

  testWidgets('editor deck insight pill renders compact deck metrics', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          backgroundColor: Color(0xFF0F172A),
          body: Center(
            child: EditorDeckInsightPill(
              insight: EditorDeckInsight(
                slideCount: 8,
                objectCount: 24,
                notesSlideCount: 0,
                themeName: 'Studio',
                slideSize: Size(1024, 768),
              ),
              accentColor: Color(0xFF14B8A6),
            ),
          ),
        ),
      ),
    );

    expect(_deckInsightTooltip(), findsOneWidget);
    expect(find.text('24 objects'), findsOneWidget);
    expect(find.text('No notes'), findsOneWidget);
    expect(find.text('4:3'), findsOneWidget);
  });

  testWidgets('editor theme palette strip renders active theme colors', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          backgroundColor: Color(0xFF0F172A),
          body: Center(
            child: EditorThemePaletteStrip(
              colors: [
                Color(0xFF2563EB),
                Color(0xFF14B8A6),
                Color(0xFFF59E0B),
                Color(0xFFEC4899),
                Color(0xFF8B5CF6),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byTooltip('Theme palette'), findsOneWidget);
    expect(find.byType(DecoratedBox), findsWidgets);
  });

  testWidgets('editor top bar command widgets dispatch actions', (
    tester,
  ) async {
    var commandRequests = 0;
    var presentRequests = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          body: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                EditorTopBarCommandGroup(
                  children: [
                    EditorTopBarIconButton(
                      icon: Icons.folder_open_outlined,
                      tooltip: 'Open files',
                      onPressed: () => commandRequests++,
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                EditorPresentActionButton(onPressed: () => presentRequests++),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Open files'));
    await tester.tap(find.byTooltip('Present (F5)'));
    await tester.pumpAndSettle();

    expect(commandRequests, 1);
    expect(presentRequests, 1);
  });

  testWidgets('editor top bar renders deck context and quick actions', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 820);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [
        presentationProvider.overrideWith(
          (ref) => PresentationNotifier(initialPresentation: _presentation()),
        ),
      ],
    );
    addTearDown(container.dispose);

    var themeRequests = 0;
    var effectRequests = 0;
    var presentRequests = 0;
    var commandPaletteRequests = 0;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            appBar: EditorTopBar(
              onOpenCommandPalette: () => commandPaletteRequests++,
              onShowThemes: () => themeRequests++,
              onShowEffects: () => effectRequests++,
              onPresent: () => presentRequests++,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Quarterly Review'), findsOneWidget);
    expect(find.text('Slide 2/2'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.manage_search_outlined));
    await tester.pumpAndSettle();

    expect(commandPaletteRequests, 1);

    container.read(slideNavigatorVisibleProvider.notifier).state = false;
    await tester.tap(find.byTooltip('Import / Export'));
    await tester.pumpAndSettle();

    expect(container.read(activeSidebarMenuProvider), SidebarMenuItem.files);
    expect(container.read(slideNavigatorVisibleProvider), isTrue);

    await tester.tap(find.byTooltip('Themes'));
    await tester.tap(find.byTooltip('Visual Effects'));
    await tester.tap(find.byTooltip('Present (F5)'));
    await tester.pumpAndSettle();

    expect(themeRequests, 1);
    expect(effectRequests, 1);
    expect(presentRequests, 1);
  });
}

Finder _deckInsightTooltip() {
  return find.byWidgetPredicate(
    (widget) =>
        widget is Tooltip &&
        widget.message?.startsWith('Deck insight:') == true,
  );
}

Widget _topBarTitleHarness({required double width}) {
  return MaterialApp(
    home: Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: SizedBox(
          width: width,
          child: const EditorTopBarTitle(
            title: 'Quarterly Review',
            slideIndex: 1,
            slideCount: 4,
            primaryColor: Color(0xFF2563EB),
            secondaryColor: Color(0xFF14B8A6),
            deckInsight: EditorDeckInsight(
              slideCount: 4,
              objectCount: 18,
              notesSlideCount: 2,
              themeName: 'Test Theme',
              slideSize: Size(1920, 1080),
            ),
            paletteColors: [
              Color(0xFF2563EB),
              Color(0xFF14B8A6),
              Color(0xFFF59E0B),
              Color(0xFFEC4899),
            ],
          ),
        ),
      ),
    ),
  );
}

Presentation _presentation() {
  return Presentation(
    id: 'editor-top-bar-test',
    title: 'Quarterly Review',
    currentSlideIndex: 1,
    slides: [
      Slide(
        id: 'intro',
        notes: 'Open with the launch story',
        components: [_component('hero-title'), _component('hero-chart')],
      ),
      Slide(id: 'summary', components: [_component('summary-card')]),
    ],
    theme: PresentationTheme(
      id: 'test-theme',
      name: 'Test Theme',
      primaryColor: Color(0xFF2563EB),
      secondaryColor: Color(0xFF14B8A6),
      backgroundColor: Color(0xFF0F172A),
      textColor: Colors.white,
      titleStyle: TextStyle(color: Colors.white, fontSize: 48),
      bodyStyle: TextStyle(color: Colors.white70, fontSize: 20),
      colorPalette: [Color(0xFF2563EB), Color(0xFF14B8A6)],
    ),
  );
}

PresentationComponent _component(String id) {
  return PresentationComponent(
    id: id,
    type: ComponentType.shape,
    position: Offset.zero,
    size: const Size(120, 80),
  );
}
