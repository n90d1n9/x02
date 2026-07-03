import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/models/presentation.dart';
import 'package:ky_slide/models/slide.dart';
import 'package:ky_slide/models/speaker_notes_metrics.dart';
import 'package:ky_slide/models/style/presentation_theme.dart';
import 'package:ky_slide/states/editor_view_provider.dart';
import 'package:ky_slide/states/history_provider.dart';
import 'package:ky_slide/states/presentation_provider.dart';
import 'package:ky_slide/widgets/editor/speaker_notes_editor.dart';
import 'package:ky_slide/widgets/editor/speaker_notes_pane.dart';

void main() {
  test('speaker notes metrics estimate presenter speaking time', () {
    final shortMetrics = SpeakerNotesMetrics.fromText('Remember the story');
    final longMetrics = SpeakerNotesMetrics.fromText(
      List.filled(131, 'word').join(' '),
    );
    final emptyMetrics = SpeakerNotesMetrics.fromText('   ');

    expect(shortMetrics.wordLabel, '3 words');
    expect(shortMetrics.characterLabel, '18 chars');
    expect(shortMetrics.speakingTimeLabel, '<1 min talk');
    expect(longMetrics.speakingTimeLabel, '2 min talk');
    expect(emptyMetrics.speakingTimeLabel, '0 min talk');
  });

  testWidgets('speaker notes editor renders metadata and actions', (
    tester,
  ) async {
    var cleared = false;
    var closed = false;
    var changed = '';
    final controller = TextEditingController(text: 'Remember the story');
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SpeakerNotesEditor(
            slideNumber: 2,
            slideTitle: 'Launch plan',
            metrics: SpeakerNotesMetrics.fromText(controller.text),
            canClear: true,
            controller: controller,
            focusNode: focusNode,
            onChanged: (value) => changed = value,
            onClear: () => cleared = true,
            onClose: () => closed = true,
          ),
        ),
      ),
    );

    expect(find.text('Speaker notes - Slide 2 - Launch plan'), findsOneWidget);
    expect(find.text('3 words'), findsOneWidget);
    expect(find.text('18 chars'), findsOneWidget);
    expect(find.text('<1 min talk'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Updated note');
    await tester.tap(find.byTooltip('Clear speaker notes'));
    await tester.tap(find.byTooltip('Hide speaker notes'));
    await tester.pumpAndSettle();

    expect(changed, 'Updated note');
    expect(cleared, isTrue);
    expect(closed, isTrue);
  });

  testWidgets('speaker notes pane edits and hides with history', (
    tester,
  ) async {
    final container = _container();
    addTearDown(container.dispose);

    await _pumpPane(tester, container);

    expect(find.text('Speaker notes - Slide 1 - Intro'), findsOneWidget);
    expect(find.text('2 words'), findsOneWidget);
    expect(find.text('13 chars'), findsOneWidget);
    expect(find.text('<1 min talk'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Open with customer story');
    await tester.pumpAndSettle();

    expect(find.text('4 words'), findsOneWidget);
    expect(find.text('24 chars'), findsOneWidget);
    expect(find.text('<1 min talk'), findsOneWidget);

    await tester.tap(find.byTooltip('Hide speaker notes'));
    await tester.pumpAndSettle();

    expect(container.read(speakerNotesVisibleProvider), isFalse);
    expect(_slide(container).notes, 'Open with customer story');
    expect(container.read(historyProvider).undoLabel, 'Update speaker notes');
  });

  testWidgets('speaker notes pane clears notes with history', (tester) async {
    final container = _container();
    addTearDown(container.dispose);

    await _pumpPane(tester, container);
    await tester.tap(find.byTooltip('Clear speaker notes'));
    await tester.pumpAndSettle();

    expect(_slide(container).notes, isNull);
    expect(find.text('0 words'), findsOneWidget);
    expect(find.text('0 chars'), findsOneWidget);
    expect(find.text('0 min talk'), findsOneWidget);
    expect(container.read(historyProvider).undoLabel, 'Update speaker notes');
  });
}

Future<void> _pumpPane(WidgetTester tester, ProviderContainer container) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: Scaffold(body: SpeakerNotesPane())),
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
    id: 'speaker-notes-pane-test',
    title: 'Speaker Notes Pane Test',
    slides: [
      Slide(
        id: 'slide',
        title: 'Intro',
        notes: 'Initial notes',
        components: [],
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
