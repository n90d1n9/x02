import 'package:flutter/material.dart';

import '../model/sheet_table.dart';
import '../theme/ky_sheet_theme.dart';
import 'sheet_ribbon_context_bar.dart';
import 'sheet_ribbon_density.dart';
import 'sheet_ribbon_overflow_scroller.dart';
import 'sheet_ribbon_tab.dart';
import 'sheet_ribbon_tab_strip.dart';

/// Full ribbon surface that resolves density and hosts tabbed command groups.
class SheetRibbonSurface extends StatelessWidget {
  const SheetRibbonSurface({
    super.key,
    required this.selectedTab,
    required this.onTabSelected,
    required this.groups,
    this.selectionLabel,
    this.activeTable,
    this.activeTableFilterLabel,
    this.activeTableFilterVisibilityLabel,
    this.onClearActiveTableFilters,
    this.onOpenTableStudio,
    this.density,
  });

  final SheetRibbonTab selectedTab;
  final ValueChanged<SheetRibbonTab> onTabSelected;
  final List<Widget> groups;
  final String? selectionLabel;
  final SheetTable? activeTable;
  final String? activeTableFilterLabel;
  final String? activeTableFilterVisibilityLabel;
  final VoidCallback? onClearActiveTableFilters;
  final VoidCallback? onOpenTableStudio;
  final SheetRibbonDensity? density;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final resolvedDensity =
            density ??
            SheetRibbonDensityResolver.fromWidth(constraints.maxWidth);

        return SheetRibbonDensityScope(
          density: resolvedDensity,
          child: Container(
            key: const ValueKey('ky-sheet-ribbon-surface'),
            padding: resolvedDensity.surfacePadding,
            decoration: const BoxDecoration(
              color: KySheetColors.surface,
              border: Border(bottom: BorderSide(color: KySheetColors.gridLine)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SheetRibbonTabStrip(
                  selectedTab: selectedTab,
                  onSelected: onTabSelected,
                ),
                SizedBox(height: resolvedDensity.surfaceVerticalGap),
                SheetRibbonContextBar(
                  tab: selectedTab,
                  selectionLabel: selectionLabel,
                  activeTable: activeTable,
                  activeTableFilterLabel: activeTableFilterLabel,
                  activeTableFilterVisibilityLabel:
                      activeTableFilterVisibilityLabel,
                  onClearActiveTableFilters: onClearActiveTableFilters,
                  onOpenTableStudio: onOpenTableStudio,
                ),
                SizedBox(height: resolvedDensity.surfaceVerticalGap),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: SheetRibbonOverflowScroller(
                    key: ValueKey(
                      'ky-sheet-ribbon-content-${selectedTab.name}',
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: groups,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
