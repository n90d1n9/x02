import 'package:flutter/material.dart';

import '../theme/ky_sheet_theme.dart';
import 'sheet_ribbon_density.dart';

/// Small status pill for spreadsheet selection, view, and workbook metrics.
class StatusMetricChip extends StatelessWidget {
  const StatusMetricChip({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.emphasized = false,
    this.tooltip,
    this.onPressed,
  });

  /// Short metric label rendered before the value.
  final String label;

  /// Compact metric value rendered after the label.
  final String value;

  /// Optional leading icon for faster scanning.
  final IconData? icon;

  /// Whether this metric should use accent styling.
  final bool emphasized;

  /// Optional tooltip and semantic label override.
  final String? tooltip;

  /// Optional action for interactive status metrics.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final density = SheetRibbonDensityScope.of(context);
    final foregroundColor = emphasized
        ? KySheetColors.accent
        : KySheetColors.text;
    final backgroundColor = emphasized
        ? KySheetColors.accentSoft
        : KySheetColors.surfaceMuted;
    final semanticLabel = tooltip ?? '$label $value';
    final radius = BorderRadius.circular(density.statusChipRadius);

    return Tooltip(
      message: semanticLabel,
      child: Semantics(
        label: semanticLabel,
        button: onPressed != null,
        child: MouseRegion(
          cursor: onPressed == null
              ? MouseCursor.defer
              : SystemMouseCursors.click,
          child: InkWell(
            onTap: onPressed,
            borderRadius: radius,
            child: Container(
              constraints: BoxConstraints(
                minHeight: density.statusChipMinHeight,
              ),
              padding: density.statusChipPadding,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: radius,
                border: Border.all(
                  color: emphasized
                      ? KySheetColors.headerActive
                      : KySheetColors.gridLine,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: density.statusChipIconSize,
                      color: foregroundColor,
                    ),
                    SizedBox(width: density.statusChipIconGap),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      color: KySheetColors.mutedText,
                      fontSize: density.statusChipLabelFontSize,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: density.statusChipLabelGap),
                  Text(
                    value,
                    style: TextStyle(
                      color: foregroundColor,
                      fontSize: density.statusChipValueFontSize,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
