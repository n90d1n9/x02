import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/models/canvas_grid_preset.dart';
import 'package:ky_slide/models/component.dart';
import 'package:ky_slide/models/editor_ribbon_tab.dart';
import 'package:ky_slide/models/enums.dart';
import 'package:ky_slide/models/object_style_preset.dart';
import 'package:ky_slide/models/presentation.dart';
import 'package:ky_slide/models/presentation_component.dart';
import 'package:ky_slide/models/rich_text_content.dart';
import 'package:ky_slide/models/sidebar_menu_item.dart';
import 'package:ky_slide/models/slide.dart';
import 'package:ky_slide/models/slide_layout.dart';
import 'package:ky_slide/models/slide_template.dart';
import 'package:ky_slide/models/style/presentation_theme.dart';
import 'package:ky_slide/models/text_paragraph_format.dart';
import 'package:ky_slide/models/text_style_preset.dart';
import 'package:ky_slide/services/media_picker_service.dart';
import 'package:ky_slide/states/component_provider.dart';
import 'package:ky_slide/states/editor_view_provider.dart';
import 'package:ky_slide/states/history_provider.dart';
import 'package:ky_slide/states/media_insert_actions_provider.dart';
import 'package:ky_slide/states/presentation_provider.dart';
import 'package:ky_slide/states/sidebar_panel_provider.dart';
import 'package:ky_slide/widgets/previews/chart_preview_thumbnail.dart';
import 'package:ky_slide/widgets/previews/interactive_preview_thumbnail.dart';
import 'package:ky_slide/widgets/previews/shape_preview_thumbnail.dart';
import 'package:ky_slide/widgets/previews/slide_layout_preview_thumbnail.dart';
import 'package:ky_slide/widgets/previews/template_preview_thumbnail.dart';
import 'package:ky_slide/widgets/toolbar/modern_toolbar.dart';
import 'package:ky_slide/widgets/toolbar/ribbon_command_button.dart';
import 'package:ky_slide/widgets/toolbar/ribbon_icon_button.dart';
import 'package:ky_slide/widgets/toolbar/ribbon_menu_button.dart';
import 'package:ky_slide/widgets/toolbar/ribbon_toggle_button.dart';
import 'package:ky_slide/widgets/toolbar/toolbar_chart_gallery.dart';
import 'package:ky_slide/widgets/toolbar/toolbar_design_ribbon_content.dart';
import 'package:ky_slide/widgets/toolbar/toolbar_format_summary.dart';
import 'package:ky_slide/widgets/toolbar/toolbar_format_ribbon_content.dart';
import 'package:ky_slide/widgets/toolbar/toolbar_gallery_tile.dart';
import 'package:ky_slide/widgets/toolbar/toolbar_grid_preset_menu.dart';
import 'package:ky_slide/widgets/toolbar/toolbar_home_ribbon_content.dart';
import 'package:ky_slide/widgets/toolbar/toolbar_interactive_gallery.dart';
import 'package:ky_slide/widgets/toolbar/toolbar_insert_group.dart';
import 'package:ky_slide/widgets/toolbar/toolbar_insert_ribbon_content.dart';
import 'package:ky_slide/widgets/toolbar/toolbar_layout_gallery.dart';
import 'package:ky_slide/widgets/toolbar/toolbar_shape_gallery.dart';
import 'package:ky_slide/widgets/toolbar/toolbar_sidebar_panels_group.dart';
import 'package:ky_slide/widgets/toolbar/toolbar_template_gallery.dart';
import 'package:ky_slide/widgets/toolbar/toolbar_view_ribbon_content.dart';

