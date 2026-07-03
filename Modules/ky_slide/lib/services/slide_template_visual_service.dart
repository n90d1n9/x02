import 'package:flutter/material.dart';

import '../models/slide_template.dart';

class SlideTemplateVisualService {
  const SlideTemplateVisualService._();

  static const fallbackPalette = [
    Color(0xFF38BDF8),
    Color(0xFF22C55E),
    Color(0xFFF59E0B),
    Color(0xFFEC4899),
  ];

  static Color accentFor(SlideTemplateType type, List<Color> palette) {
    final colors = palette.isEmpty ? fallbackPalette : palette;

    return colors[_paletteIndex(type) % colors.length];
  }

  static IconData iconForCategory(SlideTemplateCategory category) {
    switch (category) {
      case SlideTemplateCategory.cover:
        return Icons.article_outlined;
      case SlideTemplateCategory.structure:
        return Icons.view_agenda_outlined;
      case SlideTemplateCategory.metrics:
        return Icons.bar_chart;
      case SlideTemplateCategory.decision:
        return Icons.compare_arrows;
    }
  }

  static int _paletteIndex(SlideTemplateType type) {
    switch (type) {
      case SlideTemplateType.executiveCover:
        return 0;
      case SlideTemplateType.agenda:
        return 1;
      case SlideTemplateType.metricStory:
        return 2;
      case SlideTemplateType.comparison:
        return 3;
    }
  }
}
