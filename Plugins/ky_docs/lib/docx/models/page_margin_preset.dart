import 'package:flutter/widgets.dart';

/// Describes a reusable page margin preset for document layout workflows.
enum DocumentPageMarginPreset { normal, narrow, wide, compact }

/// Provides labels and point-based margin values for page margin presets.
extension DocumentPageMarginPresetDetails on DocumentPageMarginPreset {
  EdgeInsets get margins {
    return switch (this) {
      DocumentPageMarginPreset.normal => const EdgeInsets.all(72),
      DocumentPageMarginPreset.narrow => const EdgeInsets.all(36),
      DocumentPageMarginPreset.wide => const EdgeInsets.symmetric(
        horizontal: 108,
        vertical: 72,
      ),
      DocumentPageMarginPreset.compact => const EdgeInsets.symmetric(
        horizontal: 54,
        vertical: 48,
      ),
    };
  }

  String get label {
    return switch (this) {
      DocumentPageMarginPreset.normal => 'Normal',
      DocumentPageMarginPreset.narrow => 'Narrow',
      DocumentPageMarginPreset.wide => 'Wide',
      DocumentPageMarginPreset.compact => 'Compact',
    };
  }

  String get description {
    return switch (this) {
      DocumentPageMarginPreset.normal => 'Balanced document margins',
      DocumentPageMarginPreset.narrow => 'More room for dense content',
      DocumentPageMarginPreset.wide => 'Roomier editorial spacing',
      DocumentPageMarginPreset.compact => 'Tighter vertical spacing',
    };
  }

  bool matches(EdgeInsets value) {
    return _samePointValue(value.left, margins.left) &&
        _samePointValue(value.top, margins.top) &&
        _samePointValue(value.right, margins.right) &&
        _samePointValue(value.bottom, margins.bottom);
  }
}

/// Finds the known preset that exactly matches a margin set.
class DocumentPageMarginPresetMatcher {
  const DocumentPageMarginPresetMatcher._();

  static DocumentPageMarginPreset? match(EdgeInsets margins) {
    for (final preset in DocumentPageMarginPreset.values) {
      if (preset.matches(margins)) return preset;
    }
    return null;
  }
}

bool _samePointValue(double left, double right) {
  return (left - right).abs() < 0.01;
}
