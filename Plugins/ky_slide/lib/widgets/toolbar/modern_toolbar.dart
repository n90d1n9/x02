import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/canvas_grid_preset.dart';
import '../../models/editor_ribbon_tab.dart';
import '../../models/enums.dart';
import '../../models/object_style_preset.dart';
import '../../models/presentation.dart';
import '../../models/presentation_component.dart';
import '../../services/object_style_preset_service.dart';
import '../../states/component_insert_actions_provider.dart';
import '../../states/component_layer_actions_provider.dart';
import '../../states/component_property_actions_provider.dart';
import '../../states/component_provider.dart';
import '../../states/editor_view_provider.dart';
import '../../states/media_insert_actions_provider.dart';
import '../../states/presentation_provider.dart';
import '../../states/sidebar_panel_provider.dart';
import '../../states/slide_actions_provider.dart';
import 'ribbon_tab_bar.dart';
import 'toolbar_design_ribbon_content.dart';
import 'toolbar_format_ribbon_content.dart';
import 'toolbar_home_ribbon_content.dart';
import 'toolbar_insert_ribbon_content.dart';
import 'toolbar_view_ribbon_content.dart';
import 'video_url_dialog.dart';

/// Modern ribbon toolbar that adapts editor state into tab content widgets.
class ModernToolbar extends ConsumerWidget {
  static const ObjectStylePresetService _objectStylePresetService =
      ObjectStylePresetService();

  const ModernToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTool = ref.watch(currentToolProvider);
    final showRuler = ref.watch(rulerVisibilityProvider);
    final showGrid = ref.watch(showGridProvider);
    final snapToGrid = ref.watch(snapToGridProvider);
    final gridPreset = ref.watch(canvasGridPresetProvider);
    final showSpeakerNotes = ref.watch(speakerNotesVisibleProvider);
    final showSlideNavigator = ref.watch(slideNavigatorVisibleProvider);
    final showInspector = ref.watch(propertiesPanelVisibleProvider);
    final selectedId = ref.watch(selectedComponentProvider);
    final activeRibbonTab = ref.watch(activeRibbonTabProvider);
    final presentation = ref.watch(presentationProvider);
    final selectedComponent = _selectedComponent(presentation, selectedId);
    final availableTabs = EditorRibbonTabLabel.visibleTabs(
      hasSelection: selectedComponent != null,
    );
    final effectiveRibbonTab = availableTabs.contains(activeRibbonTab)
        ? activeRibbonTab
        : EditorRibbonTab.home;

