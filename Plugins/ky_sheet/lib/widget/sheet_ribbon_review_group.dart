import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/sheet_engine_operation_provider.dart';
import '../state/sheet_sidebar_provider.dart';
import '../state/spreadsheet_provider.dart';
import '../theme/ky_sheet_theme.dart';
import '../utils/sheet_review_scanner.dart';
import 'sheet_ribbon_command_row.dart';
import 'sheet_ribbon_density.dart';
import 'tool_button.dart';

/// Review ribbon commands and live workbook review metrics.
class SheetRibbonReviewGroup extends ConsumerWidget {
  const SheetRibbonReviewGroup({super.key, required this.onOpenPanel});

  final ValueChanged<SheetSidebarPanel> onOpenPanel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewSummary = SheetReviewScanner.scan(
      ref.watch(spreadsheetProvider),
    );
    final undoCount = ref.watch(undoStackProvider).length;
    final redoCount = ref.watch(redoStackProvider).length;
    final operationCount = ref
        .watch(sheetEngineOperationLogProvider)
        .operations
        .length;

    return SheetRibbonCommandRow(
      children: [
        ToolButton(
          icon: Icons.rate_review_outlined,
          onPressed: () => onOpenPanel(SheetSidebarPanel.review),
          tooltip: 'Review',
        ),
        ToolButton(
          icon: Icons.history,
          onPressed: () => onOpenPanel(SheetSidebarPanel.history),
          tooltip: 'History',
        ),
        ToolButton(
          icon: Icons.hub_outlined,
          onPressed: () => onOpenPanel(SheetSidebarPanel.sheetEngineOperations),
          tooltip: 'Waraq Operations',
        ),
        _ReviewMetricPill(
          value: reviewSummary.commentCount,
          singularLabel: 'Comment',
          pluralLabel: 'Comments',
          icon: Icons.comment_outlined,
          color: KySheetColors.comment,
          onPressed: () => onOpenPanel(SheetSidebarPanel.review),
        ),
        _ReviewMetricPill(
          value: reviewSummary.hyperlinkCount,
          singularLabel: 'Link',
          pluralLabel: 'Links',
          icon: Icons.link,
          color: KySheetColors.formula,
          onPressed: () => onOpenPanel(SheetSidebarPanel.review),
        ),
        _ReviewMetricPill(
          value: undoCount,
          singularLabel: 'Undo',
          pluralLabel: 'Undo',
          icon: Icons.undo,
          color: KySheetColors.accent,
          onPressed: () => onOpenPanel(SheetSidebarPanel.history),
        ),
        _ReviewMetricPill(
          value: redoCount,
          singularLabel: 'Redo',
          pluralLabel: 'Redo',
          icon: Icons.redo,
          color: KySheetColors.accent,
          onPressed: () => onOpenPanel(SheetSidebarPanel.history),
        ),
        _ReviewMetricPill(
          value: operationCount,
          singularLabel: 'Op',
          pluralLabel: 'Ops',
          icon: Icons.hub_outlined,
          color: KySheetColors.mutedText,
          onPressed: () => onOpenPanel(SheetSidebarPanel.sheetEngineOperations),
        ),
      ],
    );
  }
}

/// Clickable ribbon metric pill for comments, links, history, and operations.
class _ReviewMetricPill extends StatelessWidget {
  const _ReviewMetricPill({
    required this.value,
    required this.singularLabel,
    required this.pluralLabel,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final int value;
  final String singularLabel;
  final String pluralLabel;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final density = SheetRibbonDensityScope.of(context);
    final label = '$value ${value == 1 ? singularLabel : pluralLabel}';
    final radius = BorderRadius.circular(
      density == SheetRibbonDensity.compact ? 7 : 8,
    );

    return Tooltip(
      message: label,
      child: Material(
        color: KySheetColors.surfaceMuted,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: const BorderSide(color: KySheetColors.gridLine),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onPressed,
          child: SizedBox(
            height: density.commandButtonSize,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: density == SheetRibbonDensity.compact ? 7 : 9,
              ),
              child: SheetRibbonCommandRow(
                spacing: density == SheetRibbonDensity.compact ? 4 : 5,
                children: [
                  Icon(
                    icon,
                    size: density == SheetRibbonDensity.compact ? 14 : 15,
                    color: color,
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      color: KySheetColors.text,
                      fontSize: density == SheetRibbonDensity.compact ? 10 : 11,
                      fontWeight: FontWeight.w900,
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
