import 'package:flutter/widgets.dart';

/// Visual density modes used by ribbon surfaces and command groups.
enum SheetRibbonDensity { comfortable, compact }

/// Resolves ribbon density from available layout width.
class SheetRibbonDensityResolver {
  const SheetRibbonDensityResolver._();

  /// Width below which ribbon chrome should tighten spacing.
  static const compactBreakpoint = 720.0;

  /// Width below which status bar chrome should tighten spacing.
  static const statusBarCompactBreakpoint = 900.0;

  /// Returns the density that best fits the provided ribbon width.
  static SheetRibbonDensity fromWidth(double width) {
    if (!width.isFinite) return SheetRibbonDensity.comfortable;
    return width < compactBreakpoint
        ? SheetRibbonDensity.compact
        : SheetRibbonDensity.comfortable;
  }

  /// Returns the density that best fits the provided status bar width.
  static SheetRibbonDensity fromStatusBarWidth(double width) {
    if (!width.isFinite) return SheetRibbonDensity.comfortable;
    return width < statusBarCompactBreakpoint
        ? SheetRibbonDensity.compact
        : SheetRibbonDensity.comfortable;
  }
}

/// Layout metrics derived from a ribbon density mode.
extension SheetRibbonDensityMetrics on SheetRibbonDensity {
  EdgeInsets get surfacePadding => switch (this) {
    SheetRibbonDensity.comfortable => const EdgeInsets.fromLTRB(12, 7, 12, 7),
    SheetRibbonDensity.compact => const EdgeInsets.fromLTRB(10, 6, 10, 6),
  };

  double get surfaceVerticalGap => switch (this) {
    SheetRibbonDensity.comfortable => 6,
    SheetRibbonDensity.compact => 5,
  };

  double get tabStripHeight => switch (this) {
    SheetRibbonDensity.comfortable => 38,
    SheetRibbonDensity.compact => 34,
  };

  double get tabOverflowFadeWidth => switch (this) {
    SheetRibbonDensity.comfortable => 20,
    SheetRibbonDensity.compact => 18,
  };

  double get tabButtonHeight => switch (this) {
    SheetRibbonDensity.comfortable => 32,
    SheetRibbonDensity.compact => 28,
  };

  double get tabButtonMinWidth => switch (this) {
    SheetRibbonDensity.comfortable => 78,
    SheetRibbonDensity.compact => 68,
  };

  EdgeInsets get tabButtonPadding => switch (this) {
    SheetRibbonDensity.comfortable => const EdgeInsets.symmetric(
      horizontal: 10,
    ),
    SheetRibbonDensity.compact => const EdgeInsets.symmetric(horizontal: 8),
  };

  double get tabButtonSpacing => switch (this) {
    SheetRibbonDensity.comfortable => 6,
    SheetRibbonDensity.compact => 4,
  };

  double get tabButtonRadius => switch (this) {
    SheetRibbonDensity.comfortable => 8,
    SheetRibbonDensity.compact => 7,
  };

  double get tabButtonIconSize => switch (this) {
    SheetRibbonDensity.comfortable => 15,
    SheetRibbonDensity.compact => 14,
  };

  double get tabButtonLabelGap => switch (this) {
    SheetRibbonDensity.comfortable => 6,
    SheetRibbonDensity.compact => 5,
  };

  double get tabButtonFontSize => switch (this) {
    SheetRibbonDensity.comfortable => 12,
    SheetRibbonDensity.compact => 11,
  };

  double get contextBarMinHeight => switch (this) {
    SheetRibbonDensity.comfortable => 30,
    SheetRibbonDensity.compact => 26,
  };

  EdgeInsets get contextBarPadding => switch (this) {
    SheetRibbonDensity.comfortable => const EdgeInsets.symmetric(
      horizontal: 10,
      vertical: 6,
    ),
    SheetRibbonDensity.compact => const EdgeInsets.symmetric(
      horizontal: 8,
      vertical: 4,
    ),
  };

  double get contextBarRadius => switch (this) {
    SheetRibbonDensity.comfortable => 8,
    SheetRibbonDensity.compact => 7,
  };

  double get contextBarIconSize => switch (this) {
    SheetRibbonDensity.comfortable => 15,
    SheetRibbonDensity.compact => 13,
  };

  double get contextBarGap => switch (this) {
    SheetRibbonDensity.comfortable => 8,
    SheetRibbonDensity.compact => 6,
  };