    return Container(
      height: 112,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
      child: Column(
        children: [
          RibbonTabBar(
            activeTab: effectiveRibbonTab,
            tabs: availableTabs,
            onSelected: (tab) {
              ref.read(activeRibbonTabProvider.notifier).state = tab;
            },
          ),
          Expanded(
            child: _buildRibbonContent(
              context: context,
              ref: ref,
              activeTab: effectiveRibbonTab,
              currentTool: currentTool,
              showRuler: showRuler,
              showGrid: showGrid,
              snapToGrid: snapToGrid,
              gridPreset: gridPreset,
              showSpeakerNotes: showSpeakerNotes,
              showSlideNavigator: showSlideNavigator,
              showInspector: showInspector,
              canDeleteSlide: presentation.slides.length > 1,
              selectedComponent: selectedComponent,
              selectedObjectStylePreset: selectedComponent == null
                  ? null
                  : _objectStylePresetService.detectPreset(
                      component: selectedComponent,
                      theme: presentation.theme,
                    ),
              layoutAccentColor: presentation.theme.primaryColor,
              templatePalette: presentation.theme.colorPalette,
              templateSecondaryColor: presentation.theme.secondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRibbonContent({
    required BuildContext context,
    required WidgetRef ref,
    required EditorRibbonTab activeTab,
    required ToolMode currentTool,
    required bool showRuler,
    required bool showGrid,
    required bool snapToGrid,
    required CanvasGridPreset gridPreset,
    required bool showSpeakerNotes,
    required bool showSlideNavigator,
    required bool showInspector,
    required bool canDeleteSlide,
    required PresentationComponent? selectedComponent,
    required ObjectStylePreset? selectedObjectStylePreset,
    required Color layoutAccentColor,
    required List<Color> templatePalette,
    required Color templateSecondaryColor,
  }) {
    if (activeTab == EditorRibbonTab.format && selectedComponent != null) {
      return ToolbarFormatRibbonContent(
        component: selectedComponent,
        palette: templatePalette,
        accentColor: layoutAccentColor,
        selectedObjectStylePreset: selectedObjectStylePreset,
        onArrangeSelected: (action) {
          ref.read(componentLayerActionsProvider).arrangeSelectedLayer(action);
        },
        onDeleteSelected: () {
          ref.read(componentLayerActionsProvider).deleteSelectedLayer();
        },
        onToggleVisibility: () {
          ref
              .read(componentPropertyActionsProvider)
              .setSelectedVisibility(!selectedComponent.isVisible);
        },
        onToggleLocked: () {
          ref
              .read(componentPropertyActionsProvider)
              .setSelectedLocked(!selectedComponent.isLocked);
        },
        onOpenInspector: () {
          ref.read(propertiesPanelVisibleProvider.notifier).state = true;
        },
        onFillColorSelected: (color) {
          ref
              .read(componentPropertyActionsProvider)
              .updateSelectedFillColor(color);
        },
        onFillCleared: () {
          ref.read(componentPropertyActionsProvider).clearSelectedFillColor();
        },
        onBorderColorSelected: (color) {
          ref
              .read(componentPropertyActionsProvider)
              .updateSelectedBorder(color: color);
        },
        onBorderCleared: () {
          ref.read(componentPropertyActionsProvider).clearSelectedBorder();
        },
        onBorderWidthSelected: (width) {
          ref
              .read(componentPropertyActionsProvider)
              .updateSelectedBorder(width: width);
        },
        onOpacitySelected: (opacity) {
          ref
              .read(componentPropertyActionsProvider)
              .updateSelectedOpacity(opacity);
        },
        onGlowEnabledChanged: (enabled) {
          ref
              .read(componentPropertyActionsProvider)
              .updateSelectedGlow(enabled: enabled);
        },
        onGlowColorSelected: (color) {
          ref
              .read(componentPropertyActionsProvider)
              .updateSelectedGlow(color: color);
        },
        onObjectStylePresetSelected: (preset) {
          ref
              .read(componentPropertyActionsProvider)
              .applySelectedObjectStylePreset(preset);
        },
        onTextColorSelected: (color) {
          ref
              .read(componentPropertyActionsProvider)
              .updateSelectedTextStyle(color: color);
        },
        onTextHighlightSelected: (color) {
          ref
              .read(componentPropertyActionsProvider)
              .updateSelectedTextStyle(highlightColor: color);
        },
        onTextHighlightCleared: () {
          ref
              .read(componentPropertyActionsProvider)
              .updateSelectedTextStyle(clearHighlight: true);
        },
        onTextStylePresetSelected: (preset) {
          ref
              .read(componentPropertyActionsProvider)
              .applySelectedTextStylePreset(preset);
        },
        onFontFamilySelected: (fontFamily) {
          ref
              .read(componentPropertyActionsProvider)
              .updateSelectedTextStyle(fontFamily: fontFamily);
        },
        onFontSizeSelected: (fontSize) {
          ref
              .read(componentPropertyActionsProvider)
              .updateSelectedTextStyle(fontSize: fontSize);
        },
        onLineHeightSelected: (lineHeight) {
          ref
              .read(componentPropertyActionsProvider)
              .updateSelectedTextStyle(lineHeight: lineHeight);
        },
        onLetterSpacingSelected: (letterSpacing) {
          ref
              .read(componentPropertyActionsProvider)
              .updateSelectedTextStyle(letterSpacing: letterSpacing);
        },
        onBoldChanged: (isBold) {
          ref
              .read(componentPropertyActionsProvider)
              .updateSelectedTextStyle(isBold: isBold);
        },
        onItalicChanged: (isItalic) {
          ref
              .read(componentPropertyActionsProvider)
              .updateSelectedTextStyle(isItalic: isItalic);
        },
        onUnderlineChanged: (isUnderline) {
          ref
              .read(componentPropertyActionsProvider)
              .updateSelectedTextStyle(isUnderline: isUnderline);
        },
        onStrikethroughChanged: (isStrikethrough) {
          ref
              .read(componentPropertyActionsProvider)
              .updateSelectedTextStyle(isStrikethrough: isStrikethrough);
        },
        onAlignmentSelected: (alignment) {
          ref
              .read(componentPropertyActionsProvider)
              .updateSelectedTextStyle(alignment: alignment);
        },
        onParagraphListStyleSelected: (style) {
          ref
              .read(componentPropertyActionsProvider)
              .applySelectedParagraphListStyle(style);
        },
        onTextIndentChanged: (direction) {
          ref
              .read(componentPropertyActionsProvider)
              .adjustSelectedTextIndent(direction);
        },
        onTextCaseSelected: (transform) {
          ref
              .read(componentPropertyActionsProvider)
              .applySelectedTextCase(transform);
        },
      );
    }

    return switch (activeTab) {
      EditorRibbonTab.home => _buildHomeRibbonContent(
        ref: ref,
        currentTool: currentTool,
        canDeleteSlide: canDeleteSlide,
        hasSelection: selectedComponent != null,
        layoutAccentColor: layoutAccentColor,
      ),
      EditorRibbonTab.insert => ToolbarInsertRibbonContent(
        palette: templatePalette,
        accentColor: layoutAccentColor,
        secondaryColor: templateSecondaryColor,
        onImage: () => _addImage(ref, context),
        onVideo: () => _addVideo(ref, context),
        onCreateChart: (type) {
          ref.read(componentInsertActionsProvider).addChart(type);
        },
        onCreateShape: (type) {
          ref.read(componentInsertActionsProvider).addShape(type);
        },
        onCreateInteractive: (type) {
          ref.read(componentInsertActionsProvider).addInteractive(type);
        },
      ),
      EditorRibbonTab.design => ToolbarDesignRibbonContent(
        palette: templatePalette,
        secondaryColor: templateSecondaryColor,
        onCreateTemplate: (type) {
          ref.read(slideActionsProvider).addTemplateSlide(type);
        },
        onOpenPanel: (item) {
          ref.read(activeSidebarMenuProvider.notifier).state = item;
        },
      ),
      EditorRibbonTab.view => ToolbarViewRibbonContent(
        showRuler: showRuler,
        showGrid: showGrid,
        snapToGrid: snapToGrid,
        gridPreset: gridPreset,
        showSpeakerNotes: showSpeakerNotes,
        showSlideNavigator: showSlideNavigator,
        showInspector: showInspector,
        onToggleRuler: () {
          ref.read(rulerVisibilityProvider.notifier).state = !showRuler;
        },
        onToggleGrid: () {
          ref.read(showGridProvider.notifier).state = !showGrid;
        },
        onToggleSnapToGrid: () {
          ref.read(snapToGridProvider.notifier).state = !snapToGrid;
        },
        onGridPresetSelected: (preset) {
          ref.read(canvasGridPresetProvider.notifier).state = preset;
        },
        onToggleSpeakerNotes: () {
          ref.read(speakerNotesVisibleProvider.notifier).state =
              !showSpeakerNotes;
        },
        onToggleSlideNavigator: () {
          ref.read(slideNavigatorVisibleProvider.notifier).state =
              !showSlideNavigator;
        },
        onToggleInspector: () {
          ref.read(propertiesPanelVisibleProvider.notifier).state =
              !showInspector;
        },
        onOpenSlideSorter: () {
          ref.read(slideSorterVisibleProvider.notifier).state = true;
        },
      ),
      EditorRibbonTab.format => _buildHomeRibbonContent(
        ref: ref,
        currentTool: currentTool,
        canDeleteSlide: canDeleteSlide,
        hasSelection: selectedComponent != null,
        layoutAccentColor: layoutAccentColor,
      ),
    };
  }

  Widget _buildHomeRibbonContent({
    required WidgetRef ref,
    required ToolMode currentTool,
    required bool canDeleteSlide,
    required bool hasSelection,
    required Color layoutAccentColor,
  }) {
    return ToolbarHomeRibbonContent(
      currentTool: currentTool,
      canDeleteSlide: canDeleteSlide,
      hasSelection: hasSelection,
      layoutAccentColor: layoutAccentColor,
      onAddSlide: () {
        ref.read(slideActionsProvider).addSlide();
      },
      onDuplicateSlide: () {
        ref.read(slideActionsProvider).duplicateSlide();
      },
      onDeleteSlide: () {
        ref.read(slideActionsProvider).deleteSlide();
      },
      onCreateLayout: (type) {
        ref.read(slideActionsProvider).addLayoutSlide(type);
      },
      onSelectTool: () {
        ref.read(currentToolProvider.notifier).state = ToolMode.select;
      },
      onTextTool: () {
        ref.read(currentToolProvider.notifier).state = ToolMode.text;
      },
      onArrangeSelected: (action) {
        ref.read(componentLayerActionsProvider).arrangeSelectedLayer(action);
      },
      onDeleteSelected: () {
        ref.read(componentLayerActionsProvider).deleteSelectedLayer();
      },
    );
  }

  PresentationComponent? _selectedComponent(
    Presentation presentation,
    String? selectedId,
  ) {
    if (selectedId == null || presentation.slides.isEmpty) return null;

    final currentSlideIndex = presentation.currentSlideIndex
        .clamp(0, presentation.slides.length - 1)
        .toInt();
    final currentSlide = presentation.slides[currentSlideIndex];

    for (final component in currentSlide.components) {
      if (component.id == selectedId) return component;
    }

    return null;
  }

  Future<void> _addImage(WidgetRef ref, BuildContext context) async {
    final result = await ref
        .read(mediaInsertActionsProvider)
        .addImageFromPicker();
    if (!context.mounted || result.status == MediaInsertStatus.cancelled) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message ?? 'Image insert completed.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: result.status == MediaInsertStatus.failed
            ? const Color(0xFF991B1B)
            : null,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _addVideo(WidgetRef ref, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => VideoUrlDialog(
        onSubmitted: (url) {
          ref.read(componentInsertActionsProvider).addVideo(url);
        },
      ),
    );
  }
}
