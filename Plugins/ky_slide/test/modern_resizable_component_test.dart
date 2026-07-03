import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/models/component.dart';
import 'package:ky_slide/models/presentation.dart';
import 'package:ky_slide/models/presentation_component.dart';
import 'package:ky_slide/models/slide.dart';
import 'package:ky_slide/models/style/presentation_theme.dart';
import 'package:ky_slide/models/transform_feedback.dart';
import 'package:ky_slide/states/alignment_guides_provider.dart';
import 'package:ky_slide/states/component_provider.dart';
import 'package:ky_slide/states/presentation_provider.dart';
import 'package:ky_slide/states/transform_feedback_provider.dart';
import 'package:ky_slide/widgets/modern_resizable_component.dart';

void main() {
  testWidgets(
    'locked selected component shows lock badge without edit handles',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(selectedComponentProvider.notifier).state = 'locked';

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  ModernResizableComponent(
                    component: PresentationComponent(
                      id: 'locked',
                      type: ComponentType.shape,
                      position: const Offset(20, 20),
                      size: const Size(120, 80),
                      backgroundColor: const Color(0xFF2563EB),
                      isLocked: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsNothing);
    },
  );

  testWidgets('dragging selected component snaps and clears guides', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        presentationProvider.overrideWith(
          (ref) => PresentationNotifier(
            initialPresentation: _presentation(
              position: const Offset(250, 80),
              size: const Size(100, 60),
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(selectedComponentProvider.notifier).state = 'moving';

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
                  ModernResizableComponent(component: _component(container)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final componentRect = tester.getRect(find.byType(Opacity));
    await tester.timedDragFrom(
      componentRect.center,
      const Offset(40, 0),
      const Duration(milliseconds: 250),
    );
    await tester.pump();

    final snappedComponent = container
        .read(presentationProvider)
        .slides
        .first
        .components
        .single;
    expect(snappedComponent.position.dx, 270);

    await tester.pumpAndSettle();

    expect(container.read(alignmentGuidesProvider), isEmpty);
    expect(container.read(transformFeedbackProvider), isNull);
  });

  testWidgets(
    'dragging selected component publishes active transform feedback',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          presentationProvider.overrideWith(
            (ref) => PresentationNotifier(
              initialPresentation: _presentation(
                position: const Offset(250, 80),
                size: const Size(100, 60),
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.read(selectedComponentProvider.notifier).state = 'moving';

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
                    ModernResizableComponent(component: _component(container)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final componentRect = tester.getRect(find.byType(Opacity));
      final gesture = await tester.startGesture(componentRect.center);
      await gesture.moveBy(const Offset(20, 0));
      await tester.pump();

      expect(
        container.read(transformFeedbackProvider)?.mode,
        TransformFeedbackMode.move,
      );

      await gesture.up();
      await tester.pumpAndSettle();

      expect(container.read(transformFeedbackProvider), isNull);
    },
  );

  testWidgets('selected component exposes accessible resize handles', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        presentationProvider.overrideWith(
          (ref) => PresentationNotifier(
            initialPresentation: _presentation(
              position: const Offset(100, 80),
              size: const Size(200, 60),
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(selectedComponentProvider.notifier).state = 'moving';

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
                  ModernResizableComponent(component: _component(container)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final rightHandle = find.byKey(const ValueKey('resize-handle-right'));
    expect(rightHandle, findsOneWidget);
    expect(find.byTooltip('Resize from right'), findsOneWidget);
  });

  testWidgets('selected component exposes an accessible rotate handle', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        presentationProvider.overrideWith(
          (ref) => PresentationNotifier(
            initialPresentation: _presentation(
              position: const Offset(100, 80),
              size: const Size(200, 60),
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(selectedComponentProvider.notifier).state = 'moving';

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
                  ModernResizableComponent(component: _component(container)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('rotate-handle')), findsOneWidget);
    expect(find.byTooltip('Rotate object'), findsOneWidget);
    expect(find.byIcon(Icons.rotate_right), findsOneWidget);
  });

  testWidgets('hovering an unselected component shows object hint', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        presentationProvider.overrideWith(
          (ref) => PresentationNotifier(
            initialPresentation: _presentation(
              position: const Offset(100, 80),
              size: const Size(200, 60),
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

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
                  ModernResizableComponent(component: _component(container)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(container.read(hoveredComponentProvider), isNull);
    expect(find.text('Revenue card'), findsNothing);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await tester.pump();

    final componentRect = tester.getRect(find.byType(Opacity));
    await mouse.moveTo(componentRect.center);
    await tester.pumpAndSettle();

    expect(container.read(hoveredComponentProvider), 'moving');
    expect(find.text('Revenue card'), findsOneWidget);
    expect(find.text('Rectangle'), findsOneWidget);

    await mouse.moveTo(const Offset(520, 320));
    await tester.pumpAndSettle();

    expect(container.read(hoveredComponentProvider), isNull);
  });
}

Presentation _presentation({required Offset position, required Size size}) {
  return Presentation(
    id: 'alignment-guide-interaction-test',
    title: 'Alignment Guide Interaction Test',
    slideSize: const Size(640, 360),
    slides: [
      Slide(
        id: 'slide',
        components: [
          PresentationComponent(
            id: 'moving',
            type: ComponentType.shape,
            layerName: 'Revenue card',
            position: position,
            size: size,
            backgroundColor: const Color(0xFF2563EB),
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

PresentationComponent _component(ProviderContainer container) {
  final presentation = container.read(presentationProvider);
  return presentation.slides.first.components.single;
}
