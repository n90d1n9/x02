import 'package:flutter/material.dart';

import '../../models/object_style_preset.dart';

/// Presentation-layer metadata for rendering object style preset controls.
class ObjectStylePresetVisuals {
  final ObjectStylePreset preset;
  final String label;
  final IconData icon;
  final Color fillColor;
  final Color borderColor;
  final bool showGlow;

  const ObjectStylePresetVisuals({
    required this.preset,
    required this.label,
    required this.icon,
    required this.fillColor,
    required this.borderColor,
    required this.showGlow,
  });

  factory ObjectStylePresetVisuals.forPreset({
    required ObjectStylePreset preset,
    required Color accentColor,
    required Color secondaryColor,
  }) {
    return ObjectStylePresetVisuals(
      preset: preset,
      label: labelFor(preset),
      icon: iconFor(preset),
      fillColor: fillColorFor(
        preset: preset,
        accentColor: accentColor,
        secondaryColor: secondaryColor,
      ),
      borderColor: borderColorFor(
        preset: preset,
        accentColor: accentColor,
        secondaryColor: secondaryColor,
      ),
      showGlow: showsGlow(preset),
    );
  }

  static String labelFor(ObjectStylePreset preset) {
    return switch (preset) {
      ObjectStylePreset.filled => 'Filled',
      ObjectStylePreset.outline => 'Outline',
      ObjectStylePreset.soft => 'Soft',
      ObjectStylePreset.ghost => 'Ghost',
      ObjectStylePreset.signal => 'Signal',
    };
  }

  static IconData iconFor(ObjectStylePreset preset) {
    return switch (preset) {
      ObjectStylePreset.filled => Icons.format_color_fill,
      ObjectStylePreset.outline => Icons.crop_square,
      ObjectStylePreset.soft => Icons.blur_on,
      ObjectStylePreset.ghost => Icons.layers_clear_outlined,
      ObjectStylePreset.signal => Icons.bolt_outlined,
    };
  }

  static Color fillColorFor({
    required ObjectStylePreset preset,
    required Color accentColor,
    required Color secondaryColor,
  }) {
    return switch (preset) {
      ObjectStylePreset.filled => accentColor.withValues(alpha: 0.92),
      ObjectStylePreset.outline => Colors.transparent,
      ObjectStylePreset.soft => secondaryColor.withValues(alpha: 0.24),
      ObjectStylePreset.ghost => Colors.white.withValues(alpha: 0.08),
      ObjectStylePreset.signal => const Color(
        0xFFF59E0B,
      ).withValues(alpha: 0.88),
    };
  }

  static Color borderColorFor({
    required ObjectStylePreset preset,
    required Color accentColor,
    required Color secondaryColor,
  }) {
    return switch (preset) {
      ObjectStylePreset.filled => secondaryColor,
      ObjectStylePreset.outline => accentColor,
      ObjectStylePreset.soft => accentColor.withValues(alpha: 0.44),
      ObjectStylePreset.ghost => Colors.white.withValues(alpha: 0.18),
      ObjectStylePreset.signal => const Color(0xFFB45309),
    };
  }

  static bool showsGlow(ObjectStylePreset preset) {
    return preset == ObjectStylePreset.soft ||
        preset == ObjectStylePreset.signal;
  }
}
