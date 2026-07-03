import 'package:flutter/material.dart';

import '../model/sheet_table.dart';
import '../theme/ky_sheet_theme.dart';
import '../utils/sheet_table_style_resolver.dart';
import 'sheet_ribbon_density.dart';
import 'sheet_ribbon_tab.dart';

/// Compact status strip that describes the active ribbon tab and selection.
class SheetRibbonContextBar extends StatelessWidget {
  const SheetRibbonContextBar({
    super.key,
    required this.tab,
    this.selectionLabel,
    this.activeTable,
    this.activeTableFilterLabel,
    this.activeTableFilterVisibilityLabel,
    this.onClearActiveTableFilters,
    this.onOpenTableStudio,
  });

  final SheetRibbonTab tab;
  final String? selectionLabel;
  final SheetTable? activeTable;
  final String? activeTableFilterLabel;
  final String? activeTableFilterVisibilityLabel;
  final VoidCallback? onClearActiveTableFilters;
  final VoidCallback? onOpenTableStudio;

  @override
  Widget build(BuildContext context) {
    final density = SheetRibbonDensityScope.of(context);
    final contextInfo = SheetRibbonContextInfo.fromTab(
      tab,
      selectionLabel: selectionLabel,
    );
    final tableInfo = activeTable == null
        ? null
        : SheetRibbonTableContextInfo.fromTable(
            activeTable!,
            selectionLabel: selectionLabel,
            filterLabel: activeTableFilterLabel,
            filterVisibilityLabel: activeTableFilterVisibilityLabel,
          );
    final hasTable = tableInfo != null;
    final hasActiveTableFilters = activeTableFilterLabel?.trim().isNotEmpty;

    return Container(
      key: const ValueKey('ky-sheet-ribbon-context-bar'),
      constraints: BoxConstraints(minHeight: density.contextBarMinHeight),
      padding: density.contextBarPadding,
      decoration: BoxDecoration(
        color: hasTable
            ? tableInfo.backgroundColor
            : contextInfo.hasSelection
            ? KySheetColors.accentSoft
            : KySheetColors.surfaceMuted,
        borderRadius: BorderRadius.circular(density.contextBarRadius),
        border: Border.all(
          color: hasTable
              ? tableInfo.borderColor
              : contextInfo.hasSelection
              ? KySheetColors.accent
              : KySheetColors.gridLine,
        ),
      ),
      child: Row(
        children: [
          Icon(
            tableInfo?.icon ?? contextInfo.icon,
            size: density.contextBarIconSize,
            color: hasTable
                ? tableInfo.foregroundColor
                : contextInfo.hasSelection
                ? KySheetColors.accent
                : KySheetColors.mutedText,
          ),
          SizedBox(width: density.contextBarGap),
          Flexible(
            child: Text(
              tableInfo?.label ?? contextInfo.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: hasTable
                    ? tableInfo.foregroundColor
                    : contextInfo.hasSelection
                    ? KySheetColors.accent
                    : KySheetColors.text,
                fontSize: density.contextBarFontSize,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          SizedBox(width: density.contextBarGap),
          Expanded(
            child: Text(
              tableInfo?.message ?? contextInfo.message,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: KySheetColors.mutedText,
                fontSize: density.contextBarFontSize,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (hasTable &&
              hasActiveTableFilters == true &&
              onClearActiveTableFilters != null) ...[
            SizedBox(width: density.contextBarGap),
            _ContextBarIconAction(
              key: const ValueKey('ky-sheet-ribbon-clear-table-filters'),
              tooltip: 'Clear table filters',
              icon: Icons.filter_alt_off_outlined,
              foregroundColor: tableInfo.foregroundColor,
              backgroundColor: Colors.white.withValues(alpha: 0.78),
              onPressed: onClearActiveTableFilters!,
            ),
          ],
          if (hasTable && onOpenTableStudio != null) ...[
            SizedBox(width: density.contextBarGap),
            _ContextBarIconAction(
              key: const ValueKey('ky-sheet-ribbon-open-table-studio'),
              tooltip: 'Open Table Studio',
              icon: Icons.tune,
              foregroundColor: tableInfo.foregroundColor,
              backgroundColor: tableInfo.backgroundColor,
              onPressed: onOpenTableStudio!,
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact icon-only action used by the ribbon context bar.
class _ContextBarIconAction extends StatelessWidget {
  const _ContextBarIconAction({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.onPressed,
  });

  /// Tooltip describing the action.
  final String tooltip;

  /// Icon used for the action button.
  final IconData icon;

  /// Icon and splash foreground color.
  final Color foregroundColor;

  /// Filled tonal button background color.
  final Color backgroundColor;

  /// Called when the action is invoked.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton.filledTonal(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        style: IconButton.styleFrom(
          foregroundColor: foregroundColor,
          backgroundColor: backgroundColor,
          minimumSize: const Size.square(32),
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}

/// Presentation copy and icon metadata for the ribbon context bar.
class SheetRibbonContextInfo {
  const SheetRibbonContextInfo({
    required this.label,
    required this.message,
    required this.icon,
    required this.hasSelection,
  });

  final String label;
  final String message;
  final IconData icon;
  final bool hasSelection;

  static SheetRibbonContextInfo fromTab(
    SheetRibbonTab tab, {
    String? selectionLabel,
  }) {
    final normalizedSelection = selectionLabel?.trim();
    final hasSelection =
        normalizedSelection != null && normalizedSelection.isNotEmpty;
    final label = hasSelection
        ? '$normalizedSelection selected'
        : 'No range selected';

    return SheetRibbonContextInfo(
      label: label,
      message: hasSelection ? _readyMessage(tab) : _emptyMessage(tab),
      icon: hasSelection ? Icons.select_all : Icons.info_outline,
      hasSelection: hasSelection,
    );
  }

  static String _readyMessage(SheetRibbonTab tab) {
    return switch (tab) {
      SheetRibbonTab.home =>
        'Home tools ready for formatting and clipboard actions.',
      SheetRibbonTab.insert =>
        'Insert tools can use this range for rows, columns, charts, and names.',
      SheetRibbonTab.data =>
        'Data tools ready for sorting, filtering, cleanup, and validation.',
      SheetRibbonTab.formulas =>
        'Formula tools can inspect, insert, and trace from this range.',
      SheetRibbonTab.view =>
        'View tools can freeze panes from the active range.',
      SheetRibbonTab.review =>
        'Review tools can inspect comments, history, and Waraq activity.',
    };
  }

  static String _emptyMessage(SheetRibbonTab tab) {
    return switch (tab) {
      SheetRibbonTab.home =>
        'Select cells to enable formatting, clipboard, alignment, and number tools.',
      SheetRibbonTab.insert =>
        'Select cells before inserting rows, columns, charts, or named ranges.',
      SheetRibbonTab.data =>
        'Select cells to sort, filter, validate, or profile spreadsheet data.',
      SheetRibbonTab.formulas =>
        'Select a cell to insert, audit, trace, or inspect formulas.',
      SheetRibbonTab.view =>
        'Use view presets anytime, or select a range to freeze at selection.',
      SheetRibbonTab.review =>
        'Open review, history, or Waraq operations without selecting cells.',
    };
  }
}

/// Presentation metadata for the active structured table context.
class SheetRibbonTableContextInfo {
  const SheetRibbonTableContextInfo({
    required this.label,
    required this.message,
    required this.icon,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.borderColor,
  });

  final String label;
  final String message;
  final IconData icon;
  final Color foregroundColor;
  final Color backgroundColor;
  final Color borderColor;

  static SheetRibbonTableContextInfo fromTable(
    SheetTable table, {
    String? selectionLabel,
    String? filterLabel,
    String? filterVisibilityLabel,
  }) {
    final palette = SheetTableStyleResolver.paletteFor(table.styleId);
    final anchorLabel = selectionLabel?.trim();
    final location = anchorLabel == null || anchorLabel.isEmpty
        ? table.selection.label
        : '$anchorLabel in ${table.selection.label}';
    final options = [
      if (table.showHeaderRow) 'headers',
      if (table.showBandedRows) 'banding',
      if (table.showTotalsRow) 'totals',
    ];
    final optionsLabel = options.isEmpty ? 'plain' : options.join(' + ');
    final activeFilterLabel = filterLabel?.trim();
    final activeFilterVisibilityLabel = filterVisibilityLabel?.trim();
    final messageParts = [
      location,
      '${table.styleId.label} style',
      if (activeFilterLabel != null && activeFilterLabel.isNotEmpty)
        activeFilterLabel,
      if (activeFilterVisibilityLabel != null &&
          activeFilterVisibilityLabel.isNotEmpty)
        activeFilterVisibilityLabel,
      '$optionsLabel enabled',
    ];

    return SheetRibbonTableContextInfo(
      label: '${table.name} table',
      message: messageParts.join(' · '),
      icon: Icons.table_chart_outlined,
      foregroundColor: palette.headerBackground,
      backgroundColor: palette.bandBackground,
      borderColor: palette.headerBackground,
    );
  }
}
