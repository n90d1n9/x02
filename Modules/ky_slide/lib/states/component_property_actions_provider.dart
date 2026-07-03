import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Provider, Ref;

import '../models/object_style_preset.dart';
import '../models/presentation_component.dart';
import '../models/rich_text_content.dart';
import '../models/text_paragraph_format.dart';
import '../models/text_style_preset.dart';
import '../services/component_layout_service.dart';
import '../services/object_style_preset_service.dart';
import '../services/text_paragraph_formatting_service.dart';
import '../services/text_style_preset_service.dart';
import 'component_provider.dart';
import 'history_provider.dart';
import 'presentation_provider.dart';

final componentPropertyActionsProvider = Provider<ComponentPropertyActions>((
  ref,
) {
  return ComponentPropertyActions(ref);
});

/// History-aware commands for editing the selected slide component.
class ComponentPropertyActions {
  final Ref ref;
  final ObjectStylePresetService objectStylePresetService;
  final TextParagraphFormattingService paragraphFormattingService;
  final TextStylePresetService textStylePresetService;

  const ComponentPropertyActions(
    this.ref, {
    this.objectStylePresetService = const ObjectStylePresetService(),
    this.paragraphFormattingService = const TextParagraphFormattingService(),
    this.textStylePresetService = const TextStylePresetService(),
  });

  PresentationComponent? get selectedComponent => _selectedComponent();

  bool renameSelectedLayer(String name) {
    final component = _selectedComponent();
    if (component == null) return false;

    final trimmedName = name.trim();
    final nextName = trimmedName.isEmpty ? null : trimmedName;
    if (component.layerName == nextName) return false;

    return _recordSelectedMutation(
      label: ComponentPropertyActionLabels.rename,
      mutate: (notifier, componentId) {
        notifier.renameComponentLayer(componentId, nextName);
      },
    );
  }

  bool updateSelectedFrame({
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
  }) {
    final component = _editableSelectedComponent();
    if (component == null) return false;

    final presentation = ref.read(presentationProvider);
    final updated = ComponentLayoutService.updateFrame(
      component: component,
      slideSize: presentation.slideSize,
      x: x,
      y: y,
      width: width,
      height: height,
      rotation: rotation,
    );
    if (_sameFrame(component, updated)) return false;

    return _updateSelectedComponent(
      updated,
      label: ComponentPropertyActionLabels.frame,
    );
  }

  bool updateSelectedOpacity(double opacity) {
    final component = _editableSelectedComponent();
    if (component == null) return false;

    final nextOpacity = opacity.clamp(0.0, 1.0).toDouble();
    if ((component.opacity - nextOpacity).abs() < 0.001) return false;

    return _updateSelectedComponent(
      component.copyWith(opacity: nextOpacity),
      label: ComponentPropertyActionLabels.opacity,
    );
  }

  bool updateSelectedFillColor(Color color) {
    final component = _editableSelectedComponent();
    if (component == null) return false;
    if (component.backgroundColor == color) return false;

    return _updateSelectedComponent(
      component.copyWith(backgroundColor: color),
      label: ComponentPropertyActionLabels.fill,
    );
  }

  bool clearSelectedFillColor() {
    final component = _editableSelectedComponent();
    if (component == null || component.backgroundColor == null) return false;

    return _updateSelectedComponent(
      component.copyWith(backgroundColor: null),
      label: ComponentPropertyActionLabels.fill,
    );
  }

  bool updateSelectedBorder({Color? color, double? width}) {
    final component = _editableSelectedComponent();
    if (component == null) return false;

    final current = component.border ?? const BorderSide(width: 0);
    final nextWidth = (width ?? current.width).clamp(0.0, 12.0).toDouble();
    final next = BorderSide(color: color ?? current.color, width: nextWidth);
    if (current.color == next.color &&
        (current.width - next.width).abs() < 0.001) {
      return false;
    }

    return _updateSelectedComponent(
      component.copyWith(border: next),
      label: ComponentPropertyActionLabels.border,
    );
  }

