import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/models/rich_text_content.dart';
import 'package:ky_slide/models/style/presentation_theme.dart';
import 'package:ky_slide/models/text_style_preset.dart';
import 'package:ky_slide/services/text_style_preset_service.dart';

void main() {
  const service = TextStylePresetService();

  test('applies theme title typography without changing text content', () {
    final result = service.applyPreset(
      content: _content(),
      theme: _theme(),
      preset: TextStylePreset.title,
    );

    expect(result.text, 'Quarterly update');
    expect(result.style.fontSize, 48);
    expect(result.style.color, const Color(0xFF111827));
    expect(result.isBold, isTrue);
    expect(result.isItalic, isFalse);
    expect(result.isUnderline, isFalse);
    expect(result.isStrikethrough, isFalse);
  });

  test('applies quote and caption variants with distinctive typography', () {
    final quote = service.applyPreset(
      content: _content(),
      theme: _theme(),
      preset: TextStylePreset.quote,
    );
    final caption = service.applyPreset(
      content: _content(),
      theme: _theme(),
      preset: TextStylePreset.caption,
    );

    expect(quote.style.fontSize, 28);
    expect(quote.style.fontStyle, FontStyle.italic);
    expect(quote.isItalic, isTrue);
    expect(quote.isStrikethrough, isFalse);
    expect(caption.style.fontSize, 14);
    expect(caption.isBold, isTrue);
  });

  test('detects active presets and ignores manual style drift', () {
    final theme = _theme();
    final quote = service.applyPreset(
      content: _content(),
      theme: theme,
      preset: TextStylePreset.quote,
    );
    final customized = quote.copyWith(
      style: quote.style.copyWith(fontSize: 30),
    );

    expect(
      service.detectPreset(content: quote, theme: theme),
      TextStylePreset.quote,
    );
    expect(
      service.matchesPreset(
        content: quote,
        theme: theme,
        preset: TextStylePreset.quote,
      ),
      isTrue,
    );
    expect(service.detectPreset(content: customized, theme: theme), isNull);
  });
}

RichTextContent _content() {
  return RichTextContent(
    text: 'Quarterly update',
    style: const TextStyle(
      color: Colors.white,
      fontSize: 24,
      decoration: TextDecoration.underline,
    ),
    isUnderline: true,
    isStrikethrough: true,
  );
}

PresentationTheme _theme() {
  return PresentationTheme(
    id: 'preset-test',
    name: 'Preset Test',
    primaryColor: const Color(0xFF2563EB),
    secondaryColor: const Color(0xFF14B8A6),
    backgroundColor: Colors.white,
    textColor: const Color(0xFF111827),
    titleStyle: const TextStyle(
      color: Color(0xFF111827),
      fontFamily: 'Inter',
      fontSize: 48,
      fontWeight: FontWeight.w700,
    ),
    bodyStyle: const TextStyle(
      color: Color(0xFF334155),
      fontFamily: 'Inter',
      fontSize: 20,
    ),
    colorPalette: const [Color(0xFF2563EB), Color(0xFF14B8A6)],
  );
}
