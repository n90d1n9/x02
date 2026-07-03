import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widget_previews.dart';

import '../../models/component.dart';
import '../../models/presentation_component.dart';
import '../../models/selection_quick_format_action.dart';
import '../../models/text_paragraph_format.dart';
import '../../services/object_style_preset_service.dart';
import '../../services/selection_identity_service.dart';
import '../../services/text_paragraph_formatting_service.dart';
import '../../services/text_style_preset_service.dart';
import '../../states/component_layer_actions_provider.dart';
import '../../states/component_property_actions_provider.dart';
import '../../states/editor_view_provider.dart';
import '../../states/presentation_provider.dart';
import 'selection_context_arrange_menu.dart';
import 'selection_context_action_bar.dart';
import 'selection_identity_chip.dart';
import 'selection_quick_format_menu.dart';

/// Provider-backed floating toolbar anchored near the selected slide object.
class SlideSelectionContextToolbar extends ConsumerWidget {
  static const double _identityGap = 8;
  static const double _visualWidth =
      SelectionIdentityChip.visualWidth +
      _identityGap +
      SelectionContextActionBar.visualWidth;
  static const double _visualHeight = SelectionContextActionBar.visualHeight;
  static const double _visualGap = 10;
  static const ObjectStylePresetService _objectStylePresetService =
      ObjectStylePresetService();
  static const SelectionIdentityService _selectionIdentityService =
      SelectionIdentityService();
  static const TextParagraphFormattingService _paragraphFormattingService =
      TextParagraphFormattingService();
  static const TextStylePresetService _textStylePresetService =
      TextStylePresetService();

  final PresentationComponent component;
  final Size slideSize;
  final double zoom;