  bool clearSelectedBorder() {
    final component = _editableSelectedComponent();
    final border = component?.border;
    if (component == null || border == null) return false;

    return _updateSelectedComponent(
      component.copyWith(border: null),
      label: ComponentPropertyActionLabels.border,
    );
  }

  bool updateSelectedGlow({bool? enabled, Color? color}) {
    final component = _editableSelectedComponent();
    if (component == null) return false;

    final presentation = ref.read(presentationProvider);
    final nextHasGlow = enabled ?? (color != null ? true : component.hasGlow);
    final nextGlowColor =
        color ??
        (nextHasGlow
            ? component.glowColor ?? presentation.theme.primaryColor
            : null);

    if (component.hasGlow == nextHasGlow &&
        component.glowColor == nextGlowColor) {
      return false;
    }

    return _updateSelectedComponent(
      component.copyWith(hasGlow: nextHasGlow, glowColor: nextGlowColor),
      label: ComponentPropertyActionLabels.glow,
    );
  }

  bool applySelectedObjectStylePreset(ObjectStylePreset preset) {
    final component = _editableSelectedComponent();
    if (component == null) return false;

    final presentation = ref.read(presentationProvider);
    final updated = objectStylePresetService.applyPreset(
      component: component,
      theme: presentation.theme,
      preset: preset,
    );
    if (_sameObjectStyle(component, updated)) return false;

    return _updateSelectedComponent(
      updated,
      label: ComponentPropertyActionLabels.objectPreset,
    );
  }

  bool updateSelectedTextStyle({
    Color? color,
    Color? highlightColor,
    bool clearHighlight = false,
    double? fontSize,
    String? fontFamily,
    double? lineHeight,
    double? letterSpacing,
    bool? isBold,
    bool? isItalic,
    bool? isUnderline,
    bool? isStrikethrough,
    TextAlign? alignment,
  }) {
    final component = _editableSelectedComponent();
    final richText = component?.richText;
    if (component == null || richText == null) return false;

    final nextRichText = _updatedRichText(
      richText,
      color: color,
      highlightColor: highlightColor,
      clearHighlight: clearHighlight,
      fontSize: fontSize,
      fontFamily: fontFamily,
      lineHeight: lineHeight,
      letterSpacing: letterSpacing,
      isBold: isBold,
      isItalic: isItalic,
      isUnderline: isUnderline,
      isStrikethrough: isStrikethrough,
      alignment: alignment,
    );
    if (_sameRichText(richText, nextRichText)) return false;

    return _updateSelectedComponent(
      component.copyWith(richText: nextRichText),
      label: ComponentPropertyActionLabels.textStyle,
    );
  }

  bool applySelectedTextStylePreset(TextStylePreset preset) {
    final component = _editableSelectedComponent();
    final richText = component?.richText;
    if (component == null || richText == null) return false;

    final presentation = ref.read(presentationProvider);
    final nextRichText = textStylePresetService.applyPreset(
      content: richText,
      theme: presentation.theme,
      preset: preset,
    );
    if (_sameRichText(richText, nextRichText)) return false;

    return _updateSelectedComponent(
      component.copyWith(richText: nextRichText),
      label: ComponentPropertyActionLabels.textPreset,
    );
  }

  bool applySelectedParagraphListStyle(TextParagraphListStyle style) {
    final component = _editableSelectedComponent();
    final richText = component?.richText;
    if (component == null || richText == null) return false;

    final nextText = paragraphFormattingService.applyListStyle(
      text: richText.text,
      style: style,
    );

    return _updateSelectedText(
      richText,
      nextText,
      label: ComponentPropertyActionLabels.paragraph,
    );
  }

