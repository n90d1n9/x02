import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../models/component.dart';
import '../../models/component_arrange_action.dart';
import '../../models/object_style_preset.dart';
import '../../models/presentation_component.dart';
import '../../models/rich_text_content.dart';
import '../../models/text_paragraph_format.dart';
import '../../models/text_style_preset.dart';
import 'ribbon_command_group.dart';
import 'toolbar_object_effects_menu.dart';
import 'toolbar_object_preset_menu.dart';
import 'toolbar_object_state_group.dart';
import 'toolbar_object_style_group.dart';
import 'toolbar_paragraph_format_group.dart';
import 'toolbar_format_summary.dart';
import 'toolbar_responsive_layout.dart';
import 'toolbar_selection_actions_group.dart';
import 'toolbar_text_format_group.dart';
import 'toolbar_text_preset_menu.dart';

/// Contextual ribbon tab for styling and arranging the selected object.
class ToolbarFormatRibbonContent extends StatelessWidget {
  final PresentationComponent component;
  final List<Color> palette;
  final Color accentColor;
  final ObjectStylePreset? selectedObjectStylePreset;
  final ValueChanged<ComponentArrangeAction> onArrangeSelected;
  final VoidCallback onDeleteSelected;
  final VoidCallback onToggleVisibility;
  final VoidCallback onToggleLocked;
  final VoidCallback onOpenInspector;
  final ValueChanged<Color> onFillColorSelected;
  final VoidCallback onFillCleared;
  final ValueChanged<Color> onBorderColorSelected;
  final VoidCallback onBorderCleared;
  final ValueChanged<double> onBorderWidthSelected;
  final ValueChanged<double> onOpacitySelected;
  final ValueChanged<bool> onGlowEnabledChanged;
  final ValueChanged<Color> onGlowColorSelected;
  final ValueChanged<ObjectStylePreset> onObjectStylePresetSelected;
  final ValueChanged<Color> onTextColorSelected;
  final ValueChanged<Color> onTextHighlightSelected;
  final VoidCallback onTextHighlightCleared;
  final ValueChanged<TextStylePreset> onTextStylePresetSelected;
  final ValueChanged<String> onFontFamilySelected;
  final ValueChanged<double> onFontSizeSelected;
  final ValueChanged<double> onLineHeightSelected;
  final ValueChanged<double> onLetterSpacingSelected;
  final ValueChanged<bool> onBoldChanged;
  final ValueChanged<bool> onItalicChanged;
  final ValueChanged<bool> onUnderlineChanged;
  final ValueChanged<bool> onStrikethroughChanged;
  final ValueChanged<TextAlign> onAlignmentSelected;
  final ValueChanged<TextParagraphListStyle> onParagraphListStyleSelected;
  final ValueChanged<TextIndentDirection> onTextIndentChanged;
  final ValueChanged<TextCaseTransform> onTextCaseSelected;

  const ToolbarFormatRibbonContent({
    super.key,
    required this.component,
    required this.palette,
    required this.accentColor,
    this.selectedObjectStylePreset,
    required this.onArrangeSelected,
    required this.onDeleteSelected,
    required this.onToggleVisibility,
    required this.onToggleLocked,
    required this.onOpenInspector,
    required this.onFillColorSelected,
    required this.onFillCleared,
    required this.onBorderColorSelected,
    required this.onBorderCleared,
    required this.onBorderWidthSelected,
    required this.onOpacitySelected,
    required this.onGlowEnabledChanged,
    required this.onGlowColorSelected,
    required this.onObjectStylePresetSelected,
    required this.onTextColorSelected,
    required this.onTextHighlightSelected,
    required this.onTextHighlightCleared,
    required this.onTextStylePresetSelected,
    required this.onFontFamilySelected,
    required this.onFontSizeSelected,
    required this.onLineHeightSelected,
    required this.onLetterSpacingSelected,
    required this.onBoldChanged,
    required this.onItalicChanged,
    required this.onUnderlineChanged,
    required this.onStrikethroughChanged,
    required this.onAlignmentSelected,
    required this.onParagraphListStyleSelected,
    required this.onTextIndentChanged,
    required this.onTextCaseSelected,
  });

