import 'package:flutter/material.dart';

import '../theme/ky_sheet_theme.dart';
import 'sheet_ribbon_density.dart';

/// Density-aware color swatch button for ribbon color commands.
class ColorButton extends StatelessWidget {
  const ColorButton({
    super.key,
    required this.color,
    this.onPressed,
    this.tooltip,
  });

  /// Color displayed in the swatch.
  final Color color;

  /// Callback invoked when the color is selected.
  final VoidCallback? onPressed;

  /// Tooltip text describing the color command.
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final density = SheetRibbonDensityScope.of(context);
    final radius = BorderRadius.circular(density.colorSwatchRadius);

    return Tooltip(
      message: tooltip ?? 'Color',
      child: InkWell(
        onTap: onPressed,
        borderRadius: radius,
        child: Container(
          width: density.colorSwatchSize,
          height: density.colorSwatchSize,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: KySheetColors.gridLineStrong),
            borderRadius: radius,
          ),
        ),
      ),
    );
  }
}