  bool adjustSelectedTextIndent(TextIndentDirection direction) {
    final component = _editableSelectedComponent();
    final richText = component?.richText;
    if (component == null || richText == null) return false;

    final nextText = paragraphFormattingService.adjustIndent(
      text: richText.text,
      direction: direction,
    );

    return _updateSelectedText(
      richText,
      nextText,
      label: ComponentPropertyActionLabels.indent,
    );
  }

  bool applySelectedTextCase(TextCaseTransform transform) {
    final component = _editableSelectedComponent();
    final richText = component?.richText;
    if (component == null || richText == null) return false;

    final nextText = paragraphFormattingService.applyTextCase(
      text: richText.text,
      transform: transform,
    );

    return _updateSelectedText(
      richText,
      nextText,
      label: ComponentPropertyActionLabels.textCase,
    );
  }

  bool setSelectedVisibility(bool isVisible) {
    final component = _selectedComponent();
    if (component == null || component.isVisible == isVisible) return false;

    return _recordSelectedMutation(
      label: isVisible
          ? ComponentPropertyActionLabels.show
          : ComponentPropertyActionLabels.hide,
      mutate: (notifier, componentId) {
        notifier.setComponentVisibility(componentId, isVisible);
      },
    );
  }

  bool setSelectedLocked(bool isLocked) {
    final component = _selectedComponent();
    if (component == null || component.isLocked == isLocked) return false;

    return _recordSelectedMutation(
      label: isLocked
          ? ComponentPropertyActionLabels.lock
          : ComponentPropertyActionLabels.unlock,
      mutate: (notifier, componentId) {
        notifier.setComponentLocked(componentId, isLocked);
      },
    );
  }

  bool _updateSelectedComponent(
    PresentationComponent updated, {
    required String label,
  }) {
    return _recordSelectedMutation(
      label: label,
      mutate: (notifier, componentId) {
        notifier.updateComponent(componentId, updated);
      },
    );
  }

  bool _updateSelectedText(
    RichTextContent current,
    String nextText, {
    required String label,
  }) {
    if (current.text == nextText) return false;

    final component = _editableSelectedComponent();
    if (component == null) return false;

    return _updateSelectedComponent(
      component.copyWith(richText: current.copyWith(text: nextText)),
      label: label,
    );
  }

  bool _recordSelectedMutation({
    required String label,
    required void Function(PresentationNotifier notifier, String componentId)
    mutate,
  }) {
    final component = _selectedComponent();
    if (component == null) return false;

    ref.read(historyProvider.notifier).recordPresentationMutation((notifier) {
      mutate(notifier, component.id);
    }, label: label);

    return true;
  }

  PresentationComponent? _editableSelectedComponent() {
    final component = _selectedComponent();
    if (component == null || component.isLocked) return null;

    return component;
  }

  PresentationComponent? _selectedComponent() {
    final selectedId = ref.read(selectedComponentProvider);
    if (selectedId == null) return null;

    final presentation = ref.read(presentationProvider);
    final currentSlide = presentation.slides[presentation.currentSlideIndex];

    for (final component in currentSlide.components) {
      if (component.id == selectedId) return component;
    }

    return null;
  }

  bool _sameFrame(
    PresentationComponent current,
    PresentationComponent updated,
  ) {
    return current.position == updated.position &&
        current.size == updated.size &&
        current.rotation == updated.rotation;
  }

  bool _sameObjectStyle(
    PresentationComponent current,
    PresentationComponent updated,
  ) {
    return current.backgroundColor == updated.backgroundColor &&
        current.border == updated.border &&
        (current.opacity - updated.opacity).abs() < 0.001 &&
        current.hasGlow == updated.hasGlow &&
        current.glowColor == updated.glowColor;
  }

