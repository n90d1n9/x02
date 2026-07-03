import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/models/component.dart';
import 'package:ky_slide/models/presentation.dart';
import 'package:ky_slide/models/presentation_component.dart';
import 'package:ky_slide/models/slide.dart';
import 'package:ky_slide/models/slide_transition_type.dart';
import 'package:ky_slide/models/style/gradient_animation.dart';
import 'package:ky_slide/models/style/particle_effect.dart';
import 'package:ky_slide/models/style/presentation_theme.dart';
import 'package:ky_slide/states/history_provider.dart';
import 'package:ky_slide/states/presentation_provider.dart';
import 'package:ky_slide/states/slide_property_actions_provider.dart';
import 'package:ky_slide/widgets/slide_properties_panel.dart';

void main() {
  test('slide copyWith can clear nullable design fields', () {
    final slide = Slide(
      id: 'slide',
      title: 'Intro',
      notes: 'Speaker notes',
      components: const [],
      backgroundColor: Colors.red,
      backgroundGradient: GradientAnimation(colors: const [Colors.red]),
      backgroundParticles: ParticleEffect(color: Colors.blue),
      backgroundVideo: 'video.mp4',
    );

    final cleared = slide.copyWith(
      title: null,
      notes: null,
      backgroundColor: null,
      backgroundGradient: null,
      backgroundParticles: null,
      backgroundVideo: null,
    );

    expect(cleared.title, isNull);
    expect(cleared.notes, isNull);
    expect(cleared.backgroundColor, isNull);
    expect(cleared.backgroundGradient, isNull);
    expect(cleared.backgroundParticles, isNull);
    expect(cleared.backgroundVideo, isNull);
  });

  test('slide property actions update current slide with history labels', () {
    final container = _container();
    addTearDown(container.dispose);
    final actions = container.read(slidePropertyActionsProvider);

    expect(actions.renameCurrentSlide('Roadmap'), isTrue);
    expect(_slide(container).title, 'Roadmap');
    expect(container.read(historyProvider).undoLabel, 'Rename slide');

    expect(actions.updateSpeakerNotes('Mention the Q3 launch.'), isTrue);
    expect(_slide(container).notes, 'Mention the Q3 launch.');
    expect(container.read(historyProvider).undoLabel, 'Update speaker notes');

    expect(actions.updateSpeakerNotes('   '), isTrue);
    expect(_slide(container).notes, isNull);
    expect(container.read(historyProvider).undoLabel, 'Update speaker notes');

    expect(actions.updateBackgroundColor(const Color(0xFF14B8A6)), isTrue);
    expect(_slide(container).backgroundColor, const Color(0xFF14B8A6));
    expect(
      container.read(historyProvider).undoLabel,
      'Update slide background',
    );

    expect(actions.updateTransition(SlideTransitionType.zoom), isTrue);
    expect(_slide(container).transition, SlideTransitionType.zoom);
    expect(
      container.read(historyProvider).undoLabel,
      'Update slide transition',
    );

    expect(actions.applyBackgroundGradient(), isTrue);
    expect(_slide(container).backgroundGradient, isNotNull);
    expect(container.read(historyProvider).undoLabel, 'Apply slide gradient');

    expect(actions.clearBackgroundGradient(), isTrue);
    expect(_slide(container).backgroundGradient, isNull);
    expect(container.read(historyProvider).undoLabel, 'Remove slide gradient');

    expect(actions.applyBackgroundParticles(), isTrue);
    expect(_slide(container).backgroundParticles, isNotNull);
    expect(container.read(historyProvider).undoLabel, 'Apply slide particles');

    expect(actions.clearBackgroundParticles(), isTrue);
    expect(_slide(container).backgroundParticles, isNull);
    expect(container.read(historyProvider).undoLabel, 'Remove slide particles');
  });

  testWidgets('slide properties panel edits title background and transition', (
    tester,
  ) async {
    final container = _container();
    addTearDown(container.dispose);

    await _pumpPanel(tester, container);

    expect(find.text('Slide Properties'), findsOneWidget);
    expect(find.text('Slide'), findsWidgets);
    expect(find.text('Speaker Notes'), findsOneWidget);
    expect(find.text('Background'), findsOneWidget);
    expect(find.text('Playback'), findsOneWidget);

    await tester.enterText(_textFieldWithLabel('Slide title'), 'Launch plan');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(_slide(container).title, 'Launch plan');
    expect(container.read(historyProvider).undoLabel, 'Rename slide');

    await tester.enterText(_textFieldWithLabel('Notes'), 'Open with the story');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(_slide(container).notes, 'Open with the story');
    expect(container.read(historyProvider).undoLabel, 'Update speaker notes');

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -260),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('#14B8A6'));
    await tester.pumpAndSettle();

    expect(_slide(container).backgroundColor, const Color(0xFF14B8A6));
    expect(
      container.read(historyProvider).undoLabel,
      'Update slide background',
    );

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -520),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Fade'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zoom').last);
    await tester.pumpAndSettle();

    expect(_slide(container).transition, SlideTransitionType.zoom);
    expect(
      container.read(historyProvider).undoLabel,
      'Update slide transition',
    );
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
          body: SizedBox(width: 320, child: SlidePropertiesPanel()),
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
    id: 'slide-properties-test',
    title: 'Slide Properties Test',
    slides: [
      Slide(
        id: 'slide',
        title: 'Intro',
        components: [
          PresentationComponent(
            id: 'shape',
            type: ComponentType.shape,
            position: Offset.zero,
            size: const Size(120, 80),
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

Slide _slide(ProviderContainer container) {
  final presentation = container.read(presentationProvider);
  return presentation.slides[presentation.currentSlideIndex];
}