  @override
  Widget build(BuildContext context) {
    final richText = component.richText;
    final secondaryColor = palette.length > 1 ? palette[1] : accentColor;

    return ToolbarResponsiveLayout(
      leadingGroup: (context, compact) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RibbonCommandGroup(
            label: _componentTypeLabel(component.type),
            child: ToolbarObjectStateGroup(
              compact: true,
              accentColor: accentColor,
              isVisible: component.isVisible,
              isLocked: component.isLocked,
              onToggleVisibility: onToggleVisibility,
              onToggleLocked: onToggleLocked,
              onOpenInspector: onOpenInspector,
            ),
          ),
          RibbonCommandGroup(
            label: 'Look',
            child: ToolbarObjectPresetMenu(
              compact: true,
              enabled: !component.isLocked,
              accentColor: accentColor,
              secondaryColor: secondaryColor,
              selectedPreset: selectedObjectStylePreset,
              onSelected: onObjectStylePresetSelected,
            ),
          ),
          if (richText != null)
            RibbonCommandGroup(
              label: 'Preset',
              child: ToolbarTextPresetMenu(
                compact: true,
                enabled: !component.isLocked,
                onSelected: onTextStylePresetSelected,
              ),
            ),
          if (richText != null)
            RibbonCommandGroup(
              label: 'Text',
              child: ToolbarTextFormatGroup(
                compact: true,
                enabled: !component.isLocked,
                accentColor: accentColor,
                richText: richText,
                colors: palette,
                onTextColorSelected: onTextColorSelected,
                onTextHighlightSelected: onTextHighlightSelected,
                onTextHighlightCleared: onTextHighlightCleared,
                onFontFamilySelected: onFontFamilySelected,
                onFontSizeSelected: onFontSizeSelected,
                onLineHeightSelected: onLineHeightSelected,
                onLetterSpacingSelected: onLetterSpacingSelected,
                onBoldChanged: onBoldChanged,
                onItalicChanged: onItalicChanged,
                onUnderlineChanged: onUnderlineChanged,
                onStrikethroughChanged: onStrikethroughChanged,
                onAlignmentSelected: onAlignmentSelected,
              ),
            ),
          if (richText != null)
            RibbonCommandGroup(
              label: 'Paragraph',
              child: ToolbarParagraphFormatGroup(
                compact: true,
                enabled: !component.isLocked,
                accentColor: accentColor,
                richText: richText,
                onListStyleSelected: onParagraphListStyleSelected,
                onIndentChanged: onTextIndentChanged,
                onTextCaseSelected: onTextCaseSelected,
              ),
            ),
          RibbonCommandGroup(
            label: 'Style',
            child: ToolbarObjectStyleGroup(
              compact: true,
              enabled: !component.isLocked,
              colors: palette,
              selectedFillColor: component.backgroundColor,
              selectedBorderColor: component.border?.color,
              selectedBorderWidth: component.border?.width ?? 0,
              selectedOpacity: component.opacity,
              onFillColorSelected: onFillColorSelected,
              onFillCleared: onFillCleared,
              onBorderColorSelected: onBorderColorSelected,
              onBorderCleared: onBorderCleared,
              onBorderWidthSelected: onBorderWidthSelected,
              onOpacitySelected: onOpacitySelected,
            ),
          ),
          RibbonCommandGroup(
            label: 'Effects',
            child: ToolbarObjectEffectsMenu(
              compact: true,
              enabled: !component.isLocked,
              hasGlow: component.hasGlow,
              selectedGlowColor: component.glowColor,
              colors: palette,
              onGlowEnabledChanged: onGlowEnabledChanged,
              onGlowColorSelected: onGlowColorSelected,
            ),
          ),
          RibbonCommandGroup(
            label: 'Arrange',
            child: ToolbarSelectionActionsGroup(
              compact: true,
              hasSelection: true,
              onArrangeSelected: onArrangeSelected,
              onDeleteSelected: onDeleteSelected,
            ),
          ),
        ],
      ),
      trailingGroups: (context, compact) => [
        RibbonCommandGroup(
          label: 'Summary',
          child: ToolbarFormatSummary(
            component: component,
            accentColor: accentColor,
            compact: compact,
          ),
        ),
      ],
    );
  }

  String _componentTypeLabel(ComponentType type) {
    return switch (type) {
      ComponentType.richText => 'Text',
      ComponentType.image => 'Image',
      ComponentType.chart => 'Chart',
      ComponentType.video => 'Video',
      ComponentType.audio => 'Audio',
      ComponentType.hotspot ||
      ComponentType.poll ||
      ComponentType.quiz ||
      ComponentType.countdown ||
      ComponentType.progressBar => 'Interactive',
      ComponentType.shape ||
      ComponentType.circle ||
      ComponentType.triangle => 'Shape',
      _ => 'Object',
    };
  }
}

@Preview(name: 'Toolbar format ribbon content', size: Size(760, 88))
Widget toolbarFormatRibbonContentPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      body: Center(
        child: SizedBox(
          height: 78,
          child: ToolbarFormatRibbonContent(
            component: PresentationComponent(
              id: 'preview-object',
              type: ComponentType.richText,
              position: const Offset(40, 40),
              size: const Size(220, 120),
              backgroundColor: const Color(0xFF38BDF8),
              border: const BorderSide(color: Color(0xFF14B8A6), width: 2),
              richText: RichTextContent(
                text: 'Quarterly update',
                style: const TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontFamily: 'Inter',
                  fontSize: 24,
                  height: 1.3,
                  letterSpacing: 0.5,
                  backgroundColor: Color(0xFFFFF3BF),
                ),
                isBold: true,
                isStrikethrough: true,
                alignment: TextAlign.center,
              ),
            ),
            palette: const [Color(0xFF38BDF8), Color(0xFF14B8A6)],
            accentColor: const Color(0xFF38BDF8),
            selectedObjectStylePreset: ObjectStylePreset.filled,
            onArrangeSelected: (_) {},
            onDeleteSelected: () {},
            onToggleVisibility: () {},
            onToggleLocked: () {},
            onOpenInspector: () {},
            onFillColorSelected: (_) {},
            onFillCleared: () {},
            onBorderColorSelected: (_) {},
            onBorderCleared: () {},
            onBorderWidthSelected: (_) {},
            onOpacitySelected: (_) {},
            onGlowEnabledChanged: (_) {},
            onGlowColorSelected: (_) {},
            onObjectStylePresetSelected: (_) {},
            onTextColorSelected: (_) {},
            onTextHighlightSelected: (_) {},
            onTextHighlightCleared: () {},
            onTextStylePresetSelected: (_) {},
            onFontFamilySelected: (_) {},
            onFontSizeSelected: (_) {},
            onLineHeightSelected: (_) {},
            onLetterSpacingSelected: (_) {},
            onBoldChanged: (_) {},
            onItalicChanged: (_) {},
            onUnderlineChanged: (_) {},
            onStrikethroughChanged: (_) {},
            onAlignmentSelected: (_) {},
            onParagraphListStyleSelected: (_) {},
            onTextIndentChanged: (_) {},
            onTextCaseSelected: (_) {},
          ),
        ),
      ),
    ),
  );
}