  RichTextContent _updatedRichText(
    RichTextContent current, {
    Color? color,
    Color? highlightColor,
    bool clearHighlight = false,
    double? fontSize,
    String? fontFamily,
    double? lineHeight,
    double? letterSpacing,
    bool? isBold,
    bool? isItalic,
    bool? isUnderline,
    bool? isStrikethrough,
    TextAlign? alignment,
  }) {
    final nextFontSize = fontSize?.clamp(8.0, 96.0).toDouble();
    final nextLineHeight = lineHeight?.clamp(0.9, 2.2).toDouble();
    final nextLetterSpacing = letterSpacing?.clamp(-2.0, 8.0).toDouble();
    final nextFontFamily = fontFamily?.trim();
    final nextStyle = _updatedTextStyle(
      current.style,
      color: color,
      highlightColor: highlightColor,
      clearHighlight: clearHighlight,
      fontSize: nextFontSize,
      fontFamily: nextFontFamily?.isEmpty == true ? null : nextFontFamily,
      lineHeight: nextLineHeight,
      letterSpacing: nextLetterSpacing,
    );

    return current.copyWith(
      style: nextStyle,
      isBold: isBold,
      isItalic: isItalic,
      isUnderline: isUnderline,
      isStrikethrough: isStrikethrough,
      alignment: alignment,
    );
  }

  TextStyle _updatedTextStyle(
    TextStyle current, {
    Color? color,
    Color? highlightColor,
    bool clearHighlight = false,
    double? fontSize,
    String? fontFamily,
    double? lineHeight,
    double? letterSpacing,
  }) {
    final replacesForeground = color != null;
    final replacesBackground = clearHighlight || highlightColor != null;

    return TextStyle(
      inherit: current.inherit,
      color: current.foreground == null
          ? color ?? current.color
          : replacesForeground
          ? color
          : null,
      backgroundColor: replacesBackground
          ? clearHighlight
                ? null
                : highlightColor
          : current.background == null
          ? current.backgroundColor
          : null,
      fontSize: fontSize ?? current.fontSize,
      fontWeight: current.fontWeight,
      fontStyle: current.fontStyle,
      letterSpacing: letterSpacing ?? current.letterSpacing,
      wordSpacing: current.wordSpacing,
      textBaseline: current.textBaseline,
      height: lineHeight ?? current.height,
      leadingDistribution: current.leadingDistribution,
      locale: current.locale,
      foreground: replacesForeground ? null : current.foreground,
      background: replacesBackground ? null : current.background,
      shadows: current.shadows,
      fontFeatures: current.fontFeatures,
      fontVariations: current.fontVariations,
      decoration: current.decoration,
      decorationColor: current.decorationColor,
      decorationStyle: current.decorationStyle,
      decorationThickness: current.decorationThickness,
      debugLabel: current.debugLabel,
      fontFamily: fontFamily ?? current.fontFamily,
      fontFamilyFallback: current.fontFamilyFallback,
      overflow: current.overflow,
    );
  }

  bool _sameRichText(RichTextContent current, RichTextContent updated) {
    return current.text == updated.text &&
        current.style == updated.style &&
        current.isBold == updated.isBold &&
        current.isItalic == updated.isItalic &&
        current.isUnderline == updated.isUnderline &&
        current.isStrikethrough == updated.isStrikethrough &&
        current.alignment == updated.alignment;
  }
}

/// History labels used by selected-component property mutations.
class ComponentPropertyActionLabels {
  static const border = 'Update layer border';
  static const fill = 'Update layer fill';
  static const frame = 'Update layer frame';
  static const glow = 'Update layer glow';
  static const hide = 'Hide layer';
  static const indent = 'Update paragraph indent';
  static const lock = 'Lock layer';
  static const objectPreset = 'Apply object preset';
  static const opacity = 'Update layer opacity';
  static const rename = 'Rename layer';
  static const show = 'Show layer';
  static const paragraph = 'Format paragraph';
  static const textCase = 'Change text case';
  static const textPreset = 'Apply text preset';
  static const textStyle = 'Update text style';
  static const unlock = 'Unlock layer';

  const ComponentPropertyActionLabels._();
}
