import 'package:flutter/material.dart';

import '../theme/ky_sheet_theme.dart';
import 'sheet_ribbon_command_row.dart';
import 'sheet_ribbon_density.dart';

/// Framed ribbon command group with density-aware spacing and labelling.
class SheetRibbonGroup extends StatelessWidget {
  const SheetRibbonGroup({
    super.key,
    required this.label,
    required this.icon,
    required this.children,
  });

  final String label;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final density = SheetRibbonDensityScope.of(context);

    return Container(
      constraints: BoxConstraints(minHeight: density.groupMinHeight),
      margin: EdgeInsets.only(right: density.groupMargin),
      padding: density.groupPadding,
      decoration: BoxDecoration(
        color: KySheetColors.surface,
        border: Border.all(color: KySheetColors.gridLine),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetRibbonCommandRow(children: children),
          SizedBox(height: density.groupLabelGap),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: density.groupLabelIconSize,
                color: KySheetColors.mutedText,
              ),
              SizedBox(width: density == SheetRibbonDensity.compact ? 3 : 4),
              Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: KySheetColors.mutedText,
                  fontSize: density.groupLabelFontSize,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
