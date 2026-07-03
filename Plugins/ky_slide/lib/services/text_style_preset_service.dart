import 'package:flutter/material.dart';

import '../models/rich_text_content.dart';
import '../models/style/presentation_theme.dart';
import '../models/text_style_preset.dart';

/// Applies theme-aware style presets to rich text components.
class TextStylePresetService {
  const TextStylePresetService();

  TextStylePreset? detectPreset({
    required RichTextContent content,
    required PresentationTheme theme,
  }) {
    for (final preset in TextStylePreset.values) {
      if (matchesPreset(content: content, theme: theme, preset: preset)) {
        return preset;
      }
    }

    return null;
  }

  bool matchesPreset({
    required RichTextContent content,
    required PresentationTheme theme,
    required TextStylePreset preset,
  }) {
    final expected = applyPreset(
      content: content,
      theme: theme,
      preset: preset,
    );

    return content.style == expected.style &&
        content.isBold == expected.isBold &&
        content.isItalic == expected.isItalic &&
        content.isUnderline == expected.isUnderline &&
        content.isStrikethrough == expected.isStrikethrough;
  }

  RichTextContent applyPreset({
    required RichTextContent content,
    required PresentationTheme theme,
    required TextStylePreset preset,
  }) {
    final style = _styleFor(content: content, theme: theme, preset: preset);

    return content.copyWith(
      style: style,
      isBold: _isBold(style),
      isItalic: style.fontStyle == FontStyle.italic,
      isUnderline: false,
      isStrikethrough: false,
    );
  }

  TextStyle _styleFor({
    required RichTextContent content,
    required PresentationTheme theme,
    required TextStylePreset preset,
  }) {
    final current = content.style;
    final baseFontFamily =
        theme.titleStyle.fontFamily ??
        theme.bodyStyle.fontFamily ??
        current.fontFamily;

    return switch (preset) {
      TextStylePreset.title => theme.titleStyle.copyWith(
        fontFamily: theme.titleStyle.fontFamily ?? baseFontFamily,
        fontSize: theme.titleStyle.fontSize ?? 48,
        height: theme.titleStyle.height ?? 1.05,
      ),
      TextStylePreset.subtitle => theme.bodyStyle.copyWith(
        color: theme.textColor.withValues(alpha: 0.82),
        fontFamily: baseFontFamily,
        fontSize: 30,
        fontWeight: FontWeight.w600,
        height: 1.15,
      ),
      TextStylePreset.body => theme.bodyStyle.copyWith(
        color: theme.bodyStyle.color ?? theme.textColor,
        fontFamily: theme.bodyStyle.fontFamily ?? baseFontFamily,
        fontSize: theme.bodyStyle.fontSize ?? 22,
        height: theme.bodyStyle.height ?? 1.3,
      ),
      TextStylePreset.caption => theme.bodyStyle.copyWith(
        color: (theme.bodyStyle.color ?? theme.textColor).withValues(
          alpha: 0.72,
        ),
        fontFamily: theme.bodyStyle.fontFamily ?? baseFontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.2,
      ),
      TextStylePreset.quote => theme.bodyStyle.copyWith(
        color: theme.textColor,
        fontFamily: theme.bodyStyle.fontFamily ?? baseFontFamily,
        fontSize: 28,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w500,
        height: 1.25,
      ),
    };
  }

  bool _isBold(TextStyle style) {
    final fontWeight = style.fontWeight;
    if (fontWeight == null) return false;

    return fontWeight.value >= FontWeight.w600.value;
  }
}
