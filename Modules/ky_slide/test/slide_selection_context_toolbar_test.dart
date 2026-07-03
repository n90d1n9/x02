import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/models/component.dart';
import 'package:ky_slide/models/presentation.dart';
import 'package:ky_slide/models/presentation_component.dart';
import 'package:ky_slide/models/rich_text_content.dart';
import 'package:ky_slide/models/slide.dart';
import 'package:ky_slide/models/style/presentation_theme.dart';
import 'package:ky_slide/states/component_provider.dart';
import 'package:ky_slide/states/editor_view_provider.dart';
import 'package:ky_slide/states/history_provider.dart';
import 'package:ky_slide/states/presentation_provider.dart';
import 'package:ky_slide/widgets/canvas/selection_context_action_bar.dart';
import 'package:ky_slide/widgets/canvas/slide_selection_context_toolbar.dart';

void main() {
  testWidgets('selection context action bar dispatches object commands', (
    tester,
  ) async {
    var duplicated = false;
    var openedProperties = false;
    var toggledLock = false;
    var deleted = false;
    SelectionContextLayerOrderAction? orderAction;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF101114),
          body: Center(
            child: SelectionContextActionBar(
              isLocked: false,
              accentColor: const Color(0xFF2563EB),
              onDuplicate: () => duplicated = true,
              onLayerOrderSelected: (action) => orderAction = action,
              onOpenProperties: () => openedProperties = true,
              onToggleLock: () => toggledLock = true,
              onDelete: () => deleted = true,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Duplicate selected object'));
    await tester.tap(find.byTooltip('Layer order'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bring to front'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Lock selected object'));
    await tester.tap(find.byTooltip('Open object properties'));
    await tester.tap(find.byTooltip('Delete selected object'));
    await tester.pumpAndSettle();

    expect(duplicated, isTrue);
    expect(orderAction, SelectionContextLayerOrderAction.bringToFront);
    expect(openedProperties, isTrue);
    expect(toggledLock, isTrue);
    expect(deleted, isTrue);
  });

  testWidgets('selection context toolbar duplicates and deletes objects', (
    tester,
  ) async {
    final container = _container();
    addTearDown(container.dispose);
    container.read(selectedComponentProvider.notifier).state = 'title';

    await _pumpToolbar(tester, container, _component(container, 'title'));

    expect(find.text('Hero title'), findsOneWidget);
    expect(find.text('Text / Editable'), findsOneWidget);

    await tester.tap(find.byTooltip('Duplicate selected object'));
    await tester.pumpAndSettle();

    final duplicatedId = container.read(selectedComponentProvider);
    expect(duplicatedId, isNot('title'));
    expect(_components(container).length, 2);
    expect(container.read(historyProvider).undoLabel, 'Duplicate layer');

    await tester.tap(find.byTooltip('Delete selected object'));
    await tester.pumpAndSettle();

    expect(container.read(selectedComponentProvider), isNull);
    expect(_components(container).map((component) => component.id), ['title']);
    expect(container.read(historyProvider).undoLabel, 'Delete layer');
  });

  testWidgets('selection context toolbar toggles object lock state', (
    tester,
  ) async {
    final container = _container();
    addTearDown(container.dispose);
    container.read(selectedComponentProvider.notifier).state = 'title';

    await _pumpToolbar(tester, container, _component(container, 'title'));

    await tester.tap(find.byTooltip('Lock selected object'));
    await tester.pumpAndSettle();

    expect(_component(container, 'title').isLocked, isTrue);
    expect(container.read(historyProvider).undoLabel, 'Lock layer');

    await _pumpToolbar(tester, container, _component(container, 'title'));
    await tester.tap(find.byTooltip('Unlock selected object'));
    await tester.pumpAndSettle();

    expect(_component(container, 'title').isLocked, isFalse);
    expect(container.read(historyProvider).undoLabel, 'Unlock layer');
  });

  testWidgets('selection context toolbar opens the object properties panel', (
    tester,
  ) async {
    final container = _container();
    addTearDown(container.dispose);
    container.read(selectedComponentProvider.notifier).state = 'title';
    container.read(propertiesPanelVisibleProvider.notifier).state = false;

    await _pumpToolbar(tester, container, _component(container, 'title'));

    await tester.tap(find.byTooltip('Open object properties'));
    await tester.pumpAndSettle();

    expect(container.read(propertiesPanelVisibleProvider), isTrue);
  });

  testWidgets('selection context toolbar applies quick format changes', (
    tester,
  ) async {
    final container = _container();
    addTearDown(container.dispose);
    container.read(selectedComponentProvider.notifier).state = 'title';

    await _pumpToolbar(tester, container, _component(container, 'title'));

    await tester.tap(find.byTooltip('Quick format'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Fill #2563EB'));
    await tester.pumpAndSettle();

    expect(
      _component(container, 'title').backgroundColor,
      const Color(0xFF2563EB),
    );
    expect(container.read(historyProvider).undoLabel, 'Update layer fill');

    await tester.tap(find.byTooltip('Quick format'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('No fill'));
    await tester.pumpAndSettle();

    expect(_component(container, 'title').backgroundColor, isNull);
    expect(container.read(historyProvider).undoLabel, 'Update layer fill');

    await tester.tap(find.byTooltip('Quick format'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('2 px outline'));
    await tester.pumpAndSettle();

    expect(_component(container, 'title').border?.width, 2);
    expect(container.read(historyProvider).undoLabel, 'Update layer border');

    await tester.tap(find.byTooltip('Quick format'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('No outline').first);
    await tester.pumpAndSettle();

    expect(_component(container, 'title').border, isNull);
    expect(container.read(historyProvider).undoLabel, 'Update layer border');

    await tester.tap(find.byTooltip('Quick format'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('75% opacity'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('75% opacity'));
    await tester.pumpAndSettle();

    expect(_component(container, 'title').opacity, closeTo(0.75, 0.001));
    expect(container.read(historyProvider).undoLabel, 'Update layer opacity');

    await tester.tap(find.byTooltip('Quick format'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Glow on'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Glow on'));
    await tester.pumpAndSettle();

    expect(_component(container, 'title').hasGlow, isTrue);
    expect(_component(container, 'title').glowColor, const Color(0xFF2563EB));
    expect(container.read(historyProvider).undoLabel, 'Update layer glow');

    await tester.tap(find.byTooltip('Quick format'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Glow #14B8A6'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Glow #14B8A6'));
    await tester.pumpAndSettle();

    expect(_component(container, 'title').glowColor, const Color(0xFF14B8A6));
    expect(container.read(historyProvider).undoLabel, 'Update layer glow');

    await tester.tap(find.byTooltip('Quick format'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('No glow'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('No glow'));
    await tester.pumpAndSettle();

    expect(_component(container, 'title').hasGlow, isFalse);
    expect(_component(container, 'title').glowColor, isNull);
    expect(container.read(historyProvider).undoLabel, 'Update layer glow');

    await tester.tap(find.byTooltip('Quick format'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Apply Soft preset'));
    await tester.pumpAndSettle();

    final component = _component(container, 'title');
    expect(
      component.backgroundColor,
      const Color(0xFF14B8A6).withValues(alpha: 0.18),
    );
    expect(
      component.border?.color,
      const Color(0xFF2563EB).withValues(alpha: 0.42),
    );
    expect(component.hasGlow, isTrue);
    expect(container.read(historyProvider).undoLabel, 'Apply object preset');

    await tester.tap(find.byTooltip('Quick format'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Bold text'));
    await tester.pumpAndSettle();

    expect(_component(container, 'title').richText?.isBold, isTrue);
    expect(container.read(historyProvider).undoLabel, 'Update text style');

    await tester.tap(find.byTooltip('Quick format'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Strikethrough text'));
    await tester.pumpAndSettle();

    expect(_component(container, 'title').richText?.isStrikethrough, isTrue);
    expect(container.read(historyProvider).undoLabel, 'Update text style');

    await tester.tap(find.byTooltip('Quick format'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Justify align text'));
    await tester.pumpAndSettle();

    expect(
      _component(container, 'title').richText?.alignment,
      TextAlign.justify,
    );
    expect(container.read(historyProvider).undoLabel, 'Update text style');

    await tester.tap(find.byTooltip('Quick format'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Apply Quote text preset'));
    await tester.pumpAndSettle();

    final richText = _component(container, 'title').richText;
    expect(richText?.style.fontSize, 28);
    expect(richText?.isItalic, isTrue);
    expect(richText?.isBold, isFalse);
    expect(container.read(historyProvider).undoLabel, 'Apply text preset');

    await tester.tap(find.byTooltip('Quick format'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Font family Poppins'));
    await tester.pumpAndSettle();

    expect(
      _component(container, 'title').richText?.style.fontFamily,
      'Poppins',
    );
    expect(container.read(historyProvider).undoLabel, 'Update text style');

    await tester.tap(find.byTooltip('Quick format'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('1.5x line spacing'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('1.5x line spacing'));
    await tester.pumpAndSettle();

    expect(_component(container, 'title').richText?.style.height, 1.5);
    expect(container.read(historyProvider).undoLabel, 'Update text style');

    await tester.tap(find.byTooltip('Quick format'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('1.5 pt character spacing'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('1.5 pt character spacing'));
    await tester.pumpAndSettle();

    expect(_component(container, 'title').richText?.style.letterSpacing, 1.5);
    expect(container.read(historyProvider).undoLabel, 'Update text style');

    await tester.tap(find.byTooltip('Quick format'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Highlight #BBF7D0'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Highlight #BBF7D0'));
    await tester.pumpAndSettle();

    expect(
      _component(container, 'title').richText?.style.backgroundColor,
      const Color(0xFFBBF7D0),
    );
    expect(container.read(historyProvider).undoLabel, 'Update text style');

    await tester.tap(find.byTooltip('Quick format'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Clear highlight'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Clear highlight'));
    await tester.pumpAndSettle();

    expect(
      _component(container, 'title').richText?.style.backgroundColor,
      isNull,
    );
    expect(container.read(historyProvider).undoLabel, 'Update text style');

    await tester.tap(find.byTooltip('Quick format'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Bulleted list'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Bulleted list'));
    await tester.pumpAndSettle();

    expect(_component(container, 'title').richText?.text, '- Quarterly update');
    expect(container.read(historyProvider).undoLabel, 'Format paragraph');

    await tester.tap(find.byTooltip('Quick format'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Increase indent'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Increase indent'));
    await tester.pumpAndSettle();

    expect(
      _component(container, 'title').richText?.text,
      '  - Quarterly update',
    );
    expect(
      container.read(historyProvider).undoLabel,
      'Update paragraph indent',
    );

    await tester.tap(find.byTooltip('Quick format'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('AA'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('AA'));
    await tester.pumpAndSettle();

    expect(
      _component(container, 'title').richText?.text,
      '  - QUARTERLY UPDATE',
    );
    expect(container.read(historyProvider).undoLabel, 'Change text case');
  });

  testWidgets('selection context toolbar reaches layer order actions', (
    tester,
  ) async {
    final container = _container(stacked: true);
    addTearDown(container.dispose);
    container.read(selectedComponentProvider.notifier).state = 'title';

    await _pumpToolbar(tester, container, _component(container, 'title'));

    await tester.tap(find.byTooltip('Layer order'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send to back'));
    await tester.pumpAndSettle();

    expect(_component(container, 'title').zIndex, -1);
    expect(container.read(historyProvider).undoLabel, 'Send layer to back');
  });

  testWidgets('selection context toolbar aligns the selected object', (
    tester,
  ) async {
    final container = _container();
    addTearDown(container.dispose);
    container.read(selectedComponentProvider.notifier).state = 'title';

    await _pumpToolbar(tester, container, _component(container, 'title'));

    await tester.tap(find.byTooltip('Align selected object'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Center on slide'));
    await tester.pumpAndSettle();

    final component = _component(container, 'title');
    expect(component.position, const Offset(230, 150));
    expect(container.read(historyProvider).undoLabel, 'Arrange layer');
  });
}

Future<void> _pumpToolbar(
  WidgetTester tester,
  ProviderContainer container,
  PresentationComponent component,
) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 640,
            height: 360,
            child: Stack(
              children: [
                SlideSelectionContextToolbar(
                  component: component,
                  slideSize: const Size(640, 360),
                  zoom: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ProviderContainer _container({bool stacked = false}) {
  return ProviderContainer(
    overrides: [
      presentationProvider.overrideWith(
        (ref) =>
            PresentationNotifier(initialPresentation: _presentation(stacked)),
      ),
    ],
  );
}

Presentation _presentation(bool stacked) {
  return Presentation(
    id: 'selection-context-toolbar-test',
    title: 'Selection Context Toolbar Test',
    slideSize: const Size(640, 360),
    slides: [
      Slide(
        id: 'slide',
        components: [
          if (stacked)
            PresentationComponent(
              id: 'background',
              type: ComponentType.shape,
              position: const Offset(20, 20),
              size: const Size(260, 120),
              zIndex: 0,
            ),
          PresentationComponent(
            id: 'title',
            type: ComponentType.richText,
            layerName: 'Hero title',
            position: const Offset(80, 80),
            size: const Size(180, 60),
            zIndex: stacked ? 1 : 0,
            richText: RichTextContent(
              text: 'Quarterly update',
              style: const TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
        ],
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
      colorPalette: const [Color(0xFF2563EB), Color(0xFF14B8A6)],
    ),
  );
}

List<PresentationComponent> _components(ProviderContainer container) {
  final presentation = container.read(presentationProvider);
  return presentation.slides[presentation.currentSlideIndex].components;
}

PresentationComponent _component(ProviderContainer container, String id) {
  return _components(container).firstWhere((component) => component.id == id);
}
