import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/models/history_entry.dart';
import 'package:ky_slide/models/presentation.dart';
import 'package:ky_slide/models/component.dart';
import 'package:ky_slide/models/component_layer_filter.dart';
import 'package:ky_slide/models/component_layer_item.dart';
import 'package:ky_slide/models/presentation_file_format.dart';
import 'package:ky_slide/models/presentation_component.dart';
import 'package:ky_slide/models/rich_text_content.dart';
import 'package:ky_slide/models/presentation_outline.dart';
import 'package:ky_slide/models/sidebar_menu_item.dart';
import 'package:ky_slide/models/sidebar_section_id.dart';
import 'package:ky_slide/models/slide.dart';
import 'package:ky_slide/models/slide_layout.dart';
import 'package:ky_slide/models/slide_template.dart';
import 'package:ky_slide/models/style/presentation_theme.dart';
import 'package:ky_slide/services/slide_template_service.dart';
import 'package:ky_slide/states/component_provider.dart';
import 'package:ky_slide/states/history_provider.dart';
import 'package:ky_slide/states/presentation_provider.dart';
import 'package:ky_slide/states/sidebar_panel_provider.dart';
import 'package:ky_slide/widgets/sidebar/design_assist_panel.dart';
import 'package:ky_slide/widgets/sidebar/history_action_card.dart';
import 'package:ky_slide/widgets/sidebar/presentation_file_action_card.dart';
import 'package:ky_slide/widgets/sidebar/presentation_file_panel.dart';
import 'package:ky_slide/widgets/sidebar/presentation_file_sections.dart';
import 'package:ky_slide/widgets/sidebar/sidebar_action_card.dart';
import 'package:ky_slide/widgets/sidebar/sidebar_command_button.dart';
import 'package:ky_slide/widgets/sidebar/sidebar_command_grid.dart';
import 'package:ky_slide/widgets/sidebar/sidebar_empty_state.dart';
import 'package:ky_slide/widgets/sidebar/sidebar_filter_chips.dart';
import 'package:ky_slide/widgets/sidebar/sidebar_metadata_pill.dart';
import 'package:ky_slide/widgets/sidebar/sidebar_result_summary.dart';
import 'package:ky_slide/widgets/sidebar/sidebar_section.dart';
import 'package:ky_slide/widgets/sidebar/sidebar_menu.dart';
import 'package:ky_slide/widgets/sidebar/component_arrange_panel.dart';
import 'package:ky_slide/widgets/sidebar/component_layer_action_card.dart';
import 'package:ky_slide/widgets/sidebar/component_layers_panel.dart';
import 'package:ky_slide/widgets/sidebar/slide_outline_action_card.dart';
import 'package:ky_slide/widgets/sidebar/slide_outline_panel.dart';
import 'package:ky_slide/widgets/sidebar/slide_layout_preview_thumbnail.dart';
import 'package:ky_slide/widgets/sidebar/template_action_card.dart';
import 'package:ky_slide/widgets/sidebar/template_preview_thumbnail.dart';

