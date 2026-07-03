import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/models/component.dart';
import 'package:ky_slide/models/editor_slide_jump_summary.dart';
import 'package:ky_slide/models/presentation_component.dart';
import 'package:ky_slide/models/slide.dart';
import 'package:ky_slide/widgets/editor/editor_status_bar_widgets.dart';
import 'package:ky_slide/widgets/editor/editor_status_slide_navigator.dart';

void main() {
  test('editor slide jump summary derives fallback title and metadata', () {
    final summary = EditorSlideJumpSummary.fromSlide(
      Slide(
        id: 'slide-1',
        title: '  ',
        notes: 'Presenter cue',
        components: [
          PresentationComponent(
            id: 'text-1',
            type: ComponentType.richText,
            position: Offset.zero,
            size: const Size(120, 40),
          ),
        ],
      ),
      index: 1,
    );

    expect(summary.displayTitle, 'Slide 2');
    expect(summary.objectLabel, '1 object');
    expect(summary.hasSpeakerNotes, isTrue);
  });

  testWidgets('editor slide progress meter reflects deck position', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          backgroundColor: Color(0xFF0F172A),
          body: Center(
            child: SizedBox(
              width: 120,
              child: EditorSlideProgressMeter(
                currentSlideIndex: 1,
                slideCount: 3,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byTooltip('Slide position'), findsOneWidget);
    expect(
      tester.widget<FractionallySizedBox>(find.byType(FractionallySizedBox)),
      isA<FractionallySizedBox>().having(
        (widget) => widget.widthFactor,
        'widthFactor',
        closeTo(2 / 3, 0.001),
      ),
    );
  });

  testWidgets('editor status slide navigator dispatches slide steps', (
    tester,
  ) async {
    var previousRequests = 0;
    var nextRequests = 0;
    int? selectedSlide;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          body: Center(
            child: EditorStatusControlGroup(
              children: [
                EditorStatusSlideNavigator(
                  currentSlideIndex: 1,
                  slideCount: 3,
                  slideTitles: const ['Opening', 'Plan', 'Closing'],
                  slideSummaries: const [
                    EditorSlideJumpSummary(
                      index: 0,
                      title: 'Opening',
                      objectCount: 2,
                      hasSpeakerNotes: true,
                    ),
                    EditorSlideJumpSummary(
                      index: 1,
                      title: 'Plan',
                      objectCount: 0,
                    ),
                    EditorSlideJumpSummary(
                      index: 2,
                      title: 'Closing',
                      objectCount: 1,
                    ),
                  ],
                  onPrevious: () => previousRequests++,
                  onNext: () => nextRequests++,
                  onSlideSelected: (index) => selectedSlide = index,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Slide 2 of 3'), findsOneWidget);
    expect(find.byType(EditorSlideProgressMeter), findsOneWidget);
    expect(find.byTooltip('Slide position'), findsOneWidget);

    await tester.tap(find.byTooltip('Previous slide'));
    await tester.tap(find.byTooltip('Next slide'));
    await tester.tap(find.byTooltip('Jump to slide'));
    await tester.pumpAndSettle();

    expect(find.byType(EditorSlideJumpMenuHeader), findsOneWidget);
    expect(find.byType(EditorSlideJumpMenuItem), findsNWidgets(3));
    expect(find.text('Jump to slide'), findsWidgets);
    expect(find.text('3 slides'), findsOneWidget);
    expect(find.text('2 objects'), findsOneWidget);
    expect(find.text('0 objects'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);

    await tester.tap(find.text('Closing'));
    await tester.pumpAndSettle();

    expect(previousRequests, 1);
    expect(nextRequests, 1);
    expect(selectedSlide, 2);
  });

  testWidgets('editor status slide navigator disables unavailable steps', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          body: Center(
            child: EditorStatusControlGroup(
              children: [
                EditorStatusSlideNavigator(
                  currentSlideIndex: 0,
                  slideCount: 1,
                  onPrevious: () {},
                  onNext: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Slide 1 of 1'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(
            find.widgetWithIcon(IconButton, Icons.keyboard_arrow_left),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<IconButton>(
            find.widgetWithIcon(IconButton, Icons.keyboard_arrow_right),
          )
          .onPressed,
      isNull,
    );
  });
}
