import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/models/component.dart';
import 'package:ky_slide/models/presentation_component.dart';
import 'package:ky_slide/models/rich_text_content.dart';
import 'package:ky_slide/models/slide.dart';
import 'package:ky_slide/models/slide_navigator_density.dart';
import 'package:ky_slide/models/style/presentation_theme.dart';
import 'package:ky_slide/widgets/sidebar/sidebar_action_card.dart';
import 'package:ky_slide/widgets/sidebar/slide_thumbnail_card.dart';
import 'package:ky_slide/widgets/sidebar/slide_thumbnail_preview.dart';

void main() {
  testWidgets('slide thumbnail card renders slide summary and selects', (
    tester,
  ) async {
    var selected = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 240,
            child: SlideThumbnailCard(
              slide: _slide(),
              index: 1,
              isSelected: true,
              theme: _theme(),
              slideSize: const Size(1920, 1080),
              onSelect: () => selected = true,
              onDuplicate: () {},
              onDelete: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('2'), findsOneWidget);
    expect(find.text('Quarterly story'), findsOneWidget);
    expect(find.text('2 items'), findsOneWidget);
    expect(find.byType(SidebarActionCard), findsOneWidget);

    await tester.tap(find.text('Quarterly story'));

    expect(selected, isTrue);
  });

  testWidgets('slide thumbnail card exposes duplicate and delete actions', (
    tester,
  ) async {
    var duplicated = false;
    var deleted = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 240,
            child: SlideThumbnailCard(
              slide: _slide(),
              index: 0,
              isSelected: false,
              theme: _theme(),
              slideSize: const Size(1920, 1080),
              onSelect: () {},
              onDuplicate: () => duplicated = true,
              onDelete: () => deleted = true,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Duplicate'));
    await tester.pumpAndSettle();

    expect(duplicated, isTrue);

    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(deleted, isTrue);
  });

  testWidgets('slide thumbnail card respects compact density', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 240,
            child: SlideThumbnailCard(
              slide: _slide(),
              index: 0,
              isSelected: false,
              theme: _theme(),
              slideSize: const Size(1920, 1080),
              density: SlideNavigatorDensity.compact,
              onSelect: () {},
              onDuplicate: () {},
              onDelete: () {},
            ),
          ),
        ),
      ),
    );

    final previewSize = tester.getSize(find.byType(SlideThumbnailPreview));

    expect(previewSize.height, SlideNavigatorDensity.compact.previewHeight);
  });

  testWidgets('slide thumbnail card exposes quick move actions', (
    tester,
  ) async {
    var movedUp = false;
    var movedDown = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 260,
            child: SlideThumbnailCard(
              slide: _slide(),
              index: 1,
              isSelected: false,
              theme: _theme(),
              slideSize: const Size(1920, 1080),
              canMoveUp: true,
              canMoveDown: true,
              onSelect: () {},
              onMoveUp: () => movedUp = true,
              onMoveDown: () => movedDown = true,
              onDuplicate: () {},
              onDelete: () {},
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Move slide up'));
    await tester.tap(find.byTooltip('Move slide down'));

    expect(movedUp, isTrue);
    expect(movedDown, isTrue);
  });

  testWidgets('slide thumbnail card quick delete explains the last slide', (
    tester,
  ) async {
    var unavailable = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 260,
            child: SlideThumbnailCard(
              slide: _slide(),
              index: 0,
              isSelected: false,
              theme: _theme(),
              slideSize: const Size(1920, 1080),
              canDelete: false,
              onSelect: () {},
              onDuplicate: () {},
              onDelete: () {},
              onDeleteUnavailable: () => unavailable = true,
            ),
          ),
        ),
      ),
    );

    await tester.tap(
      find.byTooltip('Presentation needs at least one slide').first,
    );

    expect(unavailable, isTrue);
  });

  testWidgets('slide thumbnail card explains why the last slide is kept', (
    tester,
  ) async {
    var deleted = false;
    var unavailable = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 240,
            child: SlideThumbnailCard(
              slide: _slide(),
              index: 0,
              isSelected: false,
              theme: _theme(),
              slideSize: const Size(1920, 1080),
              canDelete: false,
              onSelect: () {},
              onDuplicate: () {},
              onDelete: () => deleted = true,
              onDeleteUnavailable: () => unavailable = true,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();

    expect(find.text('Keep last slide'), findsOneWidget);
    expect(find.text('Presentation needs one slide'), findsOneWidget);

    await tester.tap(find.text('Keep last slide'));
    await tester.pumpAndSettle();

    expect(deleted, isFalse);
    expect(unavailable, isTrue);
  });

  testWidgets('slide thumbnail preview renders component layers compactly', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 180,
            height: 96,
            child: SlideThumbnailPreview(
              slide: _slide(),
              theme: _theme(),
              slideSize: const Size(1920, 1080),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(SlideThumbnailPreview), findsOneWidget);
  });
}

Slide _slide() {
  return Slide(
    id: 'slide-1',
    title: 'Quarterly story',
    backgroundColor: const Color(0xFF0F172A),
    components: [
      PresentationComponent(
        id: 'title',
        type: ComponentType.richText,
        position: const Offset(160, 120),
        size: const Size(820, 180),
        richText: RichTextContent(
          text: 'Quarterly story',
          style: const TextStyle(color: Colors.white, fontSize: 56),
        ),
      ),
      PresentationComponent(
        id: 'chart',
        type: ComponentType.chart,
        position: const Offset(980, 250),
        size: const Size(520, 420),
      ),
    ],
  );
}

PresentationTheme _theme() {
  return PresentationTheme(
    id: 'thumbnail-test',
    name: 'Thumbnail Test',
    primaryColor: const Color(0xFF2563EB),
    secondaryColor: const Color(0xFF14B8A6),
    backgroundColor: const Color(0xFF0F172A),
    textColor: Colors.white,
    titleStyle: const TextStyle(color: Colors.white, fontSize: 48),
    bodyStyle: const TextStyle(color: Colors.white70, fontSize: 20),
    colorPalette: const [Color(0xFF2563EB), Color(0xFF14B8A6)],
  );
}