void main() {
  test('sidebar expansion provider uses section defaults', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(activeSidebarMenuProvider), SidebarMenuItem.slides);
    expect(container.read(outlineSearchQueryProvider), isEmpty);
    expect(container.read(designAssistSearchQueryProvider), isEmpty);
    expect(container.read(designAssistCategoryProvider), isNull);
    expect(container.read(slideSearchQueryProvider), isEmpty);
    expect(container.read(layerSearchQueryProvider), isEmpty);
    expect(container.read(layerFilterProvider), ComponentLayerFilter.all);
    expect(
      container.read(
        sidebarSectionExpandedProvider(SidebarSectionId.designAssist),
      ),
      isTrue,
    );
    expect(
      container.read(sidebarSectionExpandedProvider(SidebarSectionId.outline)),
      isTrue,
    );
  });

  testWidgets('sidebar menu renders destinations and selects an item', (
    tester,
  ) async {
    var selectedItem = SidebarMenuItem.slides;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return SidebarMenu(
                selectedItem: selectedItem,
                accentColor: const Color(0xFF2563EB),
                onSelected: (item) {
                  setState(() => selectedItem = item);
                },
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('Slides'), findsOneWidget);
    expect(find.text('Design'), findsOneWidget);
    expect(find.text('Outline'), findsOneWidget);
    expect(find.text('Layers'), findsOneWidget);
    expect(find.text('Arrange'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('File'), findsOneWidget);

    await tester.tap(find.text('Arrange'));
    await tester.pumpAndSettle();

    expect(selectedItem, SidebarMenuItem.arrange);
  });

  testWidgets('component layer action card renders metadata and selects', (
    tester,
  ) async {
    var selected = false;
    var toggled = false;
    var locked = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 280,
            child: ComponentLayerActionCard(
              item: _layerItem(),
              isSelected: true,
              accentColor: const Color(0xFF2563EB),
              onPressed: () => selected = true,
              onToggleVisibility: () => toggled = true,
              onToggleLock: () => locked = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Quarterly update'), findsOneWidget);
    expect(find.text('Text'), findsOneWidget);
    expect(find.text('z 10'), findsOneWidget);
    expect(find.byTooltip('Hide layer'), findsOneWidget);
    expect(find.byTooltip('Lock layer'), findsOneWidget);

    await tester.tap(find.text('Quarterly update'));
    await tester.pump();

    expect(selected, isTrue);

    await tester.tap(find.byTooltip('Hide layer'));
    await tester.pump();

    expect(toggled, isTrue);

    await tester.tap(find.byTooltip('Lock layer'));
    await tester.pump();

    expect(locked, isTrue);
  });

  testWidgets('component layers panel selects and brings a layer forward', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        presentationProvider.overrideWith(
          (ref) => PresentationNotifier(
            initialPresentation: _presentationWithLayers(),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(width: 320, child: ComponentLayersPanel()),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Layers'), findsOneWidget);
    expect(find.text('3 objects'), findsOneWidget);
    expect(find.text('Quarterly update'), findsOneWidget);
    expect(find.text('z 10'), findsOneWidget);
    expect(find.byTooltip('Drag to reorder layer'), findsNWidgets(3));

    await _tapVisible(tester, find.text('Quarterly update'));

    expect(container.read(selectedComponentProvider), 'title');

    await _tapVisible(tester, find.text('Forward'));

    final components = container
        .read(presentationProvider)
        .slides
        .first
        .components;
    final titleComponent = components.firstWhere(
      (component) => component.id == 'title',
    );
    final badgeComponent = components.firstWhere(
      (component) => component.id == 'badge',
    );
    expect(titleComponent.zIndex, 2);
    expect(badgeComponent.zIndex, 1);
    expect(find.text('z 2'), findsOneWidget);

    await _tapVisible(tester, find.byTooltip('Hide layer').first);

    final hiddenTitleComponent = container
        .read(presentationProvider)
        .slides
        .first
        .components
        .firstWhere((component) => component.id == 'title');
    expect(hiddenTitleComponent.isVisible, isFalse);
    expect(find.byTooltip('Show layer'), findsOneWidget);

    await _tapVisible(tester, find.byTooltip('Lock layer').first);

    final lockedTitleComponent = container
        .read(presentationProvider)
        .slides
        .first
        .components
        .firstWhere((component) => component.id == 'title');
    expect(lockedTitleComponent.isLocked, isTrue);
    expect(find.byTooltip('Unlock layer'), findsOneWidget);
  });

  testWidgets('component layers panel filters and clears layer search', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        presentationProvider.overrideWith(
          (ref) => PresentationNotifier(
            initialPresentation: _presentationWithLayers(),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(width: 320, child: ComponentLayersPanel()),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Quarterly update'), findsOneWidget);
    expect(find.text('Circle'), findsWidgets);
    expect(find.text('3 objects'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'circle');
    await tester.pumpAndSettle();

    expect(container.read(layerSearchQueryProvider), 'circle');
    expect(find.text('Quarterly update'), findsNothing);
    expect(find.text('Circle'), findsWidgets);
    expect(find.text('1 match'), findsOneWidget);
    expect(find.byTooltip('Drag to reorder layer'), findsNothing);

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();

    expect(container.read(layerSearchQueryProvider), isEmpty);
    expect(find.text('Quarterly update'), findsOneWidget);
    expect(find.text('Circle'), findsWidgets);
    expect(find.text('3 objects'), findsOneWidget);
  });

  testWidgets(
    'component layers panel filters by layer state and clears filters',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          presentationProvider.overrideWith(
            (ref) => PresentationNotifier(
              initialPresentation: _presentationWithLayerStates(),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: SizedBox(width: 320, child: ComponentLayersPanel()),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Quarterly update'), findsOneWidget);
      expect(find.text('Hidden cue'), findsOneWidget);
      expect(find.text('4 objects'), findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(-120, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hidden'));
      await tester.pumpAndSettle();

      expect(container.read(layerFilterProvider), ComponentLayerFilter.hidden);
      expect(find.text('Hidden cue'), findsOneWidget);
      expect(find.text('Quarterly update'), findsNothing);
      expect(find.text('1 match'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'quarter');
      await tester.pumpAndSettle();

      expect(find.text('No matching layers'), findsOneWidget);

      await tester.tap(find.text('Clear filters'));
      await tester.pumpAndSettle();

      expect(container.read(layerSearchQueryProvider), isEmpty);
      expect(container.read(layerFilterProvider), ComponentLayerFilter.all);
      expect(find.text('Quarterly update'), findsOneWidget);
      expect(find.text('Hidden cue'), findsOneWidget);
      expect(find.text('4 objects'), findsOneWidget);
    },
  );

  testWidgets('component layers panel shows and unlocks all layers', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        presentationProvider.overrideWith(
          (ref) => PresentationNotifier(
            initialPresentation: _presentationWithLayerStates(),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(width: 320, child: ComponentLayersPanel()),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Show all'), findsOneWidget);
    expect(find.text('Unlock all'), findsOneWidget);

    await tester.tap(find.text('Show all'));
    await tester.pumpAndSettle();

    var components = container
        .read(presentationProvider)
        .slides
        .first
        .components;
    expect(
      components
          .firstWhere((component) => component.id == 'hidden-cue')
          .isVisible,
      isTrue,
    );
    expect(container.read(historyProvider).undoLabel, 'Show all layers');

    await tester.tap(find.text('Unlock all'));
    await tester.pumpAndSettle();

    components = container.read(presentationProvider).slides.first.components;
    expect(
      components.firstWhere((component) => component.id == 'badge').isLocked,
      isFalse,
    );
    expect(container.read(historyProvider).undoLabel, 'Unlock all layers');
  });

  testWidgets('component layers panel duplicates and deletes selected layer', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        presentationProvider.overrideWith(
          (ref) => PresentationNotifier(
            initialPresentation: _presentationWithLayers(),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(width: 320, child: ComponentLayersPanel()),
            ),
          ),
        ),
      ),
    );

    await _tapVisible(tester, find.text('Quarterly update'));
    await _tapVisible(tester, find.text('Duplicate'));

    var presentation = container.read(presentationProvider);
    var components = presentation.slides.first.components;
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
    expect(duplicate.zIndex, 31);
    expect(find.text('4 objects'), findsOneWidget);
    expect(container.read(historyProvider).undoLabel, 'Duplicate layer');

    await _tapVisible(tester, find.text('Delete'));

    presentation = container.read(presentationProvider);
    components = presentation.slides.first.components;
    expect(
      components.map((component) => component.id),
      isNot(contains(duplicate.id)),
    );
    expect(components.length, 3);
    expect(container.read(selectedComponentProvider), isNull);
    expect(container.read(historyProvider).undoLabel, 'Delete layer');
  });

  testWidgets('component layers panel renames selected layer', (tester) async {
    final container = ProviderContainer(
      overrides: [
        presentationProvider.overrideWith(
          (ref) => PresentationNotifier(
            initialPresentation: _presentationWithLayers(),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(width: 320, child: ComponentLayersPanel()),
            ),
          ),
        ),
      ),
    );

    await _tapVisible(tester, find.text('Quarterly update'));
    await _tapVisible(tester, find.text('Rename'));

    expect(find.text('Rename layer'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'Executive headline');
    await tester.tap(find.widgetWithText(FilledButton, 'Rename'));
    await tester.pumpAndSettle();

    final renamed = container
        .read(presentationProvider)
        .slides
        .first
        .components
        .firstWhere((component) => component.id == 'title');
    expect(renamed.layerName, 'Executive headline');
    expect(find.text('Executive headline'), findsOneWidget);
    expect(find.text('Quarterly update'), findsNothing);
    expect(container.read(historyProvider).undoLabel, 'Rename layer');

    await tester.enterText(find.byType(TextField), 'quarterly');
    await tester.pumpAndSettle();

    expect(find.text('Executive headline'), findsOneWidget);
    expect(find.text('1 match'), findsOneWidget);
  });

  testWidgets('component layers panel selects adjacent layers', (tester) async {
    final container = ProviderContainer(
      overrides: [
        presentationProvider.overrideWith(
          (ref) => PresentationNotifier(
            initialPresentation: _presentationWithLayers(),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(width: 320, child: ComponentLayersPanel()),
            ),
          ),
        ),
      ),
    );

    await _tapVisible(tester, find.text('Quarterly update'));

    expect(container.read(selectedComponentProvider), 'title');

    await _tapVisible(tester, find.text('Above'));

    expect(container.read(selectedComponentProvider), 'badge');

    await _tapVisible(tester, find.text('Below'));

    expect(container.read(selectedComponentProvider), 'title');

    await tester.enterText(find.byType(TextField), 'quarterly');
    await tester.pumpAndSettle();

    expect(find.text('1 match'), findsOneWidget);

    await _tapVisible(tester, find.text('Above'), warnIfMissed: false);

    expect(container.read(selectedComponentProvider), 'title');
  });

  testWidgets(
    'component layers panel reveals a selected layer hidden by filters',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          presentationProvider.overrideWith(
            (ref) => PresentationNotifier(
              initialPresentation: _presentationWithLayers(),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: SizedBox(width: 320, child: ComponentLayersPanel()),
              ),
            ),
          ),
        ),
      );

      await _tapVisible(tester, find.text('Quarterly update'));
      await tester.enterText(find.byType(TextField), 'circle');
      await tester.pumpAndSettle();

      expect(container.read(selectedComponentProvider), 'title');
      expect(container.read(layerSearchQueryProvider), 'circle');
      expect(
        find.text('Selected layer hidden by filters: Quarterly update'),
        findsOneWidget,
      );

      await _tapVisible(tester, find.text('Reveal'));

      expect(container.read(selectedComponentProvider), 'title');
      expect(container.read(layerSearchQueryProvider), isEmpty);
      expect(container.read(layerFilterProvider), ComponentLayerFilter.all);
      expect(
        find.text('Selected layer hidden by filters: Quarterly update'),
        findsNothing,
      );
      expect(find.text('Quarterly update'), findsOneWidget);
      expect(find.text('3 objects'), findsOneWidget);
    },
  );

  testWidgets('component arrange panel aligns rotates and layers selection', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        presentationProvider.overrideWith(
          (ref) => PresentationNotifier(
            initialPresentation: _presentationWithLayers(),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(selectedComponentProvider.notifier).state = 'title';

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(width: 320, child: ComponentArrangePanel()),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Arrange'), findsOneWidget);
    expect(find.text('Quarterly update'), findsOneWidget);
    expect(find.text('Align'), findsOneWidget);
    expect(find.text('Position'), findsOneWidget);
    expect(find.text('Layer Order'), findsOneWidget);

    await _tapVisible(tester, find.text('Left'));

    var component = _component(container, 'title');
    expect(component.position.dx, 0);
    expect(container.read(historyProvider).undoLabel, 'Arrange layer');

    await _tapVisible(tester, find.text('Rotate right'));

    component = _component(container, 'title');
    expect(component.rotation, 90);
    expect(container.read(historyProvider).undoLabel, 'Arrange layer');

    await _tapVisible(tester, find.text('To back'));

    component = _component(container, 'title');
    expect(component.zIndex, -1);
    expect(container.read(historyProvider).undoLabel, 'Send layer to back');
  });

  testWidgets('sidebar action card provides a reusable tappable shell', (
    tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SidebarActionCard(
            semanticsLabel: 'Open reusable card',
            onPressed: () => tapped = true,
            child: const Text('Reusable card'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Reusable card'));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('presentation file action card renders status and format', (
    tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 280,
            child: PresentationFileActionCard(
              capability: const PresentationFileCapability(
                format: PresentationFileFormat.pptx,
                operation: PresentationFileOperation.export,
                support: PresentationFileSupport.native,
                title: 'Export PPTX',
                description: 'Native OpenXML export.',
                actionLabel: 'Export',
              ),
              accentColor: const Color(0xFF2563EB),
              onPressed: () => tapped = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Export PPTX'), findsOneWidget);
    expect(find.text('Native'), findsOneWidget);
    expect(find.text('.pptx'), findsOneWidget);

    await tester.tap(find.text('Export PPTX'));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('presentation file summary card renders deck metadata', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 280,
            child: PresentationFileSummaryCard(
              title: 'Investor Update',
              slideCount: 8,
              slideSize: Size(1920, 1080),
              accentColor: Color(0xFF2563EB),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Investor Update'), findsOneWidget);
    expect(find.text('8 slides'), findsOneWidget);
    expect(find.text('16:9'), findsOneWidget);
  });

  testWidgets('presentation file capability group selects capabilities', (
    tester,
  ) async {
    PresentationFileCapability? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child: PresentationFileCapabilityGroup(
              title: 'Export',
              icon: Icons.file_download_outlined,
              color: const Color(0xFF22C55E),
              accentColor: const Color(0xFF22C55E),
              capabilities: const [
                PresentationFileCapability(
                  format: PresentationFileFormat.pptx,
                  operation: PresentationFileOperation.export,
                  support: PresentationFileSupport.native,
                  title: 'Export PPTX',
                  description: 'Native export.',
                  actionLabel: 'Export',
                ),
                PresentationFileCapability(
                  format: PresentationFileFormat.pdf,
                  operation: PresentationFileOperation.export,
                  support: PresentationFileSupport.planned,
                  title: 'Export PDF',
                  description: 'Planned export.',
                  actionLabel: 'Export',
                ),
              ],
              onSelected: (capability) => selected = capability,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Export'), findsWidgets);
    expect(find.text('Export PPTX'), findsOneWidget);
    expect(find.text('Export PDF'), findsOneWidget);

    await tester.tap(find.text('Export PDF'));
    await tester.pump();

    expect(selected?.format, PresentationFileFormat.pdf);
  });

  testWidgets('presentation file panel exports through injected saver', (
    tester,
  ) async {
    String? savedFileName;
    Uint8List? savedBytes;
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
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 320,
                child: PresentationFilePanel(
                  savePptxFile: (fileName, bytes) async {
                    savedFileName = fileName;
                    savedBytes = bytes;
                    return '/tmp/$fileName';
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Export PPTX'));
    await tester.pumpAndSettle();

    expect(savedFileName, 'Sidebar Test.pptx');
    expect(savedBytes, isNotNull);
    expect(savedBytes, isNotEmpty);
    expect(find.text('Exported Sidebar Test.pptx.'), findsOneWidget);
  });

  testWidgets(
    'sidebar action card highlights selected state with accent color',
    (tester) async {
      const accentColor = Color(0xFF2563EB);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SidebarActionCard(
              accentColor: accentColor,
              selected: true,
              child: Text('Selected card'),
            ),
          ),
        ),
      );

      final container = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byType(SidebarActionCard),
          matching: find.byType(AnimatedContainer),
        ),
      );
      final decoration = container.decoration! as BoxDecoration;
      final border = decoration.border! as Border;

      expect(decoration.color, accentColor.withValues(alpha: 0.12));
      expect(border.top.color, accentColor.withValues(alpha: 0.48));
      expect(decoration.boxShadow, isNotEmpty);
    },
  );

  testWidgets('sidebar command button respects enabled state', (tester) async {
    var enabledTapCount = 0;
    var disabledTapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              SidebarCommandButton(
                icon: Icons.undo,
                label: 'Undo',
                isEnabled: true,
                onPressed: () => enabledTapCount++,
              ),
              SidebarCommandButton(
                icon: Icons.redo,
                label: 'Redo',
                isEnabled: false,
                onPressed: () => disabledTapCount++,
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Undo'));
    await tester.tap(find.text('Redo'));
    await tester.pump();

    expect(enabledTapCount, 1);
    expect(disabledTapCount, 0);
  });

  testWidgets('sidebar command grid lays out reusable command rows', (
    tester,
  ) async {
    var tapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            child: SidebarCommandGrid(
              columns: 3,
              accentColor: const Color(0xFF2563EB),
              items: [
                SidebarCommandGridItem(
                  icon: Icons.drive_file_rename_outline,
                  label: 'Rename',
                  isEnabled: true,
                  onPressed: () => tapCount++,
                ),
                SidebarCommandGridItem(
                  icon: Icons.copy,
                  label: 'Duplicate',
                  isEnabled: false,
                  onPressed: () => tapCount++,
                ),
                SidebarCommandGridItem(
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  isEnabled: true,
                  onPressed: () => tapCount++,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Rename'), findsOneWidget);
    expect(find.text('Duplicate'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);

    await tester.tap(find.text('Rename'));
    await tester.tap(find.text('Duplicate'));
    await tester.tap(find.text('Delete'));
    await tester.pump();

    expect(tapCount, 2);
  });

  testWidgets('template preview thumbnails render for every template type', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: SlideTemplateType.values.map((type) {
              return SizedBox(
                width: 80,
                child: TemplatePreviewThumbnail(
                  type: type,
                  accentColor: const Color(0xFF2563EB),
                  secondaryColor: const Color(0xFF14B8A6),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );

    expect(
      find.byType(TemplatePreviewThumbnail),
      findsNWidgets(SlideTemplateType.values.length),
    );
  });

  testWidgets('template preview thumbnails fit compact sidebar slots', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: SlideTemplateType.values.map((type) {
              return SizedBox(
                width: 58,
                child: TemplatePreviewThumbnail(
                  type: type,
                  accentColor: const Color(0xFF2563EB),
                  secondaryColor: const Color(0xFF14B8A6),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );

    expect(
      find.byType(TemplatePreviewThumbnail),
      findsNWidgets(SlideTemplateType.values.length),
    );
  });

  testWidgets('slide layout preview thumbnails render for every layout type', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: SlideLayoutType.values.map((type) {
              return SizedBox(
                width: 80,
                child: SlideLayoutPreviewThumbnail(
                  type: type,
                  accentColor: const Color(0xFF14B8A6),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );

    expect(
      find.byType(SlideLayoutPreviewThumbnail),
      findsNWidgets(SlideLayoutType.values.length),
    );
  });

  testWidgets('slide layout preview thumbnails fit compact menu slots', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: SlideLayoutType.values.map((type) {
              return SizedBox(
                width: 46,
                child: SlideLayoutPreviewThumbnail(
                  type: type,
                  accentColor: const Color(0xFF14B8A6),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );

    expect(
      find.byType(SlideLayoutPreviewThumbnail),
      findsNWidgets(SlideLayoutType.values.length),
    );
  });

  testWidgets('template action card renders metadata and action label', (
    tester,
  ) async {
    var tapped = false;
    final recipe = SlideTemplateService.recipeFor(
      SlideTemplateType.executiveCover,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 260,
            child: TemplateActionCard(
              recipe: recipe,
              accentColor: const Color(0xFF2563EB),
              secondaryColor: const Color(0xFF14B8A6),
              onPressed: () => tapped = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Executive Cover'), findsOneWidget);
    expect(find.text('Category: Cover'), findsOneWidget);
    expect(find.text('6 items'), findsOneWidget);
    expect(find.text('Add cover'), findsOneWidget);

    await tester.tap(find.text('Add cover'));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('slide outline action card renders jump metadata and selects', (
    tester,
  ) async {
    var selected = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 280,
            child: SlideOutlineActionCard(
              item: const SlideOutlineItem(
                index: 1,
                slideId: 'slide-2',
                title: 'Follow up',
                snippet: 'Next steps and owner checkpoints',
                componentCount: 3,
              ),
              isSelected: true,
              accentColor: const Color(0xFF2563EB),
              onPressed: () => selected = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('2'), findsOneWidget);
    expect(find.text('Follow up'), findsOneWidget);
    expect(find.text('3 items'), findsOneWidget);
    expect(find.text('Next steps and owner checkpoints'), findsOneWidget);

    await tester.tap(find.text('Follow up'));
    await tester.pump();

    expect(selected, isTrue);
  });

  testWidgets('history action card renders summary and restores', (
    tester,
  ) async {
    var restored = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 280,
            child: HistoryActionCard(
              entry: HistoryEntry(
                presentation: _presentation(),
                label: 'Add slide',
              ),
              isCurrent: false,
              isFuture: false,
              onSelected: () => restored = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Add slide'), findsOneWidget);
    expect(find.text('2 slides - Slide 1/2: Opening'), findsOneWidget);
    expect(find.byIcon(Icons.restore), findsOneWidget);

    await tester.tap(find.text('Add slide'));
    await tester.pump();

    expect(restored, isTrue);
  });

  testWidgets('sidebar section renders header copy and child content', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SidebarSection(
            title: 'Design Assist',
            subtitle: 'Reusable sidebar section',
            icon: Icons.auto_awesome,
            gradientColors: [Color(0xFF2563EB), Color(0xFF14B8A6)],
            child: Text('Section body'),
          ),
        ),
      ),
    );

    expect(find.text('Design Assist'), findsOneWidget);
    expect(find.text('Reusable sidebar section'), findsOneWidget);
    expect(find.text('Section body'), findsOneWidget);
  });

  testWidgets('sidebar empty state renders compact message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SidebarEmptyState(message: 'No matching slides')),
      ),
    );

    expect(find.text('No matching slides'), findsOneWidget);
  });

  testWidgets('sidebar empty state can render a compact action', (
    tester,
  ) async {
    var cleared = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SidebarEmptyState(
            message: 'No matching slides',
            actionLabel: 'Clear search',
            onAction: () => cleared = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Clear search'));
    await tester.pump();

    expect(cleared, isTrue);
  });

  testWidgets('sidebar result summary renders visible counts', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              SidebarResultSummary(
                count: 3,
                isFiltered: false,
                singularLabel: 'slide',
                pluralLabel: 'slides',
              ),
              SidebarResultSummary(
                count: 1,
                isFiltered: true,
                singularLabel: 'template',
                pluralLabel: 'templates',
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('3 slides'), findsOneWidget);
    expect(find.text('1 match'), findsOneWidget);
  });

  testWidgets('sidebar metadata pill renders compact label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SidebarMetadataPill(
            icon: Icons.layers_outlined,
            label: '6 items',
            color: Color(0xFF38BDF8),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.layers_outlined), findsOneWidget);
    expect(find.text('6 items'), findsOneWidget);
  });

  testWidgets('sidebar filter chips render optional count badges', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SidebarFilterChips<String>(
            selectedValue: 'all',
            accentColor: const Color(0xFF2563EB),
            onSelected: (_) {},
            options: const [
              SidebarFilterChipOption(
                value: 'all',
                label: 'All',
                icon: Icons.dashboard_outlined,
                badgeLabel: '4',
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('All'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('collapsible sidebar section toggles body content', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SidebarSection(
            title: 'Design Assist',
            subtitle: 'Reusable sidebar section',
            icon: Icons.auto_awesome,
            gradientColors: [Color(0xFF2563EB), Color(0xFF14B8A6)],
            collapsible: true,
            initiallyExpanded: false,
            child: Text('Section body'),
          ),
        ),
      ),
    );

    expect(find.text('Design Assist'), findsOneWidget);
    expect(find.text('Reusable sidebar section'), findsNothing);
    expect(find.text('Section body'), findsNothing);

    await tester.tap(find.text('Design Assist'));
    await tester.pumpAndSettle();

    expect(find.text('Reusable sidebar section'), findsOneWidget);
    expect(find.text('Section body'), findsOneWidget);

    await tester.tap(find.text('Design Assist'));
    await tester.pumpAndSettle();

    expect(find.text('Section body'), findsNothing);
  });

  testWidgets('design assist keeps expansion state across rebuilds', (
    tester,
  ) async {
    late StateSetter refresh;
    final firstTemplateName = SlideTemplateService.recipes.first.name;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          presentationProvider.overrideWith(
            (ref) => PresentationNotifier(initialPresentation: _presentation()),
          ),
        ],
        child: MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              refresh = setState;
              return const Scaffold(body: DesignAssistPanel());
            },
          ),
        ),
      ),
    );

    expect(find.text('Design Assist'), findsOneWidget);
    expect(find.text(firstTemplateName), findsOneWidget);

    await tester.tap(find.text('Design Assist'));
    await tester.pumpAndSettle();

    expect(find.text(firstTemplateName), findsNothing);

    refresh(() {});
    await tester.pump();

    expect(find.text(firstTemplateName), findsNothing);
  });

  testWidgets('design assist filters and clears template search', (
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
        child: const MaterialApp(home: Scaffold(body: DesignAssistPanel())),
      ),
    );

    expect(find.text('Executive Cover'), findsOneWidget);
    expect(find.text('Metric Story'), findsOneWidget);
    expect(find.text('Category: Cover'), findsOneWidget);
    expect(find.text('6 items'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'metric');
    await tester.pumpAndSettle();

    expect(container.read(designAssistSearchQueryProvider), 'metric');
    expect(find.text('Executive Cover'), findsNothing);
    expect(find.text('Metric Story'), findsOneWidget);
    expect(find.text('Category: Metrics'), findsOneWidget);
    expect(find.text('1 match'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(3));

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();

    expect(container.read(designAssistSearchQueryProvider), isEmpty);
    expect(find.text('Executive Cover'), findsOneWidget);
    expect(find.text('Metric Story'), findsOneWidget);
    expect(find.text('4 templates'), findsOneWidget);
  });

  testWidgets('design assist category chips filter templates', (tester) async {
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
        child: const MaterialApp(home: Scaffold(body: DesignAssistPanel())),
      ),
    );

    expect(find.text('Executive Cover'), findsOneWidget);
    expect(find.text('Metric Story'), findsOneWidget);

    await tester.tap(find.text('Metrics'));
    await tester.pumpAndSettle();

    expect(
      container.read(designAssistCategoryProvider),
      SlideTemplateCategory.metrics,
    );
    expect(find.text('Executive Cover'), findsNothing);
    expect(find.text('Metric Story'), findsOneWidget);
    expect(find.text('1 match'), findsOneWidget);

    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();

    expect(container.read(designAssistCategoryProvider), isNull);
    expect(find.text('Executive Cover'), findsOneWidget);
    expect(find.text('Metric Story'), findsOneWidget);
  });

  testWidgets('design assist no-match state clears active filters', (
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
        child: const MaterialApp(home: Scaffold(body: DesignAssistPanel())),
      ),
    );

    await tester.enterText(find.byType(TextField), 'metric');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cover'));
    await tester.pumpAndSettle();

    expect(find.text('No matching templates'), findsOneWidget);
    expect(
      container.read(designAssistCategoryProvider),
      SlideTemplateCategory.cover,
    );

    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();

    expect(container.read(designAssistSearchQueryProvider), isEmpty);
    expect(container.read(designAssistCategoryProvider), isNull);
    expect(find.text('Executive Cover'), findsOneWidget);
    expect(find.text('Metric Story'), findsOneWidget);
  });

  testWidgets('slide outline panel renders slide structure', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          presentationProvider.overrideWith(
            (ref) => PresentationNotifier(initialPresentation: _presentation()),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: SlideOutlinePanel())),
      ),
    );

    expect(find.text('Outline'), findsOneWidget);
    expect(find.text('Opening'), findsOneWidget);
    expect(find.text('Follow up'), findsOneWidget);
    expect(find.text('2 slides'), findsOneWidget);
  });

  testWidgets('slide outline panel filters and clears search', (tester) async {
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
        child: const MaterialApp(home: Scaffold(body: SlideOutlinePanel())),
      ),
    );

    await tester.enterText(find.byType(TextField), 'follow');
    await tester.pumpAndSettle();

    expect(container.read(outlineSearchQueryProvider), 'follow');
    expect(find.text('Opening'), findsNothing);
    expect(find.text('Follow up'), findsOneWidget);
    expect(find.text('1 match'), findsOneWidget);

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();

    expect(container.read(outlineSearchQueryProvider), isEmpty);
    expect(find.text('Opening'), findsOneWidget);
    expect(find.text('Follow up'), findsOneWidget);
  });
}

