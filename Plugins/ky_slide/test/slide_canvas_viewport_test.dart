import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/models/presentation.dart';
import 'package:ky_slide/models/slide.dart';
import 'package:ky_slide/models/style/presentation_theme.dart';
import 'package:ky_slide/states/editor_view_provider.dart';
import 'package:ky_slide/states/presentation_provider.dart';
import 'package:ky_slide/widgets/canvas/slide_canvas_viewport.dart';

void main() {
  testWidgets('slide canvas viewport publishes size and provides scrolling', (
    tester,
  ) async {
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
          home: Scaffold(
            body: SizedBox(
              width: 420,
              height: 320,
              child: SlideCanvasViewport(
                child: SizedBox(width: 1920, height: 1080),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(container.read(canvasViewportSizeProvider), const Size(420, 320));
    expect(find.byType(SingleChildScrollView), findsNWidgets(2));
  });
}

Presentation _presentation() {
  return Presentation(
    id: 'slide-canvas-viewport-test',
    title: 'Viewport Test',
    slides: [Slide(id: 'slide', components: [])],
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
