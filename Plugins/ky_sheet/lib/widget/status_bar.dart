import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/sheet_format_snapshot.dart';
import '../model/sheet_selection_summary.dart';
import '../model/sheet_status_indicator_summary.dart';
import '../model/sheet_view_state.dart';
import '../model/workbook_sheet.dart';
import '../state/sheet_format_painter_provider.dart';
import '../state/sheet_formula_preview_provider.dart';
import '../state/sheet_sidebar_provider.dart';
import '../state/spreadsheet_provider.dart';
import '../state/toolbar_provider.dart';
import '../state/workbook_provider.dart';
import '../theme/ky_sheet_theme.dart';
import 'sheet_ribbon_density.dart';
import 'sheet_zoom_control.dart';
import 'status_metric_chip.dart';
import 'status_metric_row.dart';
import 'status_sheet_switcher_chip.dart';

/// Bottom spreadsheet status strip with selection, formula, and view controls.
class StatusBar extends ConsumerWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(selectedCellProvider);
    final data = ref.watch(spreadsheetProvider);
    final formatSnapshot = ref.watch(sheetFormatPainterSnapshotProvider);
    final formulaPreviewSelections = ref.watch(formulaReferencePreviewProvider);
    final formulaPreviewContext = ref.watch(
      formulaReferencePreviewContextProvider,
    );
    final workbook = ref.watch(workbookProvider);
    final toolbar = ref.read(toolbarControllerProvider);
    final viewSummary = SheetViewStateSummary(
      freezePane: ref.watch(freezePanesProvider),
      zoom: ref.watch(zoomLevelProvider),
    );
    final summary = selection == null
        ? null
        : SheetSelectionSummary.fromSelection(
            selection: selection,
            cells: data,
          );
    final statusSummary = SheetStatusIndicatorSummary.fromState(
      workbook: workbook,
      filters: ref.watch(filterProvider),
      filterRules: ref.watch(sheetFilterRulesProvider),
      sortColumn: ref.watch(sortColumnProvider),
      sortAscending: ref.watch(sortAscendingProvider),
      editingCell: ref.watch(editingCellProvider),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final density = SheetRibbonDensityResolver.fromStatusBarWidth(
          constraints.maxWidth,
        );

        return SheetRibbonDensityScope(
          density: density,
          child: Container(
            key: const ValueKey('ky-sheet-status-bar'),
            padding: density.statusBarPadding,
            decoration: BoxDecoration(
              color: KySheetColors.surface,
              border: Border.all(color: KySheetColors.gridLine),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(density.statusBarRadius),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: StatusMetricRow(
                    children: _buildLeadingMetrics(
                      statusSummary: statusSummary,
                      summary: summary,
                      formatSnapshot: formatSnapshot,
                      viewSummary: viewSummary,
                      usedCellCount: data.length,
                      sheets: workbook.sheets,
                      activeSheetId: workbook.activeSheetId,
                      onSelectSheet: ref
                          .read(workbookProvider.notifier)
                          .switchToSheet,
                      onOpenSortFilter: () =>
                          _openSidebarPanel(ref, SheetSidebarPanel.sortFilter),
                    ),
                  ),
                ),
                SizedBox(width: density.statusBarSectionGap),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth:
                        constraints.maxWidth *
                        density.statusBarTrailingMaxWidthFraction,
                  ),
                  child: StatusMetricRow(
                    reverse: true,
                    children: _buildTrailingMetrics(
                      density: density,
                      formulaPreviewContext: formulaPreviewContext,
                      hasFormulaPreview: formulaPreviewSelections.isNotEmpty,
                      viewSummary: viewSummary,
                      toolbar: toolbar,
                      onClearFormulaPreview: () => _clearFormulaPreview(ref),
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

  List<Widget> _buildLeadingMetrics({
    required SheetStatusIndicatorSummary statusSummary,
    required SheetSelectionSummary? summary,
    required SheetFormatSnapshot? formatSnapshot,
    required SheetViewStateSummary viewSummary,
    required int usedCellCount,
    required List<WorkbookSheet> sheets,
    required String activeSheetId,
    required ValueChanged<String> onSelectSheet,
    required VoidCallback onOpenSortFilter,
  }) {
    final metrics = <Widget>[
      StatusMetricChip(
        label: 'Mode',
        value: statusSummary.modeValue,
        icon: statusSummary.isEditing
            ? Icons.edit_outlined
            : Icons.check_circle_outline,
        emphasized: true,
        tooltip: statusSummary.modeTooltip,
      ),
    ];

    if (statusSummary.hasFilters) {
      metrics.add(
        StatusMetricChip(
          label: 'Filters',
          value: statusSummary.filterValue,
          icon: Icons.filter_alt_outlined,
          emphasized: true,
          tooltip: '${statusSummary.filterTooltip}. Open Sort and Filter',
          onPressed: onOpenSortFilter,
        ),
      );
    }

    if (statusSummary.hasSort) {
      metrics.add(
        StatusMetricChip(
          label: 'Sort',
          value: statusSummary.sortValue,
          icon: Icons.sort_by_alpha,
          emphasized: true,
          tooltip: '${statusSummary.sortTooltip}. Open Sort and Filter',
          onPressed: onOpenSortFilter,
        ),
      );
    }

    metrics.add(
      StatusSheetSwitcherChip(
        value: statusSummary.sheetValue,
        tooltip: '${statusSummary.sheetTooltip}. Switch sheets',
        sheets: sheets,
        activeSheetId: activeSheetId,
        onSelected: onSelectSheet,
      ),
    );

    metrics.add(
      StatusMetricChip(
        label: 'Used',
        value: usedCellCount.toString(),
        icon: Icons.data_array,
      ),
    );

    if (summary != null) {
      metrics
        ..add(
          StatusMetricChip(
            label: 'Range',
            value: summary.label,
            icon: Icons.select_all,
            emphasized: true,
          ),
        )
        ..add(
          StatusMetricChip(
            label: 'Cells',
            value: summary.selectedCellCount.toString(),
          ),
        )
        ..add(
          StatusMetricChip(
            label: 'Filled',
            value: summary.nonEmptyCellCount.toString(),
          ),
        );

      if (summary.hasNumericValues) {
        metrics
          ..add(
            StatusMetricChip(
              label: 'Count',
              value: summary.numericCellCount.toString(),
            ),
          )
          ..add(
            StatusMetricChip(
              label: 'Sum',
              value: SheetSelectionSummary.formatNumber(summary.sum),
            ),
          )
          ..add(
            StatusMetricChip(
              label: 'Avg',
              value: SheetSelectionSummary.formatNumber(summary.average!),
            ),
          )
          ..add(
            StatusMetricChip(
              label: 'Min',
              value: SheetSelectionSummary.formatNumber(summary.min!),
            ),
          )
          ..add(
            StatusMetricChip(
              label: 'Max',
              value: SheetSelectionSummary.formatNumber(summary.max!),
            ),
          );
      }
    }

    if (formatSnapshot != null) {
      metrics.add(
        StatusMetricChip(
          label: 'Painter',
          value: formatSnapshot.sourceLabel,
          icon: Icons.format_paint,
          emphasized: true,
        ),
      );
    }

    if (viewSummary.hasFreeze) {
      metrics.add(
        StatusMetricChip(
          label: 'Freeze',
          value: viewSummary.freezeLabel,
          icon: Icons.view_week_outlined,
          emphasized: true,
        ),
      );
    }

    return metrics;
  }

  List<Widget> _buildTrailingMetrics({
    required SheetRibbonDensity density,
    required SheetFormulaPreviewContext? formulaPreviewContext,
    required bool hasFormulaPreview,
    required SheetViewStateSummary viewSummary,
    required ToolbarController toolbar,
    required VoidCallback onClearFormulaPreview,
  }) {
    return [
      if (formulaPreviewContext != null && hasFormulaPreview)
        StatusMetricSection(
          gap: density.statusBarInlineGap,
          children: [
            StatusMetricChip(
              label: formulaPreviewContext.statusLabel,
              value: formulaPreviewContext.statusValue,
              icon: Icons.schema_outlined,
              emphasized: true,
            ),
            _ClearFormulaPreviewButton(onPressed: onClearFormulaPreview),
          ],
        ),
      SheetZoomControl(
        zoom: viewSummary.zoom,
        onChanged: toolbar.setZoom,
        onZoomOut: toolbar.zoomOut,
        onZoomIn: toolbar.zoomIn,
        onReset: toolbar.resetZoom,
      ),
    ];
  }

  void _clearFormulaPreview(WidgetRef ref) {
    ref.read(formulaReferencePreviewProvider.notifier).state = const [];
    ref.read(formulaReferencePreviewContextProvider.notifier).state = null;
  }

  void _openSidebarPanel(WidgetRef ref, SheetSidebarPanel panel) {
    ref.read(activeSidebarPanelProvider.notifier).state = panel;
  }
}

/// Clears the active formula reference highlight from the status bar.
class _ClearFormulaPreviewButton extends StatelessWidget {
  const _ClearFormulaPreviewButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final density = SheetRibbonDensityScope.of(context);

    return IconButton.filledTonal(
      key: const ValueKey('ky-sheet-clear-formula-highlight'),
      constraints: BoxConstraints.tightFor(
        width: density.statusClearButtonSize,
        height: density.statusClearButtonSize,
      ),
      padding: EdgeInsets.zero,
      iconSize: density.statusClearButtonIconSize,
      tooltip: 'Clear Formula Highlight',
      onPressed: onPressed,
      icon: const Icon(Icons.visibility_off_outlined),
    );
  }
}