  const SlideSelectionContextToolbar({
    super.key,
    required this.component,
    required this.slideSize,
    required this.zoom,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final safeZoom = math.max(zoom, 0.1);
    final logicalPadding = 8 / safeZoom;
    final toolbarLogicalWidth = _visualWidth / safeZoom;
    final top = math.max(
      logicalPadding,
      component.position.dy - ((_visualHeight + _visualGap) / safeZoom),
    );
    final left = component.position.dx.clamp(
      logicalPadding,
      math.max(logicalPadding, slideSize.width - toolbarLogicalWidth),
    );
    final presentation = ref.watch(presentationProvider);
    final theme = presentation.theme;
    final accentColor = theme.primaryColor;
    final layerActions = ref.read(componentLayerActionsProvider);
    final propertyActions = ref.read(componentPropertyActionsProvider);
    final isLocked = component.isLocked;
    final selectedPreset = _objectStylePresetService.detectPreset(
      component: component,
      theme: theme,
    );
    final selectedTextPreset = component.richText == null
        ? null
        : _textStylePresetService.detectPreset(
            content: component.richText!,
            theme: theme,
          );
    final activeParagraphListStyle = component.richText == null
        ? TextParagraphListStyle.none
        : _paragraphFormattingService.activeListStyle(component.richText!.text);
    final identity = _selectionIdentityService.identityFor(component);

    return Positioned(
      left: left.toDouble(),
      top: top.toDouble(),
      child: Transform.scale(
        alignment: Alignment.topLeft,
        scale: 1 / safeZoom,
        child: Material(
          color: Colors.transparent,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SelectionIdentityChip(
                identity: identity,
                accentColor: accentColor,
              ),
              const SizedBox(width: _identityGap),
              SelectionContextActionBar(
                isLocked: isLocked,
                accentColor: accentColor,
                onDuplicate: () => layerActions.duplicateSelectedLayer(),
                onLayerOrderSelected: (action) {
                  _applyLayerOrderAction(layerActions, action);
                },
                arrangeMenu: SelectionContextArrangeMenu(
                  enabled: !isLocked,
                  accentColor: accentColor,
                  onSelected: layerActions.arrangeSelectedLayer,
                ),
                quickFormatMenu: SelectionQuickFormatMenu(
                  enabled: !isLocked,
                  accentColor: theme.primaryColor,
                  secondaryColor: theme.secondaryColor,
                  selectedPreset: selectedPreset,
                  fillColors: _quickFormatPalette(
                    theme.colorPalette,
                    theme.primaryColor,
                    theme.secondaryColor,
                  ),
                  selectedFillColor: component.backgroundColor,
                  selectedBorderColor: component.border?.color ?? accentColor,
                  selectedBorderWidth: component.border?.width ?? 0,
                  selectedOpacity: component.opacity,
                  selectedGlowEnabled: component.hasGlow,
                  selectedGlowColor: component.glowColor,
                  richText: component.richText,
                  activeParagraphListStyle: activeParagraphListStyle,
                  selectedTextPreset: selectedTextPreset,
                  onSelected: (action) {
                    _applyQuickFormatAction(propertyActions, action);
                  },
                ),
                onOpenProperties: () {
                  ref.read(propertiesPanelVisibleProvider.notifier).state =
                      true;
                },
                onToggleLock: () {
                  layerActions.setLayerLocked(component.id, !isLocked);
                },
                onDelete: () => layerActions.deleteSelectedLayer(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _applyLayerOrderAction(
    ComponentLayerActions actions,
    SelectionContextLayerOrderAction action,
  ) {
    switch (action) {
      case SelectionContextLayerOrderAction.bringForward:
        actions.moveSelectedLayerForward();
        break;
      case SelectionContextLayerOrderAction.bringToFront:
        actions.bringSelectedLayerToFront();
        break;
      case SelectionContextLayerOrderAction.sendBackward:
        actions.moveSelectedLayerBackward();
        break;
      case SelectionContextLayerOrderAction.sendToBack:
        actions.sendSelectedLayerToBack();
        break;
    }
  }

  void _applyQuickFormatAction(
    ComponentPropertyActions actions,
    SelectionQuickFormatAction action,
  ) {
    switch (action.type) {
      case SelectionQuickFormatActionType.objectPreset:
        final preset = action.preset;
        if (preset != null) actions.applySelectedObjectStylePreset(preset);
        break;
      case SelectionQuickFormatActionType.textPreset:
        final preset = action.textPreset;
        if (preset != null) actions.applySelectedTextStylePreset(preset);
        break;
      case SelectionQuickFormatActionType.fillColor:
        final color = action.color;
        if (color != null) actions.updateSelectedFillColor(color);
        break;
      case SelectionQuickFormatActionType.clearFill:
        actions.clearSelectedFillColor();
        break;
      case SelectionQuickFormatActionType.borderColor:
        final color = action.color;
        if (color != null) actions.updateSelectedBorder(color: color);
        break;
      case SelectionQuickFormatActionType.clearBorder:
        actions.clearSelectedBorder();
        break;
      case SelectionQuickFormatActionType.borderWidth:
        final width = action.value;
        if (width != null) actions.updateSelectedBorder(width: width);
        break;
      case SelectionQuickFormatActionType.opacity:
        final opacity = action.value;
        if (opacity != null) actions.updateSelectedOpacity(opacity);
        break;
      case SelectionQuickFormatActionType.glowEnabled:
        final enabled = action.enabled;
        if (enabled != null) actions.updateSelectedGlow(enabled: enabled);
        break;
      case SelectionQuickFormatActionType.glowColor:
        final color = action.color;
        if (color != null) actions.updateSelectedGlow(color: color);
        break;
      case SelectionQuickFormatActionType.textColor:
        final color = action.color;
        if (color != null) actions.updateSelectedTextStyle(color: color);
        break;
      case SelectionQuickFormatActionType.textHighlightColor:
        final color = action.color;
        if (color != null) {
          actions.updateSelectedTextStyle(highlightColor: color);
        }
        break;
      case SelectionQuickFormatActionType.textClearHighlight:
        actions.updateSelectedTextStyle(clearHighlight: true);
        break;
      case SelectionQuickFormatActionType.textFontFamily:
        final fontFamily = action.textValue;
        if (fontFamily != null) {
          actions.updateSelectedTextStyle(fontFamily: fontFamily);
        }
        break;
      case SelectionQuickFormatActionType.textFontSize:
        final fontSize = action.value;
        if (fontSize != null) {
          actions.updateSelectedTextStyle(fontSize: fontSize);
        }
        break;
      case SelectionQuickFormatActionType.textLineHeight:
        final lineHeight = action.value;
        if (lineHeight != null) {
          actions.updateSelectedTextStyle(lineHeight: lineHeight);
        }
        break;
      case SelectionQuickFormatActionType.textLetterSpacing:
        final letterSpacing = action.value;
        if (letterSpacing != null) {
          actions.updateSelectedTextStyle(letterSpacing: letterSpacing);
        }
        break;
      case SelectionQuickFormatActionType.textBold:
        final enabled = action.enabled;
        if (enabled != null) actions.updateSelectedTextStyle(isBold: enabled);
        break;
      case SelectionQuickFormatActionType.textItalic:
        final enabled = action.enabled;
        if (enabled != null) actions.updateSelectedTextStyle(isItalic: enabled);
        break;
      case SelectionQuickFormatActionType.textUnderline:
        final enabled = action.enabled;
        if (enabled != null) {
          actions.updateSelectedTextStyle(isUnderline: enabled);
        }
        break;
      case SelectionQuickFormatActionType.textStrikethrough:
        final enabled = action.enabled;
        if (enabled != null) {
          actions.updateSelectedTextStyle(isStrikethrough: enabled);
        }
        break;
      case SelectionQuickFormatActionType.textAlignment:
        final alignment = action.alignment;
        if (alignment != null) {
          actions.updateSelectedTextStyle(alignment: alignment);
        }
        break;
      case SelectionQuickFormatActionType.paragraphListStyle:
        final style = action.paragraphListStyle;
        if (style != null) actions.applySelectedParagraphListStyle(style);
        break;
      case SelectionQuickFormatActionType.textIndent:
        final direction = action.indentDirection;
        if (direction != null) actions.adjustSelectedTextIndent(direction);
        break;
      case SelectionQuickFormatActionType.textCase:
        final transform = action.caseTransform;
        if (transform != null) actions.applySelectedTextCase(transform);
        break;
    }
  }

  List<Color> _quickFormatPalette(
    List<Color> themePalette,
    Color primaryColor,
    Color secondaryColor,
  ) {
    final candidates = [
      primaryColor,
      secondaryColor,
      ...themePalette,
      const Color(0xFFFFFFFF),
      const Color(0xFF0F172A),
      const Color(0xFFF43F5E),
      const Color(0xFFF59E0B),
      const Color(0xFF10B981),
    ];
    final seen = <int>{};

    return [
      for (final color in candidates)
        if (seen.add(color.toARGB32())) color,
    ];
  }
}

@Preview(name: 'Slide selection context toolbar', size: Size(420, 220))
Widget slideSelectionContextToolbarPreview() {
  return ProviderScope(
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF101114),
        body: Stack(
          children: [
            SlideSelectionContextToolbar(
              component: PresentationComponent(
                id: 'preview-title',
                type: ComponentType.richText,
                layerName: 'Quarterly update',
                position: const Offset(96, 96),
                size: const Size(180, 56),
              ),
              slideSize: const Size(420, 220),
              zoom: 1,
            ),
          ],
        ),
      ),
    ),
  );
}