Future<void> _tapVisible(
  WidgetTester tester,
  Finder finder, {
  bool warnIfMissed = true,
}) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder, warnIfMissed: warnIfMissed);
  await tester.pumpAndSettle();
}

PresentationComponent _component(ProviderContainer container, String id) {
  final presentation = container.read(presentationProvider);
  final slide = presentation.slides[presentation.currentSlideIndex];

  return slide.components.firstWhere((component) => component.id == id);
}

Presentation _presentation() {
  return Presentation(
    id: 'sidebar-test',
    title: 'Sidebar Test',
    slides: [
      Slide(id: 'slide-1', title: 'Opening', components: []),
      Slide(id: 'slide-2', title: 'Follow up', components: []),
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

Presentation _presentationWithLayers() {
  final base = _presentation();

  return base.copyWith(
    slides: [
      Slide(
        id: 'slide-1',
        title: 'Opening',
        components: [
          PresentationComponent(
            id: 'background',
            type: ComponentType.shape,
            position: Offset.zero,
            size: const Size(120, 80),
            zIndex: 0,
          ),
          _layerItem().component,
          PresentationComponent(
            id: 'badge',
            type: ComponentType.circle,
            position: const Offset(40, 40),
            size: const Size(60, 60),
            zIndex: 30,
          ),
        ],
      ),
      base.slides.last,
    ],
  );
}

Presentation _presentationWithLayerStates() {
  final base = _presentation();

  return base.copyWith(
    slides: [
      Slide(
        id: 'slide-1',
        title: 'Opening',
        components: [
          PresentationComponent(
            id: 'background',
            type: ComponentType.shape,
            position: Offset.zero,
            size: const Size(120, 80),
            zIndex: 0,
          ),
          _layerItem().component,
          PresentationComponent(
            id: 'badge',
            type: ComponentType.circle,
            position: const Offset(40, 40),
            size: const Size(60, 60),
            zIndex: 30,
            isLocked: true,
          ),
          PresentationComponent(
            id: 'hidden-cue',
            type: ComponentType.richText,
            position: const Offset(80, 120),
            size: const Size(180, 64),
            zIndex: -1,
            isVisible: false,
            richText: RichTextContent(
              text: 'Hidden cue',
              style: const TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
        ],
      ),
      base.slides.last,
    ],
  );
}

ComponentLayerItem _layerItem() {
  return ComponentLayerItem(
    component: PresentationComponent(
      id: 'title',
      type: ComponentType.richText,
      position: const Offset(24, 32),
      size: const Size(240, 88),
      zIndex: 10,
      richText: RichTextContent(
        text: 'Quarterly update',
        style: const TextStyle(color: Colors.white, fontSize: 28),
      ),
    ),
    title: 'Quarterly update',
    typeLabel: 'Text',
    originalIndex: 1,
  );
}
