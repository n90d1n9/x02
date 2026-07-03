import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/chart_data.dart';
import '../models/component.dart';
import '../models/enums.dart';
import '../models/presentation.dart';
import '../models/presentation_component.dart';
import '../models/rich_text_content.dart';
import '../models/slide.dart';
import '../models/slide_template.dart';
import '../models/style/gradient_animation.dart';

class SlideTemplateService {
  const SlideTemplateService._();

  static List<SlideTemplateRecipe> get recipes => SlideTemplateCatalog.recipes;

  static SlideTemplateRecipe recipeFor(SlideTemplateType type) {
    return recipes.firstWhere((recipe) => recipe.type == type);
  }

  static List<SlideTemplateRecipe> filterRecipes(
    String query, {
    SlideTemplateCategory? category,
  }) {
    final filteredByCategory = category == null
        ? recipes
        : recipes.where((recipe) => recipe.category == category);
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return filteredByCategory.toList(growable: false);
    }

    return filteredByCategory
        .where((recipe) => _matchesQuery(recipe, normalizedQuery))
        .toList(growable: false);
  }

  static Map<SlideTemplateCategory, int> categoryCounts(String query) {
    final counts = {
      for (final category in SlideTemplateCategory.values) category: 0,
    };

    for (final recipe in filterRecipes(query)) {
      counts[recipe.category] = counts[recipe.category]! + 1;
    }

    return counts;
  }

  static Slide createSlide({
    required SlideTemplateType type,
    required Presentation presentation,
    SlideTemplateCustomization? customization,
    int? sequenceNumber,
  }) {
    final recipe = recipeFor(type);
    final content =
        customization ?? SlideTemplateCustomization.defaultsFor(type);

    switch (type) {
      case SlideTemplateType.executiveCover:
        return _executiveCover(presentation, recipe, content);
      case SlideTemplateType.agenda:
        return _agenda(presentation, recipe, content);
      case SlideTemplateType.metricStory:
        return _metricStory(presentation, recipe, content);
      case SlideTemplateType.comparison:
        return _comparison(presentation, recipe, content);
    }
  }

  static Slide _executiveCover(
    Presentation presentation,
    SlideTemplateRecipe recipe,
    SlideTemplateCustomization content,
  ) {
    final theme = presentation.theme;
    final size = presentation.slideSize;

    return Slide(
      id: _id(),
      title: recipe.name,
      backgroundColor: theme.backgroundColor,
      backgroundGradient: GradientAnimation(
        colors: [
          theme.backgroundColor,
          theme.primaryColor.withValues(alpha: 0.72),
          theme.secondaryColor.withValues(alpha: 0.58),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      components: [
        _shape(
          position: _offset(size, 0.62, 0.12),
          size: _componentSize(size, 0.3, 0.66),
          color: Colors.white.withValues(alpha: 0.08),
          zIndex: 1,
          border: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        _shape(
          position: _offset(size, 0.073, 0.148),
          size: _componentSize(size, 0.14, 0.054),
          color: Colors.white.withValues(alpha: 0.14),
          zIndex: 2,
          border: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
        ),
        _text(
          text: content.eyebrow,
          position: _offset(size, 0.083, 0.161),
          size: _componentSize(size, 0.12, 0.034),
          style: theme.bodyStyle.copyWith(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
          zIndex: 3,
        ),
        _text(
          text: content.headline,
          position: _offset(size, 0.073, 0.262),
          size: _componentSize(size, 0.5, 0.25),
          style: theme.titleStyle.copyWith(
            color: Colors.white,
            fontSize: 68,
            fontWeight: FontWeight.w800,
            height: 1.02,
            letterSpacing: 0,
          ),
          zIndex: 4,
        ),
        _text(
          text: content.subheadline,
          position: _offset(size, 0.076, 0.56),
          size: _componentSize(size, 0.38, 0.12),
          style: theme.bodyStyle.copyWith(
            color: Colors.white.withValues(alpha: 0.78),
            fontSize: 24,
            height: 1.35,
            letterSpacing: 0,
          ),
          zIndex: 5,
        ),
        _text(
          text: content.footer,
          position: _offset(size, 0.076, 0.815),
          size: _componentSize(size, 0.32, 0.05),
          style: theme.bodyStyle.copyWith(
            color: Colors.white.withValues(alpha: 0.68),
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
          zIndex: 6,
        ),
      ],
    );
  }

  static Slide _agenda(
    Presentation presentation,
    SlideTemplateRecipe recipe,
    SlideTemplateCustomization content,
  ) {
    final theme = presentation.theme;
    final size = presentation.slideSize;
    final steps = _itemsFor(content, SlideTemplateType.agenda);

    final components = <PresentationComponent>[
      _text(
        text: content.headline,
        position: _offset(size, 0.075, 0.115),
        size: _componentSize(size, 0.4, 0.09),
        style: theme.titleStyle.copyWith(
          fontSize: 56,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
        zIndex: 1,
      ),
      _text(
        text: content.subheadline,
        position: _offset(size, 0.077, 0.215),
        size: _componentSize(size, 0.42, 0.06),
        style: theme.bodyStyle.copyWith(
          color: theme.textColor.withValues(alpha: 0.68),
          fontSize: 22,
          letterSpacing: 0,
        ),
        zIndex: 2,
      ),
    ];

    for (var index = 0; index < steps.length; index++) {
      final step = steps[index];
      final top = 0.34 + (index * 0.135);
      components.addAll([
        _shape(
          position: _offset(size, 0.077, top),
          size: _componentSize(size, 0.78, 0.1),
          color: Colors.white.withValues(alpha: 0.07),
          zIndex: 3 + index * 2,
          border: BorderSide(
            color: index == 0
                ? theme.primaryColor.withValues(alpha: 0.8)
                : Colors.white.withValues(alpha: 0.1),
            width: index == 0 ? 2 : 1,
          ),
        ),
        _text(
          text: '${step.label}  ${step.title}\n${step.body}',
          position: _offset(size, 0.105, top + 0.018),
          size: _componentSize(size, 0.69, 0.07),
          style: theme.bodyStyle.copyWith(
            color: theme.textColor,
            fontSize: 24,
            fontWeight: FontWeight.w600,
            height: 1.28,
            letterSpacing: 0,
          ),
          zIndex: 4 + index * 2,
        ),
      ]);
    }

    return Slide(
      id: _id(),
      title: recipe.name,
      backgroundColor: theme.backgroundColor,
      components: components,
    );
  }

  static Slide _metricStory(
    Presentation presentation,
    SlideTemplateRecipe recipe,
    SlideTemplateCustomization content,
  ) {
    final theme = presentation.theme;
    final size = presentation.slideSize;
    final metrics = _metricsFor(content);

    final components = <PresentationComponent>[
      _text(
        text: content.headline,
        position: _offset(size, 0.073, 0.11),
        size: _componentSize(size, 0.38, 0.09),
        style: theme.titleStyle.copyWith(
          fontSize: 54,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
        zIndex: 1,
      ),
      _text(
        text: content.subheadline,
        position: _offset(size, 0.075, 0.21),
        size: _componentSize(size, 0.55, 0.06),
        style: theme.bodyStyle.copyWith(
          color: theme.textColor.withValues(alpha: 0.68),
          fontSize: 21,
          letterSpacing: 0,
        ),
        zIndex: 2,
      ),
      PresentationComponent(
        id: _id(),
        type: ComponentType.chart,
        position: _offset(size, 0.43, 0.34),
        size: _componentSize(size, 0.42, 0.43),
        chartData: ChartData(
          type: ChartType.line,
          values: [18, 28, 34, 48, 57, 72],
          labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
          colors: theme.colorPalette,
        ),
        backgroundColor: Colors.white.withValues(alpha: 0.06),
        border: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        zIndex: 3,
      ),
    ];

    for (var index = 0; index < metrics.length; index++) {
      final metric = metrics[index];
      final top = 0.34 + index * 0.145;
      components.addAll([
        _shape(
          position: _offset(size, 0.075, top),
          size: _componentSize(size, 0.28, 0.105),
          color: theme.colorPalette[index].withValues(alpha: 0.18),
          zIndex: 4 + index * 2,
          border: BorderSide(
            color: theme.colorPalette[index].withValues(alpha: 0.46),
          ),
        ),
        _text(
          text: '${metric.label}\n${metric.value}  ${metric.trend}',
          position: _offset(size, 0.098, top + 0.02),
          size: _componentSize(size, 0.22, 0.065),
          style: theme.bodyStyle.copyWith(
            color: theme.textColor,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            height: 1.3,
            letterSpacing: 0,
          ),
          zIndex: 5 + index * 2,
        ),
      ]);
    }

    return Slide(
      id: _id(),
      title: recipe.name,
      backgroundColor: theme.backgroundColor,
      components: components,
    );
  }

  static Slide _comparison(
    Presentation presentation,
    SlideTemplateRecipe recipe,
    SlideTemplateCustomization content,
  ) {
    final theme = presentation.theme;
    final size = presentation.slideSize;
    final items = _itemsFor(content, SlideTemplateType.comparison);

    return Slide(
      id: _id(),
      title: recipe.name,
      backgroundColor: theme.backgroundColor,
      components: [
        _text(
          text: content.headline,
          position: _offset(size, 0.073, 0.105),
          size: _componentSize(size, 0.5, 0.09),
          style: theme.titleStyle.copyWith(
            fontSize: 54,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
          zIndex: 1,
        ),
        _shape(
          position: _offset(size, 0.073, 0.255),
          size: _componentSize(size, 0.38, 0.54),
          color: theme.primaryColor.withValues(alpha: 0.16),
          zIndex: 2,
          border: BorderSide(color: theme.primaryColor.withValues(alpha: 0.52)),
        ),
        _shape(
          position: _offset(size, 0.49, 0.255),
          size: _componentSize(size, 0.38, 0.54),
          color: Colors.white.withValues(alpha: 0.07),
          zIndex: 3,
          border: BorderSide(color: Colors.white.withValues(alpha: 0.13)),
        ),
        _text(
          text: items[0].title,
          position: _offset(size, 0.105, 0.305),
          size: _componentSize(size, 0.24, 0.06),
          style: theme.titleStyle.copyWith(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
          zIndex: 4,
        ),
        _text(
          text: items[1].title,
          position: _offset(size, 0.522, 0.305),
          size: _componentSize(size, 0.24, 0.06),
          style: theme.titleStyle.copyWith(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
          zIndex: 5,
        ),
        _text(
          text: items[0].body,
          position: _offset(size, 0.105, 0.43),
          size: _componentSize(size, 0.28, 0.13),
          style: theme.bodyStyle.copyWith(
            color: theme.textColor.withValues(alpha: 0.78),
            fontSize: 24,
            height: 1.35,
            letterSpacing: 0,
          ),
          zIndex: 6,
        ),
        _text(
          text: items[1].body,
          position: _offset(size, 0.522, 0.43),
          size: _componentSize(size, 0.28, 0.13),
          style: theme.bodyStyle.copyWith(
            color: theme.textColor.withValues(alpha: 0.78),
            fontSize: 24,
            height: 1.35,
            letterSpacing: 0,
          ),
          zIndex: 7,
        ),
        _text(
          text: '${items[2].title}\n${items[2].body}',
          position: _offset(size, 0.105, 0.64),
          size: _componentSize(size, 0.3, 0.11),
          style: theme.bodyStyle.copyWith(
            color: theme.textColor,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            height: 1.32,
            letterSpacing: 0,
          ),
          zIndex: 8,
        ),
        _text(
          text: '${items[3].title}\n${items[3].body}',
          position: _offset(size, 0.522, 0.64),
          size: _componentSize(size, 0.3, 0.11),
          style: theme.bodyStyle.copyWith(
            color: theme.textColor,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            height: 1.32,
            letterSpacing: 0,
          ),
          zIndex: 9,
        ),
      ],
    );
  }

  static PresentationComponent _text({
    required String text,
    required Offset position,
    required Size size,
    required TextStyle style,
    required int zIndex,
    TextAlign alignment = TextAlign.left,
  }) {
    return PresentationComponent(
      id: _id(),
      type: ComponentType.richText,
      position: position,
      size: size,
      richText: RichTextContent(text: text, style: style, alignment: alignment),
      backgroundColor: Colors.transparent,
      zIndex: zIndex,
    );
  }

  static PresentationComponent _shape({
    required Offset position,
    required Size size,
    required Color color,
    required int zIndex,
    BorderSide? border,
  }) {
    return PresentationComponent(
      id: _id(),
      type: ComponentType.shape,
      position: position,
      size: size,
      backgroundColor: color,
      border: border,
      zIndex: zIndex,
    );
  }

  static Offset _offset(Size slideSize, double x, double y) {
    return Offset(slideSize.width * x, slideSize.height * y);
  }

  static Size _componentSize(Size slideSize, double width, double height) {
    return Size(slideSize.width * width, slideSize.height * height);
  }

  static List<SlideTemplateTextItem> _itemsFor(
    SlideTemplateCustomization content,
    SlideTemplateType type,
  ) {
    final defaults = SlideTemplateCustomization.defaultsFor(type).items;
    if (defaults.isEmpty) return content.items;

    return List.generate(
      defaults.length,
      (index) =>
          index < content.items.length ? content.items[index] : defaults[index],
    );
  }

  static List<SlideTemplateMetric> _metricsFor(
    SlideTemplateCustomization content,
  ) {
    final defaults = SlideTemplateCustomization.defaultsFor(
      SlideTemplateType.metricStory,
    ).metrics;

    return List.generate(
      defaults.length,
      (index) => index < content.metrics.length
          ? content.metrics[index]
          : defaults[index],
    );
  }

  static String _id() => const Uuid().v4();

  static bool _matchesQuery(SlideTemplateRecipe recipe, String query) {
    return recipe.name.toLowerCase().contains(query) ||
        recipe.summary.toLowerCase().contains(query) ||
        recipe.actionLabel.toLowerCase().contains(query) ||
        recipe.category.label.toLowerCase().contains(query) ||
        recipe.category.name.toLowerCase().contains(query) ||
        recipe.type.name.toLowerCase().contains(query);
  }
}
