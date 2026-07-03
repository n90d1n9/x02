import 'package:flutter/widgets.dart';

import 'sheet_ribbon_density.dart';

/// Density-aware horizontal row for ribbon commands and command clusters.
class SheetRibbonCommandRow extends StatelessWidget {
  const SheetRibbonCommandRow({
    super.key,
    required this.children,
    this.spacing,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  /// Command widgets displayed in order.
  final List<Widget> children;

  /// Optional fixed spacing between commands.
  ///
  /// When omitted, the spacing is resolved from [SheetRibbonDensityScope].
  final double? spacing;

  /// Vertical alignment for row children.
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final density = SheetRibbonDensityScope.of(context);
    final resolvedSpacing = spacing ?? density.commandRowGap;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: crossAxisAlignment,
      children: _spacedChildren(resolvedSpacing),
    );
  }

  List<Widget> _spacedChildren(double resolvedSpacing) {
    if (children.length < 2 || resolvedSpacing <= 0) return children;

    return [
      for (var index = 0; index < children.length; index++) ...[
        if (index > 0) SizedBox(width: resolvedSpacing),
        children[index],
      ],
    ];
  }
}
