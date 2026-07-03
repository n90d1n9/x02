import 'package:flutter/material.dart';

import '../theme/ky_sheet_theme.dart';

/// Reusable menu row for workbook sheet navigation surfaces.
class WorkbookSheetMenuItem extends StatelessWidget {
  const WorkbookSheetMenuItem({
    super.key,
    required this.name,
    required this.active,
    this.indexLabel,
    this.tabColor,
  });

  /// Visible workbook sheet name.
  final String name;

  /// Whether this row represents the currently active sheet.
  final bool active;

  /// Optional compact sheet position label, such as "2".
  final String? indexLabel;

  /// Optional sheet tab color shown as a navigation cue.
  final Color? tabColor;

  @override
  Widget build(BuildContext context) {
    final effectiveIndexLabel = indexLabel;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _WorkbookSheetMenuIcon(
          active: active,
          label: effectiveIndexLabel,
          tabColor: tabColor,
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            name,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: active ? KySheetColors.accent : KySheetColors.text,
              fontSize: 13,
              fontWeight: active ? FontWeight.w800 : FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

/// Compact icon treatment shared by workbook sheet menu rows.
class _WorkbookSheetMenuIcon extends StatelessWidget {
  const _WorkbookSheetMenuIcon({
    required this.active,
    required this.label,
    required this.tabColor,
  });

  final bool active;
  final String? label;
  final Color? tabColor;

  @override
  Widget build(BuildContext context) {
    if (active) {
      return Icon(
        Icons.check_circle,
        size: 18,
        color: tabColor ?? KySheetColors.accent,
      );
    }

    final effectiveLabel = label;
    if (effectiveLabel == null || effectiveLabel.isEmpty) {
      return Icon(
        Icons.table_chart_outlined,
        size: 18,
        color: tabColor ?? KySheetColors.mutedText,
      );
    }

    final color = tabColor;
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color == null
            ? KySheetColors.surfaceMuted
            : Color.alphaBlend(color.withAlpha(22), KySheetColors.surfaceMuted),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color?.withAlpha(180) ?? KySheetColors.gridLineStrong,
        ),
      ),
      child: Text(
        effectiveLabel,
        maxLines: 1,
        overflow: TextOverflow.clip,
        style: const TextStyle(
          color: KySheetColors.mutedText,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
