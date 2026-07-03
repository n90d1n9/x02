import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/models/component.dart';
import 'package:ky_slide/models/presentation.dart';
import 'package:ky_slide/models/presentation_component.dart';
import 'package:ky_slide/models/rich_text_content.dart';
import 'package:ky_slide/models/slide.dart';
import 'package:ky_slide/states/component_provider.dart';
import 'package:ky_slide/states/editor_view_provider.dart';
import 'package:ky_slide/states/history_provider.dart';
import 'package:ky_slide/states/presentation_provider.dart';
import 'package:ky_slide/widgets/editor/presentation_keyboard_shortcuts.dart';

void main() {
  testWidgets('delete shortcut removes the selected layer with history', (
    tester,
  ) async {
    final container = await _pumpShortcuts(tester);
    container.read(selectedComponentProvider.notifier).state = 'title';

    await _sendShortcut(tester, LogicalKeyboardKey.delete);

    expect(_componentIds(container), ['background', 'badge']);
    expect(container.read(selectedComponentProvider), isNull);
    expect(container.read(historyProvider).undoLabel, 'Delete layer');

    await _sendShortcut(tester, LogicalKeyboardKey.keyZ, control: true);

    expect(_componentIds(container), ['background', 'title', 'badge']);
  });

  testWidgets('duplicate shortcut copies and selects the selected layer', (
    tester,
  ) async {
    final container = await _pumpShortcuts(tester);
    container.read(selectedComponentProvider.notifier).state = 'title';

    await _sendShortcut(tester, LogicalKeyboardKey.keyD, control: true);

    final components = _components(container);
    final selectedDuplicateId = container.read(selectedComponentProvider);
    final original = components.firstWhere(
      (component) => component.id == 'title',
    );
    final duplicate = components.firstWhere(
      (component) => component.id == selectedDuplicateId,
    );

    expect(components.length, 4);
    expect(selectedDuplicateId, isNot('title'));
    expect(duplicate.richText?.text, original.richText?.text);
    expect(duplicate.position, original.position + const Offset(16, 16));
    expect(duplicate.zIndex, 3);
    expect(container.read(historyProvider).undoLabel, 'Duplicate layer');

    await _sendShortcut(tester, LogicalKeyboardKey.keyZ, control: true);
    expect(_componentIds(container), ['background', 'title', 'badge']);

    await _sendShortcut(tester, LogicalKeyboardKey.keyY, control: true);
    expect(_components(container).length, 4);
  });

  testWidgets('layer stack shortcuts move the selected layer', (tester) async {
    final container = await _pumpShortcuts(tester);
    container.read(selectedComponentProvider.notifier).state = 'title';

    await _sendShortcut(tester, LogicalKeyboardKey.bracketRight, control: true);

    var components = _components(container);
    expect(_component(components, 'title').zIndex, 2);
    expect(_component(components, 'badge').zIndex, 1);
    expect(container.read(historyProvider).undoLabel, 'Move layer forward');

    await _sendShortcut(
      tester,
      LogicalKeyboardKey.bracketLeft,
      control: true,
      shift: true,
    );

    components = _components(container);
    expect(_component(components, 'title').zIndex, -1);
    expect(container.read(historyProvider).undoLabel, 'Send layer to back');
  });

  testWidgets('arrow shortcuts nudge the selected layer', (tester) async {
    final container = await _pumpShortcuts(tester);
    container.read(selectedComponentProvider.notifier).state = 'title';

    await _sendShortcut(tester, LogicalKeyboardKey.arrowRight);

    expect(
      _component(_components(container), 'title').position,
      const Offset(41, 40),
    );
    expect(container.read(historyProvider).undoLabel, 'Nudge layer');

    await _sendShortcut(tester, LogicalKeyboardKey.arrowDown, shift: true);

    expect(
      _component(_components(container), 'title').position,
      const Offset(41, 50),
    );

    container.read(snapToGridProvider.notifier).state = true;
    await _sendShortcut(tester, LogicalKeyboardKey.arrowRight);

    expect(
      _component(_components(container), 'title').position,
      const Offset(60, 60),
    );
  });

  testWidgets('present shortcut enters presenter mode', (tester) async {
    final container = await _pumpShortcuts(tester);

    await _sendShortcut(tester, LogicalKeyboardKey.f5);

    expect(container.read(presenterModeProvider), isTrue);
  });

  testWidgets('command palette shortcut opens palette state', (tester) async {
    final container = await _pumpShortcuts(tester);

    await _sendShortcut(tester, LogicalKeyboardKey.keyK, control: true);

    expect(container.read(commandPaletteVisibleProvider), isTrue);
  });
}

Future<ProviderContainer> _pumpShortcuts(WidgetTester tester) async {
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
      child: const MaterialApp(
        home: PresentationKeyboardShortcuts(
          child: Scaffold(body: SizedBox(width: 240, height: 160)),
        ),
      ),
    ),
  );
  await tester.pump();

  return container;
}

Future<void> _sendShortcut(
  WidgetTester tester,
  LogicalKeyboardKey key, {
  bool control = false,
  bool meta = false,
  bool shift = false,
}) async {
  if (control) {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  }
  if (meta) {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
  }
  if (shift) {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  }

  await tester.sendKeyEvent(key);

  if (shift) {
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  }
  if (meta) {
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
  }
  if (control) {
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  }
}

Presentation _presentation() {
  return Presentation(
    id: 'keyboard-test',
    title: 'Keyboard Test',
    slides: [
      Slide(
        id: 'slide',
        title: 'Slide',
        components: [
          _shape(id: 'background', zIndex: 0),
          _text(id: 'title', text: 'Quarterly update', zIndex: 1),
          _shape(id: 'badge', type: ComponentType.circle, zIndex: 2),
        ],
      ),
    ],
  );
}

List<PresentationComponent> _components(ProviderContainer container) {
  final presentation = container.read(presentationProvider);
  return presentation.slides[presentation.currentSlideIndex].components;
}

List<String> _componentIds(ProviderContainer container) {
  return _components(container).map((component) => component.id).toList();
}

PresentationComponent _component(
  List<PresentationComponent> components,
  String id,
) {
  return components.firstWhere((component) => component.id == id);
}

PresentationComponent _shape({
  required String id,
  required int zIndex,
  ComponentType type = ComponentType.shape,
}) {
  return PresentationComponent(
    id: id,
    type: type,
    position: Offset.zero,
    size: const Size(100, 80),
    zIndex: zIndex,
  );
}

PresentationComponent _text({
  required String id,
  required String text,
  required int zIndex,
}) {
  return PresentationComponent(
    id: id,
    type: ComponentType.richText,
    position: const Offset(40, 40),
    size: const Size(240, 80),
    zIndex: zIndex,
    richText: RichTextContent(
      text: text,
      style: const TextStyle(color: Colors.white, fontSize: 24),
    ),
  );
}