void main() {
  testWidgets(
    'toolbar gallery tile renders preview label and dispatches taps',
    (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: const Color(0xFF111827),
            body: Center(
              child: ToolbarGalleryTile(
                label: 'Sample',
                tooltip: 'Insert Sample',
                borderColor: const Color(0xFF38BDF8),
                preview: const Icon(Icons.square, color: Colors.white),
                onPressed: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Sample'), findsOneWidget);
      expect(find.byTooltip('Insert Sample'), findsOneWidget);

      await tester.tap(find.byTooltip('Insert Sample'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    },
  );

  testWidgets('ribbon toggle button switches icon and dispatches taps', (
    tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF1E293B),
          body: Center(
            child: RibbonToggleButton(
              activeIcon: Icons.grid_on,
              inactiveIcon: Icons.grid_off,
              tooltip: 'Toggle Grid',
              isActive: true,
              onPressed: () => tapped = true,
            ),
          ),
        ),
      ),
    );

    expect(find.byTooltip('Toggle Grid'), findsOneWidget);
    expect(find.byIcon(Icons.grid_on), findsOneWidget);
    expect(find.byIcon(Icons.grid_off), findsNothing);

    await tester.tap(find.byTooltip('Toggle Grid'));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });

  testWidgets('ribbon icon button renders command icon and dispatches taps', (
    tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF1E293B),
          body: Center(
            child: RibbonIconButton(
              icon: Icons.add_to_photos_outlined,
              tooltip: 'New Slide',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      ),
    );

    expect(find.byTooltip('New Slide'), findsOneWidget);
    expect(find.byIcon(Icons.add_to_photos_outlined), findsOneWidget);

    await tester.tap(find.byTooltip('New Slide'));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });

  testWidgets('ribbon menu button opens menu and dispatches selection', (
    tester,
  ) async {
    String? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF1E293B),
          body: Center(
            child: RibbonMenuButton<String>(
              icon: Icons.center_focus_strong,
              tooltip: 'Open Arrange',
              enabled: true,
              onSelected: (value) => selected = value,
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'center',
                  child: Text(
                    'Center on slide',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byTooltip('Open Arrange'), findsOneWidget);
    await tester.tap(find.byTooltip('Open Arrange'));
    await tester.pumpAndSettle();

    expect(find.text('Center on slide'), findsOneWidget);
    await tester.tap(find.text('Center on slide'));
    await tester.pumpAndSettle();

    expect(selected, 'center');
  });

  testWidgets('ribbon command button renders label and dispatches taps', (
    tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF1E293B),
          body: Center(
            child: RibbonCommandButton(
              icon: Icons.layers,
              label: 'Layers',
              tooltip: 'Open Layers panel',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      ),
    );

    expect(find.byTooltip('Open Layers panel'), findsOneWidget);
    expect(find.byIcon(Icons.layers), findsOneWidget);
    expect(find.text('Layers'), findsOneWidget);

    await tester.tap(find.byTooltip('Open Layers panel'));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });

  testWidgets('toolbar format summary renders selected object metrics', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF1E293B),
          body: Center(
            child: ToolbarFormatSummary(
              accentColor: const Color(0xFF38BDF8),
              component: PresentationComponent(
                id: 'summary-object',
                type: ComponentType.shape,
                position: const Offset(40, 40),
                size: const Size(180, 90),
                backgroundColor: const Color(0xFF2563EB),
                border: const BorderSide(color: Color(0xFF14B8A6), width: 2),
                rotation: 15,
                opacity: 0.75,
                hasGlow: true,
                glowColor: const Color(0xFF14B8A6),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byTooltip('Selected object format summary'), findsOneWidget);
    expect(find.text('Shape'), findsOneWidget);
    expect(find.text('180 x 90'), findsOneWidget);
    expect(find.text('15 deg'), findsOneWidget);
    expect(find.text('Fill'), findsOneWidget);
    expect(find.text('2 px'), findsOneWidget);
    expect(find.text('75%'), findsOneWidget);
    expect(find.text('Glow'), findsOneWidget);
  });

  testWidgets('toolbar grid preset menu dispatches selected spacing', (
    tester,
  ) async {
    CanvasGridPreset? selectedPreset;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF1E293B),
          body: Center(
            child: ToolbarGridPresetMenu(
              selectedPreset: CanvasGridPreset.comfortable,
              onSelected: (preset) => selectedPreset = preset,
            ),
          ),
        ),
      ),
    );

    expect(find.byTooltip('Grid spacing'), findsWidgets);
    expect(find.text('20 px'), findsOneWidget);

    await tester.tap(find.byTooltip('Grid spacing').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Spacious'));
    await tester.pumpAndSettle();

    expect(selectedPreset, CanvasGridPreset.spacious);
  });

  testWidgets('toolbar sidebar panels group dispatches selected panel', (
    tester,
  ) async {
    SidebarMenuItem? selectedPanel;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF1E293B),
          body: Center(
            child: ToolbarSidebarPanelsGroup(
              onOpenPanel: (item) => selectedPanel = item,
            ),
          ),
        ),
      ),
    );

    expect(find.byTooltip('Open Design panel'), findsOneWidget);
    expect(find.byTooltip('Open Layers panel'), findsOneWidget);
    expect(find.byTooltip('Open History panel'), findsOneWidget);

    await tester.tap(find.byTooltip('Open History panel'));
    await tester.pumpAndSettle();

    expect(selectedPanel, SidebarMenuItem.history);
  });

  testWidgets('toolbar insert group dispatches media object commands', (
    tester,
  ) async {
    var insertedImage = false;
    var insertedVideo = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF1E293B),
          body: Center(
            child: ToolbarInsertGroup(
              onImage: () => insertedImage = true,
              onVideo: () => insertedVideo = true,
            ),
          ),
        ),
      ),
    );

    expect(find.byTooltip('Insert Image'), findsOneWidget);
    expect(find.byTooltip('Insert Video'), findsOneWidget);
    expect(find.text('Image'), findsOneWidget);
    expect(find.text('Video'), findsOneWidget);

    await tester.tap(find.byTooltip('Insert Image'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Insert Video'));
    await tester.pumpAndSettle();

    expect(insertedImage, isTrue);
    expect(insertedVideo, isTrue);
  });

  testWidgets('toolbar home ribbon content dispatches core commands', (
    tester,
  ) async {
    var addedSlides = 0;
    ToolMode? selectedTool;

    await _pumpToolbarContent(
      tester,
      ToolbarHomeRibbonContent(
        currentTool: ToolMode.select,
        canDeleteSlide: true,
        hasSelection: false,
        layoutAccentColor: const Color(0xFF2563EB),
        onAddSlide: () => addedSlides++,
        onDuplicateSlide: () {},
        onDeleteSlide: () {},
        onCreateLayout: (_) {},
        onSelectTool: () => selectedTool = ToolMode.select,
        onTextTool: () => selectedTool = ToolMode.text,
        onArrangeSelected: (_) {},
        onDeleteSelected: () {},
      ),
    );

    await tester.tap(find.byTooltip('New Slide'));
    await tester.tap(find.byTooltip('Text'));
    await tester.pumpAndSettle();

    expect(addedSlides, 1);
    expect(selectedTool, ToolMode.text);
  });

  testWidgets('toolbar insert ribbon content dispatches object commands', (
    tester,
  ) async {
    var insertedImage = false;
    ChartType? chartType;
    ComponentType? shapeType;

    await _pumpToolbarContent(
      tester,
      ToolbarInsertRibbonContent(
        palette: const [Color(0xFF2563EB), Color(0xFF14B8A6)],
        accentColor: const Color(0xFF2563EB),
        secondaryColor: const Color(0xFF14B8A6),
        onImage: () => insertedImage = true,
        onVideo: () {},
        onCreateChart: (type) => chartType = type,
        onCreateShape: (type) => shapeType = type,
        onCreateInteractive: (_) {},
      ),
    );

    await tester.tap(find.byTooltip('Insert Image'));
    await tester.tap(find.byTooltip('Insert Bar Chart'));
    await _scrollToolbarTo(tester, find.byTooltip('Insert Rectangle shape'));
    await tester.tap(find.byTooltip('Insert Rectangle shape'));
    await tester.pumpAndSettle();

    expect(insertedImage, isTrue);
    expect(chartType, ChartType.bar);
    expect(shapeType, ComponentType.shape);
  });

  testWidgets('toolbar design and view ribbon content dispatch commands', (
    tester,
  ) async {
    SidebarMenuItem? selectedPanel;
    SlideTemplateType? selectedTemplate;
    var toggledGrid = false;
    var toggledSnap = false;
    CanvasGridPreset? selectedGridPreset;
    var toggledInspector = false;
    var openedSlideSorter = false;

    await _pumpToolbarContent(
      tester,
      ToolbarDesignRibbonContent(
        palette: const [Color(0xFF2563EB), Color(0xFF14B8A6)],
        secondaryColor: const Color(0xFF14B8A6),
        onCreateTemplate: (type) => selectedTemplate = type,
        onOpenPanel: (item) => selectedPanel = item,
      ),
    );

    await tester.tap(find.byTooltip('Create Executive Cover slide'));
    await _scrollToolbarTo(tester, find.byTooltip('Open Layers panel'));
    await tester.tap(find.byTooltip('Open Layers panel'));
    await tester.pumpAndSettle();

    expect(selectedTemplate, SlideTemplateType.executiveCover);
    expect(selectedPanel, SidebarMenuItem.layers);

    await _pumpToolbarContent(
      tester,
      ToolbarViewRibbonContent(
        showRuler: true,
        showGrid: false,
        snapToGrid: false,
        gridPreset: CanvasGridPreset.comfortable,
        showSpeakerNotes: true,
        showSlideNavigator: true,
        showInspector: true,
        onToggleRuler: () {},
        onToggleGrid: () => toggledGrid = true,
        onToggleSnapToGrid: () => toggledSnap = true,
        onGridPresetSelected: (preset) => selectedGridPreset = preset,
        onToggleSpeakerNotes: () {},
        onToggleSlideNavigator: () {},
        onToggleInspector: () => toggledInspector = true,
        onOpenSlideSorter: () => openedSlideSorter = true,
      ),
    );

    await tester.tap(find.byTooltip('Toggle Grid'));
    await tester.tap(find.byTooltip('Toggle Snap to Grid'));
    await tester.tap(find.byTooltip('Grid spacing').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Compact'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Toggle Inspector'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Open Slide Sorter'));
    await tester.pumpAndSettle();

    expect(toggledGrid, isTrue);
    expect(toggledSnap, isTrue);
    expect(selectedGridPreset, CanvasGridPreset.compact);
    expect(toggledInspector, isTrue);
    expect(openedSlideSorter, isTrue);
  });

  testWidgets('toolbar format ribbon content dispatches object commands', (
    tester,
  ) async {
    var toggledVisibility = false;
    var toggledLock = false;
    var openedInspector = false;
    Color? fillColor;
    Color? borderColor;
    double? borderWidth;
    double? opacity;
    final glowEnabledValues = <bool>[];
    Color? glowColor;
    var clearedFill = false;
    var clearedBorder = false;
    Color? textColor;
    Color? textHighlightColor;
    var clearedTextHighlight = false;
    String? fontFamily;
    double? fontSize;
    double? lineHeight;
    double? letterSpacing;
    bool? isBold;
    bool? isItalic;
    bool? isUnderline;
    bool? isStrikethrough;
    TextAlign? alignment;
    TextParagraphListStyle? listStyle;
    TextIndentDirection? indentDirection;
    TextCaseTransform? caseTransform;
    ObjectStylePreset? objectStylePreset;
    TextStylePreset? textStylePreset;

    await _pumpToolbarContent(
      tester,
      ToolbarFormatRibbonContent(
        component: PresentationComponent(
          id: 'object',
          type: ComponentType.shape,
          position: const Offset(40, 40),
          size: const Size(180, 90),
          backgroundColor: const Color(0xFF2563EB),
          border: const BorderSide(color: Color(0xFF14B8A6), width: 2),
          rotation: 15,
          opacity: 0.75,
          hasGlow: true,
          glowColor: const Color(0xFF14B8A6),
          richText: RichTextContent(
            text: 'Quarterly update',
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Inter',
              fontSize: 24,
              height: 1.15,
              letterSpacing: 0.5,
              backgroundColor: Color(0xFFFFF3BF),
            ),
          ),
        ),
        palette: const [Color(0xFF2563EB), Color(0xFF14B8A6)],
        accentColor: const Color(0xFF38BDF8),
        selectedObjectStylePreset: ObjectStylePreset.soft,
        onArrangeSelected: (_) {},
        onDeleteSelected: () {},
        onToggleVisibility: () => toggledVisibility = true,
        onToggleLocked: () => toggledLock = true,
        onOpenInspector: () => openedInspector = true,
        onFillColorSelected: (color) => fillColor = color,
        onFillCleared: () => clearedFill = true,
        onBorderColorSelected: (color) => borderColor = color,
        onBorderCleared: () => clearedBorder = true,
        onBorderWidthSelected: (width) => borderWidth = width,
        onOpacitySelected: (value) => opacity = value,
        onGlowEnabledChanged: glowEnabledValues.add,
        onGlowColorSelected: (color) => glowColor = color,
        onObjectStylePresetSelected: (value) => objectStylePreset = value,
        onTextColorSelected: (color) => textColor = color,
        onTextHighlightSelected: (color) => textHighlightColor = color,
        onTextHighlightCleared: () => clearedTextHighlight = true,
        onTextStylePresetSelected: (value) => textStylePreset = value,
        onFontFamilySelected: (value) => fontFamily = value,
        onFontSizeSelected: (value) => fontSize = value,
        onLineHeightSelected: (value) => lineHeight = value,
        onLetterSpacingSelected: (value) => letterSpacing = value,
        onBoldChanged: (value) => isBold = value,
        onItalicChanged: (value) => isItalic = value,
        onUnderlineChanged: (value) => isUnderline = value,
        onStrikethroughChanged: (value) => isStrikethrough = value,
        onAlignmentSelected: (value) => alignment = value,
        onParagraphListStyleSelected: (value) => listStyle = value,
        onTextIndentChanged: (value) => indentDirection = value,
        onTextCaseSelected: (value) => caseTransform = value,
      ),
    );

    expect(find.byTooltip('Selected object format summary'), findsOneWidget);
    expect(find.text('180 x 90'), findsOneWidget);
    expect(find.text('15 deg'), findsOneWidget);
    expect(find.text('75%'), findsOneWidget);

    await tester.tap(find.byTooltip('Hide Object'));
    await tester.tap(find.byTooltip('Lock Object'));
    await tester.tap(find.byTooltip('Open Inspector'));
    await tester.pumpAndSettle();

    await _tapToolbarTooltip(tester, 'Fill Color');
    await tester.tap(find.text('Fill #14B8A6'));
    await tester.pumpAndSettle();

    await _tapToolbarTooltip(tester, 'Fill Color');
    await tester.tap(find.text('No Fill'));
    await tester.pumpAndSettle();

    await _tapToolbarTooltip(tester, 'Stroke Color');
    await tester.tap(find.text('Stroke #2563EB'));
    await tester.pumpAndSettle();

    await _tapToolbarTooltip(tester, 'Stroke Color');
    await tester.tap(find.text('No Outline'));
    await tester.pumpAndSettle();

    await _tapToolbarTooltip(tester, 'Border Width');
    await tester.tap(find.text('4 px'));
    await tester.pumpAndSettle();

    await _tapToolbarTooltip(tester, 'Opacity');
    await tester.tap(find.text('50%'));
    await tester.pumpAndSettle();

    await _tapToolbarTooltip(tester, 'Effects');
    await tester.tap(find.text('Glow On'));
    await tester.pumpAndSettle();

    await _tapToolbarTooltip(tester, 'Effects');
    await tester.tap(find.text('Glow #14B8A6'));
    await tester.pumpAndSettle();

    await _tapToolbarTooltip(tester, 'Effects');
    await tester.tap(find.text('No Glow'));
    await tester.pumpAndSettle();

    await _tapToolbarTooltip(tester, 'Object Presets');
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    await tester.tap(find.text('Soft'));
    await tester.pumpAndSettle();

    await _tapToolbarTooltip(tester, 'Text Color');
    await tester.tap(find.text('Text #14B8A6'));
    await tester.pumpAndSettle();

    await _tapToolbarTooltip(tester, 'Text Highlight');
    await tester.tap(find.text('Highlight #BBF7D0'));
    await tester.pumpAndSettle();

    await _tapToolbarTooltip(tester, 'Text Highlight');
    await tester.tap(find.text('No Highlight'));
    await tester.pumpAndSettle();

    await _tapToolbarTooltip(tester, 'Text Presets');
    await tester.tap(find.text('Quote'));
    await tester.pumpAndSettle();

    await _tapToolbarTooltip(tester, 'Font Family');
    await tester.tap(find.text('Poppins'));
    await tester.pumpAndSettle();

    await _tapToolbarTooltip(tester, 'Text Size');
    await tester.tap(find.text('44'));
    await tester.pumpAndSettle();

    await _tapToolbarTooltip(tester, 'Line Spacing');
    await tester.tap(find.text('1.5x'));
    await tester.pumpAndSettle();

    await _tapToolbarTooltip(tester, 'Character Spacing');
    await tester.tap(find.text('1.5 pt'));
    await tester.pumpAndSettle();

    await _tapToolbarTooltip(tester, 'Bold');
    await _tapToolbarTooltip(tester, 'Italic');
    await _tapToolbarTooltip(tester, 'Underline');
    await _tapToolbarTooltip(tester, 'Strikethrough');

    await _tapToolbarTooltip(tester, 'Text Alignment');
    await tester.tap(find.text('Justify'));
    await tester.pumpAndSettle();

    await _tapToolbarTooltip(tester, 'Bulleted List');

    await _tapToolbarTooltip(tester, 'Increase Indent');

    await _tapToolbarTooltip(tester, 'Change Case');
    await tester.tap(find.text('Title Case'));
    await tester.pumpAndSettle();

    expect(toggledVisibility, isTrue);
    expect(toggledLock, isTrue);
    expect(openedInspector, isTrue);
    expect(fillColor, const Color(0xFF14B8A6));
    expect(clearedFill, isTrue);
    expect(borderColor, const Color(0xFF2563EB));
    expect(clearedBorder, isTrue);
    expect(borderWidth, 4);
    expect(opacity, 0.5);
    expect(glowEnabledValues, [true, false]);
    expect(glowColor, const Color(0xFF14B8A6));
    expect(objectStylePreset, ObjectStylePreset.soft);
    expect(textColor, const Color(0xFF14B8A6));
    expect(textHighlightColor, const Color(0xFFBBF7D0));
    expect(clearedTextHighlight, isTrue);
    expect(textStylePreset, TextStylePreset.quote);
    expect(fontFamily, 'Poppins');
    expect(fontSize, 44);
    expect(lineHeight, 1.5);
    expect(letterSpacing, 1.5);
    expect(isBold, isTrue);
    expect(isItalic, isTrue);
    expect(isUnderline, isTrue);
    expect(isStrikethrough, isTrue);
    expect(alignment, TextAlign.justify);
    expect(listStyle, TextParagraphListStyle.bullet);
    expect(indentDirection, TextIndentDirection.increase);
    expect(caseTransform, TextCaseTransform.title);
  });

  testWidgets('modern toolbar changes tools and view toggles', (tester) async {
    final container = _container();
    addTearDown(container.dispose);

    await _pumpToolbar(tester, container);

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Insert'), findsOneWidget);
    expect(find.text('Design'), findsOneWidget);
    expect(find.text('View'), findsOneWidget);
    expect(find.text('Format'), findsNothing);
    expect(find.byTooltip('Select'), findsOneWidget);
    expect(find.byTooltip('Text'), findsOneWidget);

    await tester.tap(find.byTooltip('Text'));
    await tester.pumpAndSettle();

    expect(container.read(currentToolProvider), ToolMode.text);

    await tester.tap(find.text('View'));
    await tester.pumpAndSettle();

    expect(container.read(activeRibbonTabProvider), EditorRibbonTab.view);

    await tester.tap(find.byTooltip('Toggle Grid'));
    await tester.pumpAndSettle();

    expect(container.read(showGridProvider), isTrue);

    await tester.tap(find.byTooltip('Toggle Snap to Grid'));
    await tester.pumpAndSettle();

    expect(container.read(snapToGridProvider), isTrue);

    await tester.tap(find.byTooltip('Grid spacing').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Compact'));
    await tester.pumpAndSettle();

    expect(container.read(canvasGridPresetProvider), CanvasGridPreset.compact);

    await tester.tap(find.byTooltip('Toggle Ruler'));
    await tester.pumpAndSettle();

    expect(container.read(rulerVisibilityProvider), isFalse);

    await tester.tap(find.byTooltip('Toggle Speaker Notes'));
    await tester.pumpAndSettle();

    expect(container.read(speakerNotesVisibleProvider), isFalse);

    await tester.tap(find.byTooltip('Toggle Slide Navigator'));
    await tester.pumpAndSettle();

    expect(container.read(slideNavigatorVisibleProvider), isFalse);

    await tester.tap(find.byTooltip('Toggle Inspector'));
    await tester.pumpAndSettle();

    expect(container.read(propertiesPanelVisibleProvider), isFalse);

    await tester.tap(find.byTooltip('Open Slide Sorter'));
    await tester.pumpAndSettle();

    expect(container.read(slideSorterVisibleProvider), isTrue);
  });

  testWidgets('modern toolbar exposes format tab for selected objects', (
    tester,
  ) async {
    final container = _container();
    addTearDown(container.dispose);
    container.read(selectedComponentProvider.notifier).state = 'title';
    container.read(propertiesPanelVisibleProvider.notifier).state = false;

    await _pumpToolbar(tester, container);

    expect(find.text('Format'), findsOneWidget);

    await tester.tap(find.text('Format'));
    await tester.pumpAndSettle();

    expect(container.read(activeRibbonTabProvider), EditorRibbonTab.format);
    expect(find.byType(ToolbarFormatRibbonContent), findsOneWidget);

    await _tapToolbarTooltip(tester, 'Fill Color');
    await tester.tap(find.text('Fill #14B8A6'));
    await tester.pumpAndSettle();

    var component = _components(container).single;
    expect(component.backgroundColor, const Color(0xFF14B8A6));
    expect(container.read(historyProvider).undoLabel, 'Update layer fill');

    await _tapToolbarTooltip(tester, 'Hide Object');

    component = _components(container).single;
    expect(component.isVisible, isFalse);
    expect(container.read(historyProvider).undoLabel, 'Hide layer');

    await _tapToolbarTooltip(tester, 'Text Color');
    await tester.tap(find.text('Text #2563EB'));
    await tester.pumpAndSettle();

    component = _components(container).single;
    expect(component.richText?.style.color, const Color(0xFF2563EB));
    expect(container.read(historyProvider).undoLabel, 'Update text style');

    await _tapToolbarTooltip(tester, 'Text Presets');
    await tester.tap(find.text('Quote'));
    await tester.pumpAndSettle();

    component = _components(container).single;
    expect(component.richText?.style.fontSize, 28);
    expect(component.richText?.style.fontStyle, FontStyle.italic);
    expect(component.richText?.isItalic, isTrue);
    expect(container.read(historyProvider).undoLabel, 'Apply text preset');

    await _tapToolbarTooltip(tester, 'Object Presets');
    await tester.tap(find.text('Signal'));
    await tester.pumpAndSettle();

    component = _components(container).single;
    expect(
      component.backgroundColor,
      const Color(0xFFF59E0B).withValues(alpha: 0.88),
    );
    expect(component.border?.width, 2);
    expect(component.hasGlow, isTrue);
    expect(container.read(historyProvider).undoLabel, 'Apply object preset');

    await _tapToolbarTooltip(tester, 'Object Presets');
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    await tester.tap(find.text('Signal'));
    await tester.pumpAndSettle();

    await _tapToolbarTooltip(tester, 'Effects');
    await tester.tap(find.text('No Glow'));
    await tester.pumpAndSettle();

    component = _components(container).single;
    expect(component.hasGlow, isFalse);
    expect(component.glowColor, isNull);
    expect(container.read(historyProvider).undoLabel, 'Update layer glow');

    await _tapToolbarTooltip(tester, 'Effects');
    await tester.tap(find.text('Glow #14B8A6'));
    await tester.pumpAndSettle();

    component = _components(container).single;
    expect(component.hasGlow, isTrue);
    expect(component.glowColor, const Color(0xFF14B8A6));
    expect(container.read(historyProvider).undoLabel, 'Update layer glow');

    await _tapToolbarTooltip(tester, 'Font Family');
    await tester.tap(find.text('Poppins'));
    await tester.pumpAndSettle();

    component = _components(container).single;
    expect(component.richText?.style.fontFamily, 'Poppins');
    expect(container.read(historyProvider).undoLabel, 'Update text style');

    await _tapToolbarTooltip(tester, 'Line Spacing');
    await tester.tap(find.text('1.5x'));
    await tester.pumpAndSettle();

    component = _components(container).single;
    expect(component.richText?.style.height, 1.5);
    expect(container.read(historyProvider).undoLabel, 'Update text style');

    await _tapToolbarTooltip(tester, 'Bold');

    component = _components(container).single;
    expect(component.richText?.isBold, isTrue);
    expect(container.read(historyProvider).undoLabel, 'Update text style');

    await _tapToolbarTooltip(tester, 'Bulleted List');

    component = _components(container).single;
    expect(component.richText?.text, '- Quarterly update');
    expect(container.read(historyProvider).undoLabel, 'Format paragraph');

    await _tapToolbarTooltip(tester, 'Increase Indent');

    component = _components(container).single;
    expect(component.richText?.text, '  - Quarterly update');
    expect(
      container.read(historyProvider).undoLabel,
      'Update paragraph indent',
    );

    await _tapToolbarTooltip(tester, 'Change Case');
    await tester.tap(find.text('UPPERCASE'));
    await tester.pumpAndSettle();

    component = _components(container).single;
    expect(component.richText?.text, '  - QUARTERLY UPDATE');
    expect(container.read(historyProvider).undoLabel, 'Change text case');

    await _tapToolbarTooltip(tester, 'Open Inspector');

    expect(container.read(propertiesPanelVisibleProvider), isTrue);
  });

  testWidgets('modern toolbar inserts shapes and charts', (tester) async {
    final container = _container();
    addTearDown(container.dispose);

    await _pumpToolbar(tester, container);

    await tester.tap(find.text('Insert'));
    await tester.pumpAndSettle();

    expect(find.byType(ToolbarInsertGroup), findsOneWidget);
    expect(find.byTooltip('Insert Image'), findsOneWidget);
    expect(find.byTooltip('Insert Video'), findsOneWidget);
    expect(find.byType(ToolbarChartGallery), findsOneWidget);
    expect(find.byType(ChartPreviewThumbnail), findsNWidgets(3));
    expect(find.byType(ToolbarShapeGallery), findsOneWidget);
    expect(find.byType(ShapePreviewThumbnail), findsNWidgets(3));
    expect(find.byType(ToolbarInteractiveGallery), findsOneWidget);
    expect(find.byType(InteractivePreviewThumbnail), findsNWidgets(4));

    await tester.tap(find.byTooltip('Insert Rectangle shape'));
    await tester.pumpAndSettle();

    var components = _components(container);
    expect(components.length, 2);
    expect(components.last.type, ComponentType.shape);
    expect(container.read(selectedComponentProvider), components.last.id);

    await tester.tap(find.byTooltip('Insert Bar Chart'));
    await tester.pumpAndSettle();

    components = _components(container);
    expect(components.length, 3);
    expect(components.last.type, ComponentType.chart);
    expect(components.last.chartData?.type, ChartType.bar);

    await _scrollToolbarTo(tester, find.byTooltip('Insert Poll interactive'));
    await tester.tap(find.byTooltip('Insert Poll interactive'));
    await tester.pumpAndSettle();

    components = _components(container);
    expect(components.length, 4);
    expect(components.last.type, ComponentType.hotspot);
    expect(components.last.interactive?.type, InteractiveType.poll);
    expect(components.last.interactive?.options, hasLength(3));
  });

  testWidgets('modern toolbar inserts images through the media picker', (
    tester,
  ) async {
    final imageBytes = Uint8List.fromList([9, 8, 7]);
    final container = _containerWithPicker(
      _FakeMediaPickerService(
        () async => PickedImageMedia(bytes: imageBytes, fileName: 'hero.png'),
      ),
    );
    addTearDown(container.dispose);

    await _pumpToolbar(tester, container);

    await tester.tap(find.text('Insert'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Insert Image'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    final components = _components(container);
    expect(components, hasLength(2));
    expect(components.last.type, ComponentType.image);
    expect(components.last.imageData, imageBytes);
    expect(container.read(selectedComponentProvider), components.last.id);
    expect(find.text('Inserted hero.png.'), findsOneWidget);
  });

  testWidgets('modern toolbar manages slides from the home ribbon', (
    tester,
  ) async {
    final container = _container();
    addTearDown(container.dispose);

    await _pumpToolbar(tester, container);

    await tester.tap(find.byTooltip('New Slide'));
    await tester.pumpAndSettle();

    expect(container.read(presentationProvider).slides.length, 2);
    expect(container.read(presentationProvider).currentSlideIndex, 1);
    expect(container.read(historyProvider).undoLabel, 'Add slide');

    await tester.tap(find.byTooltip('Duplicate Slide'));
    await tester.pumpAndSettle();

    expect(container.read(presentationProvider).slides.length, 3);
    expect(container.read(presentationProvider).currentSlideIndex, 2);
    expect(container.read(historyProvider).undoLabel, 'Duplicate slide');

    await tester.tap(find.byTooltip('Delete Slide'));
    await tester.pumpAndSettle();

    expect(container.read(presentationProvider).slides.length, 2);
    expect(container.read(historyProvider).undoLabel, 'Delete slide');
  });

  testWidgets('modern toolbar home tab creates layout slides from previews', (
    tester,
  ) async {
    final container = _container();
    addTearDown(container.dispose);

    await _pumpToolbar(tester, container);

    expect(find.byType(ToolbarLayoutGallery), findsOneWidget);
    expect(
      find.byType(SlideLayoutPreviewThumbnail),
      findsNWidgets(SlideLayoutType.values.length),
    );

    await tester.tap(find.byTooltip('Create Two Columns layout slide'));
    await tester.pumpAndSettle();

    final presentation = container.read(presentationProvider);
    expect(presentation.slides.length, 2);
    expect(presentation.currentSlideIndex, 1);
    expect(presentation.slides.last.title, 'Two Columns');
    expect(container.read(historyProvider).undoLabel, 'Add layout slide');
  });

  testWidgets('modern toolbar deletes selected component with history', (
    tester,
  ) async {
    final container = _container();
    addTearDown(container.dispose);
    container.read(selectedComponentProvider.notifier).state = 'title';

    await _pumpToolbar(tester, container);

    await _scrollToolbarTo(tester, find.byTooltip('Delete (Del)'));
    await tester.tap(find.byTooltip('Delete (Del)'));
    await tester.pumpAndSettle();

    expect(_components(container), isEmpty);
    expect(container.read(selectedComponentProvider), isNull);
    expect(container.read(historyProvider).undoLabel, 'Delete layer');
  });

  testWidgets('modern toolbar arranges selected component from menu', (
    tester,
  ) async {
    final container = _container();
    addTearDown(container.dispose);
    container.read(selectedComponentProvider.notifier).state = 'title';

    await _pumpToolbar(tester, container);

    await _scrollToolbarTo(tester, find.byTooltip('Arrange selected'));
    await tester.tap(find.byTooltip('Arrange selected'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Center on slide'));
    await tester.pumpAndSettle();

    final component = _components(container).single;
    expect(component.position, isNot(const Offset(40, 40)));
    expect(container.read(historyProvider).undoLabel, 'Arrange layer');
  });

  testWidgets('modern toolbar design tab reaches sidebar panels', (
    tester,
  ) async {
    final container = _container();
    addTearDown(container.dispose);

    await _pumpToolbar(tester, container);

    await tester.tap(find.text('Design'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Open Design panel'));
    await tester.pumpAndSettle();

    expect(container.read(activeRibbonTabProvider), EditorRibbonTab.design);
    expect(container.read(activeSidebarMenuProvider), SidebarMenuItem.design);

    await tester.tap(find.byTooltip('Open Layers panel'));
    await tester.pumpAndSettle();

    expect(container.read(activeSidebarMenuProvider), SidebarMenuItem.layers);

    await tester.tap(find.byTooltip('Open Arrange panel'));
    await tester.pumpAndSettle();

    expect(container.read(activeSidebarMenuProvider), SidebarMenuItem.arrange);
  });

  testWidgets(
    'modern toolbar design tab creates template slides from previews',
    (tester) async {
      final container = _container();
      addTearDown(container.dispose);

      await _pumpToolbar(tester, container);

      await tester.tap(find.text('Design'));
      await tester.pumpAndSettle();

      expect(find.byType(ToolbarTemplateGallery), findsOneWidget);
      expect(
        find.byType(TemplatePreviewThumbnail),
        findsNWidgets(SlideTemplateType.values.length),
      );

      await tester.tap(find.byTooltip('Create Executive Cover slide'));
      await tester.pumpAndSettle();

      final presentation = container.read(presentationProvider);
      expect(presentation.slides.length, 2);
      expect(presentation.currentSlideIndex, 1);
      expect(presentation.slides.last.title, 'Executive Cover');
      expect(container.read(historyProvider).undoLabel, 'Add template slide');
    },
  );
}

Future<void> _pumpToolbarContent(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFF1E293B),
        body: SizedBox(width: 760, height: 88, child: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _scrollToolbarTo(WidgetTester tester, Finder finder) async {
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

Future<void> _tapToolbarTooltip(WidgetTester tester, String tooltip) async {
  final finder = find.byTooltip(tooltip);
  await _scrollToolbarTo(tester, finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _pumpToolbar(
  WidgetTester tester,
  ProviderContainer container,
) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(body: SizedBox(height: 132, child: ModernToolbar())),
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

ProviderContainer _containerWithPicker(MediaPickerService picker) {
  return ProviderContainer(
    overrides: [
      presentationProvider.overrideWith(
        (ref) => PresentationNotifier(initialPresentation: _presentation()),
      ),
      mediaPickerServiceProvider.overrideWithValue(picker),
    ],
  );
}

Presentation _presentation() {
  return Presentation(
    id: 'toolbar-test',
    title: 'Toolbar Test',
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
  );
}

List<PresentationComponent> _components(ProviderContainer container) {
  final presentation = container.read(presentationProvider);
  return presentation.slides[presentation.currentSlideIndex].components;
}

class _FakeMediaPickerService implements MediaPickerService {
  final Future<PickedImageMedia?> Function() pickImageCallback;

  const _FakeMediaPickerService(this.pickImageCallback);

  @override
  Future<PickedImageMedia?> pickImage() => pickImageCallback();
}
