import 'package:flutter/material.dart';

import 'object_style_preset.dart';
import 'text_paragraph_format.dart';
import 'text_style_preset.dart';

/// Category of quick-format mutation requested from the selected-object menu.
enum SelectionQuickFormatActionType {
  objectPreset,
  textPreset,
  textFontFamily,
  fillColor,
  clearFill,
  borderColor,
  clearBorder,
  borderWidth,
  opacity,
  glowEnabled,
  glowColor,
  textColor,
  textHighlightColor,
  textClearHighlight,
  textFontSize,
  textLineHeight,
  textLetterSpacing,
  textBold,
  textItalic,
  textUnderline,
  textStrikethrough,
  textAlignment,
  paragraphListStyle,
  textIndent,
  textCase,
}

/// Typed command payload emitted by the selected-object quick-format menu.
class SelectionQuickFormatAction {
  final SelectionQuickFormatActionType type;
  final ObjectStylePreset? preset;
  final TextStylePreset? textPreset;
  final Color? color;
  final String? textValue;
  final double? value;
  final bool? enabled;
  final TextAlign? alignment;
  final TextParagraphListStyle? paragraphListStyle;
  final TextIndentDirection? indentDirection;
  final TextCaseTransform? caseTransform;

  const SelectionQuickFormatAction._({
    required this.type,
    this.preset,
    this.textPreset,
    this.color,
    this.textValue,
    this.value,
    this.enabled,
    this.alignment,
    this.paragraphListStyle,
    this.indentDirection,
    this.caseTransform,
  });

  const SelectionQuickFormatAction.objectPreset(ObjectStylePreset preset)
    : this._(type: SelectionQuickFormatActionType.objectPreset, preset: preset);

  const SelectionQuickFormatAction.textPreset(TextStylePreset preset)
    : this._(
        type: SelectionQuickFormatActionType.textPreset,
        textPreset: preset,
      );

  const SelectionQuickFormatAction.fillColor(Color color)
    : this._(type: SelectionQuickFormatActionType.fillColor, color: color);

  const SelectionQuickFormatAction.clearFill()
    : this._(type: SelectionQuickFormatActionType.clearFill);

  const SelectionQuickFormatAction.borderColor(Color color)
    : this._(type: SelectionQuickFormatActionType.borderColor, color: color);

  const SelectionQuickFormatAction.clearBorder()
    : this._(type: SelectionQuickFormatActionType.clearBorder);

  const SelectionQuickFormatAction.borderWidth(double width)
    : this._(type: SelectionQuickFormatActionType.borderWidth, value: width);

  const SelectionQuickFormatAction.opacity(double opacity)
    : this._(type: SelectionQuickFormatActionType.opacity, value: opacity);

  const SelectionQuickFormatAction.glowEnabled(bool enabled)
    : this._(
        type: SelectionQuickFormatActionType.glowEnabled,
        enabled: enabled,
      );

  const SelectionQuickFormatAction.glowColor(Color color)
    : this._(type: SelectionQuickFormatActionType.glowColor, color: color);

  const SelectionQuickFormatAction.textColor(Color color)
    : this._(type: SelectionQuickFormatActionType.textColor, color: color);

  const SelectionQuickFormatAction.textHighlightColor(Color color)
    : this._(
        type: SelectionQuickFormatActionType.textHighlightColor,
        color: color,
      );

  const SelectionQuickFormatAction.textClearHighlight()
    : this._(type: SelectionQuickFormatActionType.textClearHighlight);

  const SelectionQuickFormatAction.textFontFamily(String fontFamily)
    : this._(
        type: SelectionQuickFormatActionType.textFontFamily,
        textValue: fontFamily,
      );

  const SelectionQuickFormatAction.textFontSize(double fontSize)
    : this._(
        type: SelectionQuickFormatActionType.textFontSize,
        value: fontSize,
      );

  const SelectionQuickFormatAction.textLineHeight(double lineHeight)
    : this._(
        type: SelectionQuickFormatActionType.textLineHeight,
        value: lineHeight,
      );

  const SelectionQuickFormatAction.textLetterSpacing(double letterSpacing)
    : this._(
        type: SelectionQuickFormatActionType.textLetterSpacing,
        value: letterSpacing,
      );

  const SelectionQuickFormatAction.textBold(bool enabled)
    : this._(type: SelectionQuickFormatActionType.textBold, enabled: enabled);

  const SelectionQuickFormatAction.textItalic(bool enabled)
    : this._(type: SelectionQuickFormatActionType.textItalic, enabled: enabled);

  const SelectionQuickFormatAction.textUnderline(bool enabled)
    : this._(
        type: SelectionQuickFormatActionType.textUnderline,
        enabled: enabled,
      );

  const SelectionQuickFormatAction.textStrikethrough(bool enabled)
    : this._(
        type: SelectionQuickFormatActionType.textStrikethrough,
        enabled: enabled,
      );

  const SelectionQuickFormatAction.textAlignment(TextAlign alignment)
    : this._(
        type: SelectionQuickFormatActionType.textAlignment,
        alignment: alignment,
      );

  const SelectionQuickFormatAction.paragraphListStyle(
    TextParagraphListStyle style,
  ) : this._(
        type: SelectionQuickFormatActionType.paragraphListStyle,
        paragraphListStyle: style,
      );

  const SelectionQuickFormatAction.textIndent(TextIndentDirection direction)
    : this._(
        type: SelectionQuickFormatActionType.textIndent,
        indentDirection: direction,
      );

  const SelectionQuickFormatAction.textCase(TextCaseTransform transform)
    : this._(
        type: SelectionQuickFormatActionType.textCase,
        caseTransform: transform,
      );
}
