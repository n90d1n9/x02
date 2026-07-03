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
import 'package:ky_slide/states/history_provider.dart';
import 'package:ky_slide/states/presentation_provider.dart';
import 'package:ky_slide/widgets/component_properties_panel.dart';

void main() {
  testWidgets('component properties panel edits frame and fill', (
    tester,
  ) async {
    final container = _container();
    addTearDown(container.dispose);
    container.read(selectedComponentProvider.notifier).state = 'title';

    await _pumpPanel(tester, container);

    expect(find.text('Component Properties'), findsOneWidget);
    expect(find.text('Layer'), findsOneWidget);
    expect(find.text('Frame'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Presets'), findsOneWidget);
    expect(find.text('Border color'), findsOneWidget);
    expect(find.text('Border width'), findsOneWidget);
    expect(find.text('Glow'), findsOneWidget);
    expect(find.text('Modern Design Features Complete!'), findsNothing);

    await tester.enterText(_textFieldWithLabel('X'), '84');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(_component(container).position.dx, 84);
    expect(container.read(historyProvider).undoLabel, 'Update layer frame');

    await tester.ensureVisible(find.byTooltip('Apply Soft preset'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Apply Soft preset'));
    await tester.pumpAndSettle();

    var component = _component(container);
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
    expect(find.byIcon(Icons.check_circle), findsOneWidget);

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -520),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('#14B8A6').first);
    await tester.pumpAndSettle();

    component = _component(container);
    expect(component.backgroundColor, const Color(0xFF14B8A6));
    expect(container.read(historyProvider).undoLabel, 'Update layer fill');

    await tester.ensureVisible(find.text('Border color'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('#F59E0B').at(1));
    await tester.pumpAndSettle();

    component = _component(container);
    expect(component.border?.color, const Color(0xFFF59E0B));
    expect(container.read(historyProvider).undoLabel, 'Update layer border');

    await tester.ensureVisible(find.text('Glow color'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('#F59E0B').at(2));
    await tester.pumpAndSettle();

    component = _component(container);
    expect(component.glowColor, const Color(0xFFF59E0B));
    expect(container.read(historyProvider).undoLabel, 'Update layer glow');

    await tester.tap(find.byType(Switch).last);
    await tester.pumpAndSettle();

    component = _component(container);
    expect(component.hasGlow, isFalse);
    expect(component.glowColor, isNull);
    expect(container.read(historyProvider).undoLabel, 'Update layer glow');
  });

  testWidgets('component properties panel locks editable controls', (
    tester,
  ) async {
    final container = _container(locked: true);
    addTearDown(container.dispose);
    container.read(selectedComponentProvider.notifier).state = 'title';

    await _pumpPanel(tester, container);

    expect(find.text('Locked layer'), findsOneWidget);
    expect(
      find.text('Unlock the layer to edit frame and appearance.'),
      findsOneWidget,
    );

    await tester.enterText(_textFieldWithLabel('X'), '200');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(_component(container).position.dx, 40);

    await tester.tap(find.byType(Switch).at(1));
    await tester.pumpAndSettle();

    expect(_component(container).isLocked, isFalse);
    expect(container.read(historyProvider).undoLabel, 'Unlock layer');
  });
}

Finder _textFieldWithLabel(String label) {
  return find.byWidgetPredicate((widget) {
    return widget is TextField && widget.decoration?.labelText == label;
  });
}

Future<void> _pumpPanel(
  WidgetTester tester,
  ProviderContainer container,
) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 320, child: ComponentPropertiesPanel()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ProviderContainer _container({bool locked = false}) {
  return ProviderContainer(
    overrides: [
      presentationProvider.overrideWith(
        (ref) => PresentationNotifier(
          initialPresentation: _presentation(locked: locked),
        ),
      ),
    ],
  );
}

Presentation _presentation({required bool locked}) {
  return Presentation(
    id: 'properties-panel-test',
    title: 'Properties Panel Test',
    slides: [
      Slide(
        id: 'slide',
        components: [
          PresentationComponent(
            id: 'title',
            type: ComponentType.richText,
            position: const Offset(40, 40),
            size: const Size(240, 80),
            zIndex: 1,
            isLocked: locked,
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
    slideSize: const Size(1000, 600),
  );
}

PresentationComponent _component(ProviderContainer container) {
  final presentation = container.read(presentationProvider);
  return presentation.slides[presentation.currentSlideIndex].components.first;
}
