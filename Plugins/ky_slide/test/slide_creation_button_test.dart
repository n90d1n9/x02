import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/models/slide_layout.dart';
import 'package:ky_slide/models/slide_template.dart';
import 'package:ky_slide/services/slide_layout_service.dart';
import 'package:ky_slide/services/slide_template_service.dart';
import 'package:ky_slide/widgets/sidebar/slide_creation_button.dart';
import 'package:ky_slide/widgets/sidebar/slide_layout_preview_thumbnail.dart';
import 'package:ky_slide/widgets/sidebar/template_preview_thumbnail.dart';

void main() {
  testWidgets(
    'slide creation button creates blank slides from primary action',
    (tester) async {
      var createdBlank = false;

      await _pumpButton(tester, onCreateBlank: () => createdBlank = true);

      await tester.tap(find.text('New Slide'));

      expect(createdBlank, isTrue);
    },
  );

  testWidgets('slide creation button opens templates from the menu', (
    tester,
  ) async {
    var openedTemplates = false;

    await _pumpButton(tester, onOpenTemplates: () => openedTemplates = true);

    await tester.tap(find.byTooltip('New slide options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Browse templates'));
    await tester.pumpAndSettle();

    expect(openedTemplates, isTrue);
  });

  testWidgets('slide creation button inserts layout slides from the menu', (
    tester,
  ) async {
    SlideLayoutType? createdLayout;

    await _pumpButton(tester, onCreateLayout: (type) => createdLayout = type);

    await tester.tap(find.byTooltip('New slide options'));
    await tester.pumpAndSettle();

    expect(
      find.byType(SlideLayoutPreviewThumbnail),
      findsNWidgets(SlideLayoutType.values.length),
    );

    await tester.tap(find.text('Title + Content'));
    await tester.pumpAndSettle();

    expect(createdLayout, SlideLayoutType.titleAndContent);
  });

  testWidgets('slide creation button inserts template slides from the menu', (
    tester,
  ) async {
    SlideTemplateType? createdTemplate;

    await _pumpButton(
      tester,
      onCreateTemplate: (type) => createdTemplate = type,
    );

    await tester.tap(find.byTooltip('New slide options'));
    await tester.pumpAndSettle();

    expect(
      find.byType(TemplatePreviewThumbnail),
      findsNWidgets(SlideTemplateType.values.length),
    );

    await tester.tap(find.text('Metric Story'));
    await tester.pumpAndSettle();

    expect(createdTemplate, SlideTemplateType.metricStory);
  });
}

Future<void> _pumpButton(
  WidgetTester tester, {
  VoidCallback? onCreateBlank,
  VoidCallback? onOpenTemplates,
  ValueChanged<SlideLayoutType>? onCreateLayout,
  ValueChanged<SlideTemplateType>? onCreateTemplate,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 300,
            child: SlideCreationButton(
              accentColor: const Color(0xFF2563EB),
              secondaryColor: const Color(0xFF14B8A6),
              templatePalette: const [
                Color(0xFF2563EB),
                Color(0xFF14B8A6),
                Color(0xFFF59E0B),
              ],
              layouts: SlideLayoutService.recipes,
              templates: SlideTemplateService.recipes,
              onCreateBlank: onCreateBlank ?? () {},
              onOpenTemplates: onOpenTemplates ?? () {},
              onCreateLayout: onCreateLayout ?? (_) {},
              onCreateTemplate: onCreateTemplate ?? (_) {},
            ),
          ),
        ),
      ),
    ),
  );
}
