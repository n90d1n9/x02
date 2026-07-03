import 'package:flutter/material.dart';

import '../models/object_style_preset.dart';
import '../models/presentation_component.dart';
import '../models/style/presentation_theme.dart';

/// Applies theme-aware visual presets to selected slide objects.
class ObjectStylePresetService {
  const ObjectStylePresetService();

  PresentationComponent applyPreset({
    required PresentationComponent component,
    required PresentationTheme theme,
    required ObjectStylePreset preset,
  }) {
    final signalColor = _signalColor(theme);

    return switch (preset) {
      ObjectStylePreset.filled => component.copyWith(
        backgroundColor: theme.primaryColor.withValues(alpha: 0.92),
        border: BorderSide(color: theme.secondaryColor, width: 2),
        opacity: 1,
        hasGlow: false,
        glowColor: null,
      ),
      ObjectStylePreset.outline => component.copyWith(
        backgroundColor: Colors.transparent,
        border: BorderSide(color: theme.primaryColor, width: 2),
        opacity: 1,
        hasGlow: false,
        glowColor: null,
      ),
      ObjectStylePreset.soft => component.copyWith(
        backgroundColor: theme.secondaryColor.withValues(alpha: 0.18),
        border: BorderSide(
          color: theme.primaryColor.withValues(alpha: 0.42),
          width: 1.5,
        ),
        opacity: 1,
        hasGlow: true,
        glowColor: theme.secondaryColor,
      ),
      ObjectStylePreset.ghost => component.copyWith(
        backgroundColor: theme.textColor.withValues(alpha: 0.08),
        border: BorderSide(
          color: theme.textColor.withValues(alpha: 0.16),
          width: 1,
        ),
        opacity: 0.82,
        hasGlow: false,
        glowColor: null,
      ),
      ObjectStylePreset.signal => component.copyWith(
        backgroundColor: signalColor.withValues(alpha: 0.88),
        border: BorderSide(color: _darken(signalColor), width: 2),
        opacity: 1,
        hasGlow: true,
        glowColor: signalColor,
      ),
    };
  }

  /// Finds the preset that currently matches a component's appearance.
  ObjectStylePreset? detectPreset({
    required PresentationComponent component,
    required PresentationTheme theme,
  }) {
    for (final preset in ObjectStylePreset.values) {
      if (matchesPreset(component: component, theme: theme, preset: preset)) {
        return preset;
      }
    }

    return null;
  }

  /// Returns whether a component already matches a theme-aware object preset.
  bool matchesPreset({
    required PresentationComponent component,
    required PresentationTheme theme,
    required ObjectStylePreset preset,
  }) {
    final expected = applyPreset(
      component: component,
      theme: theme,
      preset: preset,
    );

    return component.backgroundColor == expected.backgroundColor &&
        component.border == expected.border &&
        (component.opacity - expected.opacity).abs() < 0.001 &&
        component.hasGlow == expected.hasGlow &&
        component.glowColor == expected.glowColor;
  }

  Color _signalColor(PresentationTheme theme) {
    for (final color in theme.colorPalette) {
      final hsl = HSLColor.fromColor(color);
      if (hsl.hue >= 24 && hsl.hue <= 58 && hsl.saturation >= 0.45) {
        return color;
      }
    }

    return const Color(0xFFF59E0B);
  }

  Color _darken(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - 0.18).clamp(0.0, 1.0)).toColor();
  }
}
