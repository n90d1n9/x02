import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/models/presentation.dart';
import 'package:ky_slide/models/sidebar_menu_item.dart';
import 'package:ky_slide/models/slide.dart';
import 'package:ky_slide/models/style/presentation_theme.dart';
import 'package:ky_slide/screens/presentation_editor.dart';
import 'package:ky_slide/states/editor_view_provider.dart';
import 'package:ky_slide/states/presentation_provider.dart';
import 'package:ky_slide/states/sidebar_panel_provider.dart';
import 'package:ky_slide/widgets/properties_panel.dart';
import 'package:ky_slide/widgets/slide_panel.dart';

void main() {
  testWidgets('presentation editor hides side panels from the view ribbon', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 820);
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

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: PresentationEditor()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SlidePanel), findsOneWidget);
    expect(find.byType(PropertiesPanel), findsOneWidget);

    await tester.tap(find.text('View'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Toggle Slide Navigator'));
    await tester.pumpAndSettle();

    expect(container.read(slideNavigatorVisibleProvider), isFalse);
    expect(find.byType(SlidePanel), findsNothing);

    await tester.tap(find.byTooltip('Toggle Inspector'));
    await tester.pumpAndSettle();

    expect(container.read(propertiesPanelVisibleProvider), isFalse);
    expect(find.byType(PropertiesPanel), findsNothing);
  });

  testWidgets('presentation editor command palette opens the slide board', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 820);
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

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: PresentationEditor()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.manage_search_outlined));
    await tester.pumpAndSettle();

    expect(container.read(commandPaletteVisibleProvider), isTrue);
    expect(find.text('Search commands'), findsOneWidget);

    await tester.enterText(_commandPaletteSearchField(), 'slide board');
    await tester.pump();
    await tester.tap(_commandText('Open Slide Board'));
    await tester.pumpAndSettle();

    expect(container.read(commandPaletteVisibleProvider), isFalse);
    expect(container.read(slideSorterVisibleProvider), isTrue);
    expect(find.text('Slide Board'), findsOneWidget);
  });

  testWidgets('presentation editor command palette opens sidebar panels', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 820);
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

    container.read(slideNavigatorVisibleProvider.notifier).state = false;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: PresentationEditor()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.manage_search_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(_commandPaletteSearchField(), 'files pptx');
    await tester.pump();
    await tester.tap(_commandText('Open Import / Export'));
    await tester.pumpAndSettle();

    expect(container.read(commandPaletteVisibleProvider), isFalse);
    expect(container.read(slideNavigatorVisibleProvider), isTrue);
    expect(container.read(activeSidebarMenuProvider), SidebarMenuItem.files);
  });
}

Finder _commandText(String text) => find.text(text, findRichText: true);

Finder _commandPaletteSearchField() {
  return find.byWidgetPredicate((widget) {
    return widget is TextField &&
        widget.decoration?.hintText == 'Search commands';
  });
}

Presentation _presentation() {
  return Presentation(
    id: 'presentation-editor-layout-test',
    title: 'Workspace Controls',
    slides: [
      Slide(id: 'slide-1', components: [], title: 'Intro'),
      Slide(id: 'slide-2', components: [], title: 'Plan'),
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
