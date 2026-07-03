import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/models/component.dart';
import 'package:ky_slide/models/object_style_preset.dart';
import 'package:ky_slide/models/presentation_component.dart';
import 'package:ky_slide/models/style/presentation_theme.dart';
import 'package:ky_slide/services/object_style_preset_service.dart';

void main() {
  const service = ObjectStylePresetService();

  test('applies filled preset from presentation theme colors', () {
    final result = service.applyPreset(
      component: _component(),
      theme: _theme(),
      preset: ObjectStylePreset.filled,
    );

    expect(
      result.backgroundColor,
      const Color(0xFF2563EB).withValues(alpha: 0.92),
    );
    expect(result.border?.color, const Color(0xFF14B8A6));
    expect(result.border?.width, 2);
    expect(result.opacity, 1);
    expect(result.hasGlow, isFalse);
    expect(result.glowColor, isNull);
  });

  test('applies soft preset with subtle fill and glow', () {
    final result = service.applyPreset(
      component: _component(),
      theme: _theme(),
      preset: ObjectStylePreset.soft,
    );

    expect(
      result.backgroundColor,
      const Color(0xFF14B8A6).withValues(alpha: 0.18),
    );
    expect(
      result.border?.color,
      const Color(0xFF2563EB).withValues(alpha: 0.42),
    );
    expect(result.border?.width, 1.5);
    expect(result.opacity, 1);
    expect(result.hasGlow, isTrue);
    expect(result.glowColor, const Color(0xFF14B8A6));
  });

  test('uses warm palette color for signal preset', () {
    final result = service.applyPreset(
      component: _component(),
      theme: _theme(),
      preset: ObjectStylePreset.signal,
    );

    expect(
      result.backgroundColor,
      const Color(0xFFF59E0B).withValues(alpha: 0.88),
    );
    expect(result.border?.color, isNot(const Color(0xFFF59E0B)));
    expect(result.border?.width, 2);
    expect(result.hasGlow, isTrue);
    expect(result.glowColor, const Color(0xFFF59E0B));
  });

  test('detects the active object preset', () {
    final styled = service.applyPreset(
      component: _component(),
      theme: _theme(),
      preset: ObjectStylePreset.soft,
    );

    expect(
      service.detectPreset(component: styled, theme: _theme()),
      ObjectStylePreset.soft,
    );
    expect(
      service.matchesPreset(
        component: styled,
        theme: _theme(),
        preset: ObjectStylePreset.soft,
      ),
      isTrue,
    );
  });

  test('returns null when appearance no longer matches a preset', () {
    final styled = service
        .applyPreset(
          component: _component(),
          theme: _theme(),
          preset: ObjectStylePreset.outline,
        )
        .copyWith(border: const BorderSide(color: Colors.black, width: 4));

    expect(service.detectPreset(component: styled, theme: _theme()), isNull);
  });
}

PresentationComponent _component() {
  return PresentationComponent(
    id: 'object',
    type: ComponentType.shape,
    position: const Offset(40, 40),
    size: const Size(240, 120),
    backgroundColor: Colors.white,
    border: const BorderSide(color: Colors.black, width: 1),
    opacity: 0.5,
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
    titleStyle: const TextStyle(color: Color(0xFF111827), fontSize: 48),
    bodyStyle: const TextStyle(color: Color(0xFF334155), fontSize: 20),
    colorPalette: const [
      Color(0xFF2563EB),
      Color(0xFF14B8A6),
      Color(0xFFF59E0B),
    ],
  );
}