  double get contextBarFontSize => switch (this) {
    SheetRibbonDensity.comfortable => 12,
    SheetRibbonDensity.compact => 11,
  };

  double get overflowFadeWidth => switch (this) {
    SheetRibbonDensity.comfortable => 28,
    SheetRibbonDensity.compact => 24,
  };

  double get overflowButtonSize => switch (this) {
    SheetRibbonDensity.comfortable => 26,
    SheetRibbonDensity.compact => 24,
  };

  double get overflowButtonIconSize => switch (this) {
    SheetRibbonDensity.comfortable => 18,
    SheetRibbonDensity.compact => 16,
  };

  double get overflowButtonInset => switch (this) {
    SheetRibbonDensity.comfortable => 2,
    SheetRibbonDensity.compact => 1,
  };

  double get groupMinHeight => switch (this) {
    SheetRibbonDensity.comfortable => 68,
    SheetRibbonDensity.compact => 58,
  };

  double get groupMargin => switch (this) {
    SheetRibbonDensity.comfortable => 8,
    SheetRibbonDensity.compact => 6,
  };

  EdgeInsets get groupPadding => switch (this) {
    SheetRibbonDensity.comfortable => const EdgeInsets.fromLTRB(8, 7, 8, 6),
    SheetRibbonDensity.compact => const EdgeInsets.fromLTRB(6, 5, 6, 5),
  };

  double get groupLabelGap => switch (this) {
    SheetRibbonDensity.comfortable => 5,
    SheetRibbonDensity.compact => 3,
  };

  double get groupLabelIconSize => switch (this) {
    SheetRibbonDensity.comfortable => 12,
    SheetRibbonDensity.compact => 10,
  };

  double get groupLabelFontSize => switch (this) {
    SheetRibbonDensity.comfortable => 10,
    SheetRibbonDensity.compact => 9,
  };

  double get commandButtonSize => switch (this) {
    SheetRibbonDensity.comfortable => 34,
    SheetRibbonDensity.compact => 30,
  };

  double get commandIconSize => switch (this) {
    SheetRibbonDensity.comfortable => 18,
    SheetRibbonDensity.compact => 16,
  };

  double get commandPopupOffsetY => commandButtonSize + 4;

  double get commandRowGap => switch (this) {
    SheetRibbonDensity.comfortable => 6,
    SheetRibbonDensity.compact => 4,
  };

  double get colorSwatchSize => switch (this) {
    SheetRibbonDensity.comfortable => 24,
    SheetRibbonDensity.compact => 20,
  };

  double get colorSwatchRadius => switch (this) {
    SheetRibbonDensity.comfortable => 6,
    SheetRibbonDensity.compact => 5,
  };

  double get zoomControlHeight => switch (this) {
    SheetRibbonDensity.comfortable => 32,
    SheetRibbonDensity.compact => 28,
  };

  EdgeInsets get zoomControlPadding => switch (this) {
    SheetRibbonDensity.comfortable => const EdgeInsets.symmetric(horizontal: 5),
    SheetRibbonDensity.compact => const EdgeInsets.symmetric(horizontal: 4),
  };

  double get zoomControlRadius => switch (this) {
    SheetRibbonDensity.comfortable => 8,
    SheetRibbonDensity.compact => 7,
  };

  double get zoomButtonSize => switch (this) {
    SheetRibbonDensity.comfortable => 26,
    SheetRibbonDensity.compact => 22,
  };

  double get zoomButtonIconSize => switch (this) {
    SheetRibbonDensity.comfortable => 16,
    SheetRibbonDensity.compact => 14,
  };

  double get zoomButtonRadius => switch (this) {
    SheetRibbonDensity.comfortable => 6,
    SheetRibbonDensity.compact => 5,
  };

  double get zoomSliderWidth => switch (this) {
    SheetRibbonDensity.comfortable => 92,
    SheetRibbonDensity.compact => 72,
  };

  double get zoomSliderHeight => switch (this) {
    SheetRibbonDensity.comfortable => 30,
    SheetRibbonDensity.compact => 26,
  };

  double get zoomSliderTrackHeight => switch (this) {
    SheetRibbonDensity.comfortable => 3,
    SheetRibbonDensity.compact => 2.5,
  };

