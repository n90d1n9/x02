import 'package:flutter/material.dart';

import 'sheet_ribbon_density.dart';

/// Horizontally scrollable row for status bar metrics and controls.
class StatusMetricRow extends StatelessWidget {
  const StatusMetricRow({
    super.key,
    required this.children,
    this.reverse = false,
    this.mainAxisSize = MainAxisSize.min,
  });

  /// Widgets rendered as density-spaced status sections.
  final List<Widget> children;

  /// Whether the scrollable row should anchor from the trailing edge.
  final bool reverse;

  /// Main-axis sizing used by the wrapped metric section.
  final MainAxisSize mainAxisSize;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: reverse,
      child: StatusMetricSection(
        mainAxisSize: mainAxisSize,
        children: children,
      ),
    );
  }
}

/// Density-aware inline group for related status bar controls.
class StatusMetricSection extends StatelessWidget {
  const StatusMetricSection({
    super.key,
    required this.children,
    this.gap,
    this.mainAxisSize = MainAxisSize.min,
  });

  /// Controls or metric chips displayed inside the section.
  final List<Widget> children;

  /// Optional spacing override between children.
  final double? gap;

  /// Main-axis sizing for the section row.
  final MainAxisSize mainAxisSize;

  @override
  Widget build(BuildContext context) {
    final resolvedGap =
        gap ?? SheetRibbonDensityScope.of(context).statusBarMetricGap;

    if (children.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: mainAxisSize,
      children: [
        for (var index = 0; index < children.length; index++) ...[
          if (index > 0) SizedBox(width: resolvedGap),
          children[index],
        ],
      ],
    );
  }
}
