import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/models/component.dart';
import 'package:ky_slide/models/presentation.dart';
import 'package:ky_slide/models/presentation_component.dart';
import 'package:ky_slide/models/sidebar_menu_item.dart';
import 'package:ky_slide/models/slide.dart';
import 'package:ky_slide/models/style/presentation_theme.dart';
import 'package:ky_slide/states/component_provider.dart';
import 'package:ky_slide/states/editor_view_provider.dart';
import 'package:ky_slide/states/history_provider.dart';
import 'package:ky_slide/states/presentation_provider.dart';
import 'package:ky_slide/states/sidebar_panel_provider.dart';
import 'package:ky_slide/widgets/canvas/slide_canvas.dart';

void main() {
  testWidgets('slide canvas empty state adds a title placeholder', (
    tester,
  ) async {
    final container = _container();
    addTearDown(container.dispose);

    await _pumpCanvas(tester, container);

    expect(find.text('Blank slide'), findsOneWidget);

    await tester.tap(find.byTooltip('Add title'));
    await tester.pumpAndSettle();

    final component = _components(container).single;
    expect(component.type, ComponentType.richText);
    expect(component.richText?.text, 'Title');
    expect(component.richText?.alignment, TextAlign.center);
    expect(container.read(selectedComponentProvider), component.id);
    expect(container.read(historyProvider).undoLabel, 'Add title');
  });

  testWidgets('slide canvas empty state opens templates in the sidebar', (
    tester,
  ) async {
    final container = _container();
    addTearDown(container.dispose);
    container.read(slideNavigatorVisibleProvider.notifier).state = false;

    await _pumpCanvas(tester, container);
    await tester.tap(find.byTooltip('Open templates'));
    await tester.pumpAndSettle();

    expect(container.read(slideNavigatorVisibleProvider), isTrue);
    expect(container.read(activeSidebarMenuProvider), SidebarMenuItem.design);
  });

  testWidgets('slide canvas hides empty state when slide has content', (
    tester,
  ) async {
    final container = _container(hasContent: true);
    addTearDown(container.dispose);

    await _pumpCanvas(tester, container);

    expect(find.text('Blank slide'), findsNothing);
    expect(find.byTooltip('Add title'), findsNothing);
  });
}

Future<void> _pumpCanvas(
  WidgetTester tester,
  ProviderContainer container,
) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 640, height: 360, child: SlideCanvas()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ProviderContainer _container({bool hasContent = false}) {
  return ProviderContainer(
    overrides: [
      presentationProvider.overrideWith(
        (ref) => PresentationNotifier(
          initialPresentation: _presentation(hasContent: hasContent),
        ),
      ),
    ],
  );
}

Presentation _presentation({required bool hasContent}) {
  return Presentation(
    id: 'slide-canvas-empty-state-test',
    title: 'Canvas Empty State Test',
    slideSize: const Size(640, 360),
    slides: [
      Slide(
        id: 'slide',
        components: hasContent
            ? [
                PresentationComponent(
                  id: 'shape',
                  type: ComponentType.shape,
                  position: const Offset(40, 40),
                  size: const Size(100, 80),
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
      colorPalette: const [Color(0xFF2563EB), Color(0xFF14B8A6)],
    ),
  );
}

List<PresentationComponent> _components(ProviderContainer container) {
  final presentation = container.read(presentationProvider);
  return presentation.slides[presentation.currentSlideIndex].components;
}