  double get zoomSliderThumbRadius => switch (this) {
    SheetRibbonDensity.comfortable => 6,
    SheetRibbonDensity.compact => 5,
  };

  double get zoomSliderOverlayRadius => switch (this) {
    SheetRibbonDensity.comfortable => 12,
    SheetRibbonDensity.compact => 10,
  };

  double get zoomLabelGap => switch (this) {
    SheetRibbonDensity.comfortable => 4,
    SheetRibbonDensity.compact => 3,
  };

  double get zoomLabelWidth => switch (this) {
    SheetRibbonDensity.comfortable => 38,
    SheetRibbonDensity.compact => 34,
  };

  double get zoomLabelFontSize => switch (this) {
    SheetRibbonDensity.comfortable => 12,
    SheetRibbonDensity.compact => 11,
  };

  EdgeInsets get statusBarPadding => switch (this) {
    SheetRibbonDensity.comfortable => const EdgeInsets.symmetric(
      horizontal: 10,
      vertical: 7,
    ),
    SheetRibbonDensity.compact => const EdgeInsets.symmetric(
      horizontal: 8,
      vertical: 5,
    ),
  };

  double get statusBarRadius => switch (this) {
    SheetRibbonDensity.comfortable => 10,
    SheetRibbonDensity.compact => 8,
  };

  double get statusBarSectionGap => switch (this) {
    SheetRibbonDensity.comfortable => 10,
    SheetRibbonDensity.compact => 8,
  };

  double get statusBarTrailingMaxWidthFraction => switch (this) {
    SheetRibbonDensity.comfortable => 0.46,
    SheetRibbonDensity.compact => 0.5,
  };

  double get statusBarMetricGap => switch (this) {
    SheetRibbonDensity.comfortable => 8,
    SheetRibbonDensity.compact => 6,
  };

  double get statusBarInlineGap => switch (this) {
    SheetRibbonDensity.comfortable => 4,
    SheetRibbonDensity.compact => 3,
  };

  double get statusChipMinHeight => switch (this) {
    SheetRibbonDensity.comfortable => 30,
    SheetRibbonDensity.compact => 26,
  };

  EdgeInsets get statusChipPadding => switch (this) {
    SheetRibbonDensity.comfortable => const EdgeInsets.symmetric(
      horizontal: 9,
      vertical: 5,
    ),
    SheetRibbonDensity.compact => const EdgeInsets.symmetric(
      horizontal: 7,
      vertical: 4,
    ),
  };

  double get statusChipRadius => switch (this) {
    SheetRibbonDensity.comfortable => 8,
    SheetRibbonDensity.compact => 7,
  };

  double get statusChipIconSize => switch (this) {
    SheetRibbonDensity.comfortable => 14,
    SheetRibbonDensity.compact => 12,
  };

  double get statusChipIconGap => switch (this) {
    SheetRibbonDensity.comfortable => 6,
    SheetRibbonDensity.compact => 5,
  };

  double get statusChipLabelGap => switch (this) {
    SheetRibbonDensity.comfortable => 5,
    SheetRibbonDensity.compact => 4,
  };

  double get statusChipLabelFontSize => switch (this) {
    SheetRibbonDensity.comfortable => 11,
    SheetRibbonDensity.compact => 10,
  };

  double get statusChipValueFontSize => switch (this) {
    SheetRibbonDensity.comfortable => 12,
    SheetRibbonDensity.compact => 11,
  };

  double get statusClearButtonSize => switch (this) {
    SheetRibbonDensity.comfortable => 30,
    SheetRibbonDensity.compact => 26,
  };

  double get statusClearButtonIconSize => switch (this) {
    SheetRibbonDensity.comfortable => 16,
    SheetRibbonDensity.compact => 14,
  };
}

/// Shares the active ribbon density with descendant ribbon widgets.
class SheetRibbonDensityScope extends InheritedWidget {
  const SheetRibbonDensityScope({
    super.key,
    required this.density,
    required super.child,
  });

  /// Density mode used by descendant ribbon components.
  final SheetRibbonDensity density;

  /// Returns the nearest density or a comfortable default outside the ribbon.
  static SheetRibbonDensity of(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<SheetRibbonDensityScope>()
            ?.density ??
        SheetRibbonDensity.comfortable;
  }

  @override
  bool updateShouldNotify(SheetRibbonDensityScope oldWidget) {
    return density != oldWidget.density;
  }
}
