import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/cell/cell_address.dart';
import '../model/cell/cell_selection.dart';
import '../model/column_config.dart';
import '../model/row_config.dart';
import '../model/sheet_cell_context_menu_state.dart';
import '../model/sheet_filter_rule.dart';
import '../model/sheet_search_match.dart';
import '../state/sheet_find_replace_provider.dart';
import '../state/sheet_format_painter_provider.dart';
import '../state/sheet_navigation_provider.dart';
import '../state/sheet_sidebar_provider.dart';
import '../state/sheet_viewport_provider.dart';
import '../state/spreadsheet_provider.dart';
import '../state/toolbar_provider.dart';
import '../theme/ky_sheet_theme.dart';
import '../utils/sheet_column_filter_summary_builder.dart';
import '../utils/sheet_column_filter_value_builder.dart';
import '../utils/sheet_fill_series.dart';
import '../utils/sheet_filter_evaluator.dart';
import '../utils/sheet_freeze_pane_layout.dart';
import '../utils/sheet_viewport_metrics.dart';
import 'inline_cell_editor.dart';
import 'sheet_cell_context_menu.dart';
import 'sheet_column_filter_dialog.dart';
import 'sheet_column_header_menu_button.dart';
import 'sheet_headers.dart';
import 'sheet_selection_mini_toolbar.dart';
import 'spreadsheet_cell.dart';

class SpreadsheetGrid extends ConsumerStatefulWidget {
  final ScrollController horizontalController;
  final ScrollController verticalController;
  final int rows;
  final int cols;

  const SpreadsheetGrid({
    super.key,
    required this.horizontalController,
    required this.verticalController,
    this.rows = 200,
    this.cols = 52,
  });

  @override
  ConsumerState<SpreadsheetGrid> createState() => _SpreadsheetGridState();
}

class _SpreadsheetGridState extends ConsumerState<SpreadsheetGrid> {
  late final ScrollController _headerHorizontalController;
  late final ScrollController _rowHeaderVerticalController;
  final _focusNode = FocusNode(debugLabel: 'KySheetGrid');

  CellAddress? _rangeStart;
  CellSelection? _fillSourceSelection;
  SheetViewportStats? _lastViewportStats;
  Offset _fillDragOffset = Offset.zero;
  bool _syncingHorizontal = false;
  bool _syncingVertical = false;

  @override
  void initState() {
    super.initState();
    _headerHorizontalController = ScrollController();
    _rowHeaderVerticalController = ScrollController();
    _attachControllerListeners();
  }

  @override
  void didUpdateWidget(covariant SpreadsheetGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.horizontalController != widget.horizontalController ||
        oldWidget.verticalController != widget.verticalController) {
      oldWidget.horizontalController.removeListener(_syncColumnHeader);
      oldWidget.verticalController.removeListener(_syncRowHeader);
      _attachControllerListeners();
    }
  }

  @override
  void dispose() {
    widget.horizontalController.removeListener(_syncColumnHeader);
    widget.verticalController.removeListener(_syncRowHeader);
    _headerHorizontalController.dispose();
    _rowHeaderVerticalController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<SheetNavigationRequest?>(sheetNavigationRequestProvider, (
      previous,
      next,
    ) {
      if (next != null) _handleNavigationRequest(next);
    });

    final rowConfig = ref.watch(rowConfigProvider);
    final columnConfig = ref.watch(columnConfigProvider);
    final selection = ref.watch(selectedCellProvider);
    final editingCell = ref.watch(editingCellProvider);
    final data = ref.watch(spreadsheetProvider);
    final filters = ref.watch(filterProvider);
    final filterRules = ref.watch(sheetFilterRulesProvider);
    final freezePane = ref.watch(freezePanesProvider);
    final zoom = ref.watch(zoomLevelProvider);
    final visibleRows = SheetFilterEvaluator.visibleRows(
      rows: SheetViewportMetrics.visibleRows(widget.rows, rowConfig),
      filters: filters,
      filterRules: filterRules,
      cells: data,
    );
    final visibleColumns = SheetViewportMetrics.visibleColumns(
      widget.cols,
      columnConfig,
    );
    final freezeLayout = SheetFreezePaneLayout.from(
      freezePane: freezePane,
      visibleRows: visibleRows,
      visibleColumns: visibleColumns,
    );

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: KySheetColors.surface,
          border: Border(
            top: BorderSide(color: KySheetColors.gridLine),
            left: BorderSide(color: KySheetColors.gridLine),
          ),
        ),
        child: Column(
          children: [
            _buildStickyColumnHeader(
              freezeLayout,
              columnConfig,
              selection,
              filters,
              filterRules,
              ref.watch(sortColumnProvider),
              ref.watch(sortAscendingProvider),
              zoom,
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStickyRowHeader(
                    freezeLayout,
                    rowConfig,
                    selection,
                    zoom,
                  ),
                  Expanded(
                    child: _buildScrollableCells(
                      visibleRows,
                      visibleColumns,
                      freezeLayout,
                      rowConfig,
                      columnConfig,
                      zoom,
                      selection,
                      editingCell,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _attachControllerListeners() {
    widget.horizontalController.addListener(_syncColumnHeader);
    widget.verticalController.addListener(_syncRowHeader);
  }

  void _syncColumnHeader() {
    if (_syncingHorizontal) return;
    _syncingHorizontal = true;
    _jumpTo(_headerHorizontalController, widget.horizontalController.offset);
    _syncingHorizontal = false;
    _rebuildForViewportScroll();
  }

  void _syncRowHeader() {
    if (_syncingVertical) return;
    _syncingVertical = true;
    _jumpTo(_rowHeaderVerticalController, widget.verticalController.offset);
    _syncingVertical = false;
    _rebuildForViewportScroll();
  }

  void _rebuildForViewportScroll() {
    if (mounted) setState(() {});
  }

  void _jumpTo(ScrollController controller, double offset) {
    if (!controller.hasClients) return;
    final position = controller.position;
    final next = offset
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
    if ((controller.offset - next).abs() > 0.5) {
      controller.jumpTo(next);
    }
  }

  Widget _buildStickyColumnHeader(
    SheetFreezePaneLayout freezeLayout,
    Map<int, ColumnConfig> columnConfig,
    CellSelection? selection,
    Map<int, String> filters,
    Map<int, SheetFilterRule> filterRules,
    int? sortColumn,
    bool sortAscending,
    double zoom,
  ) {
    final activeFilterRules = SheetFilterEvaluator.effectiveRules(
      filters: filters,
      filterRules: filterRules,
    );

    return SizedBox(
      height: KySheetMetrics.headerHeight * zoom,
      child: Row(
        children: [
          SheetCornerHeader(
            width: KySheetMetrics.rowHeaderWidth * zoom,
            height: KySheetMetrics.headerHeight * zoom,
            onTap: _selectAll,
          ),
          if (freezeLayout.hasFrozenColumns)
            SizedBox(
              width: _totalColumnWidth(
                freezeLayout.frozenColumns,
                columnConfig,
                zoom,
              ),
              height: KySheetMetrics.headerHeight * zoom,
              child: Row(
                children: [
                  for (final col in freezeLayout.frozenColumns)
                    SheetColumnHeader(
                      column: col,
                      width: SheetViewportMetrics.columnWidth(
                        col,
                        columnConfig,
                        zoom,
                      ),
                      height: KySheetMetrics.headerHeight * zoom,
                      isActive: selection?.spansColumn(col) ?? false,
                      hasFilter: activeFilterRules.containsKey(col),
                      filterDescription: activeFilterRules[col]?.description,
                      isSorted: sortColumn == col,
                      sortAscending: sortAscending,
                      canUnhideAdjacent: _hasHiddenAdjacentColumn(
                        col,
                        columnConfig,
                      ),
                      onTap: () => _selectColumn(col),
                      onMenuAction: (action) =>
                          _handleColumnHeaderAction(col, action),
                      onResize: (delta) => _resizeColumn(col, delta, zoom),
                      onAutoFit: () => _autoFitColumn(col),
                    ),
                ],
              ),
            ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columnSlice = SheetViewportMetrics.viewportSlice(
                  indexes: freezeLayout.scrollingColumns,
                  scrollOffset: _scrollOffset(widget.horizontalController),
                  viewportExtent: _boundedExtent(constraints.maxWidth),
                  extentFor: (col) =>
                      SheetViewportMetrics.columnWidth(col, columnConfig, zoom),
                );

                return SingleChildScrollView(
                  controller: _headerHorizontalController,
                  physics: const NeverScrollableScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: columnSlice.contentExtent,
                    height: KySheetMetrics.headerHeight * zoom,
                    child: Row(
                      children: [
                        SizedBox(width: columnSlice.leadingExtent),
                        for (final col in columnSlice.indexes)
                          SheetColumnHeader(
                            column: col,
                            width: SheetViewportMetrics.columnWidth(
                              col,
                              columnConfig,
                              zoom,
                            ),
                            height: KySheetMetrics.headerHeight * zoom,
                            isActive: selection?.spansColumn(col) ?? false,
                            hasFilter: activeFilterRules.containsKey(col),
                            filterDescription:
                                activeFilterRules[col]?.description,
                            isSorted: sortColumn == col,
                            sortAscending: sortAscending,
                            canUnhideAdjacent: _hasHiddenAdjacentColumn(
                              col,
                              columnConfig,
                            ),
                            onTap: () => _selectColumn(col),
                            onMenuAction: (action) =>
                                _handleColumnHeaderAction(col, action),
                            onResize: (delta) =>
                                _resizeColumn(col, delta, zoom),
                            onAutoFit: () => _autoFitColumn(col),
                          ),
                        SizedBox(width: columnSlice.trailingExtent),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyRowHeader(
    SheetFreezePaneLayout freezeLayout,
    Map<int, RowConfig> rowConfig,
    CellSelection? selection,
    double zoom,
  ) {
    return SizedBox(
      width: KySheetMetrics.rowHeaderWidth * zoom,
      child: Column(
        children: [
          if (freezeLayout.hasFrozenRows)
            SizedBox(
              height: _totalRowHeight(freezeLayout.frozenRows, rowConfig, zoom),
              child: Column(
                children: [
                  for (final row in freezeLayout.frozenRows)
                    SheetRowHeader(
                      row: row,
                      width: KySheetMetrics.rowHeaderWidth * zoom,
                      height: SheetViewportMetrics.rowHeight(
                        row,
                        rowConfig,
                        zoom,
                      ),
                      isActive: selection?.spansRow(row) ?? false,
                      canUnhideAdjacent: _hasHiddenAdjacentRow(row, rowConfig),
                      onTap: () => _selectRow(row),
                      onMenuAction: (action) =>
                          _handleRowHeaderAction(row, action),
                      onResize: (delta) => _resizeRow(row, delta, zoom),
                      onAutoFit: () => _autoFitRow(row),
                    ),
                ],
              ),
            ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final rowSlice = SheetViewportMetrics.viewportSlice(
                  indexes: freezeLayout.scrollingRows,
                  scrollOffset: _scrollOffset(widget.verticalController),
                  viewportExtent: _boundedExtent(constraints.maxHeight),
                  extentFor: (row) =>
                      SheetViewportMetrics.rowHeight(row, rowConfig, zoom),
                );

                return SingleChildScrollView(
                  controller: _rowHeaderVerticalController,
                  physics: const NeverScrollableScrollPhysics(),
                  child: SizedBox(
                    width: KySheetMetrics.rowHeaderWidth * zoom,
                    height: rowSlice.contentExtent,
                    child: Column(
                      children: [
                        SizedBox(height: rowSlice.leadingExtent),
                        for (final row in rowSlice.indexes)
                          SheetRowHeader(
                            row: row,
                            width: KySheetMetrics.rowHeaderWidth * zoom,
                            height: SheetViewportMetrics.rowHeight(
                              row,
                              rowConfig,
                              zoom,
                            ),
                            isActive: selection?.spansRow(row) ?? false,
                            canUnhideAdjacent: _hasHiddenAdjacentRow(
                              row,
                              rowConfig,
                            ),
                            onTap: () => _selectRow(row),
                            onMenuAction: (action) =>
                                _handleRowHeaderAction(row, action),
                            onResize: (delta) => _resizeRow(row, delta, zoom),
                            onAutoFit: () => _autoFitRow(row),
                          ),
                        SizedBox(height: rowSlice.trailingExtent),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollableCells(
    List<int> visibleRows,
    List<int> visibleColumns,
    SheetFreezePaneLayout freezeLayout,
    Map<int, RowConfig> rowConfig,
    Map<int, ColumnConfig> columnConfig,
    double zoom,
    CellSelection? selection,
    CellAddress? editingCell,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final frozenHeight = _totalRowHeight(
          freezeLayout.frozenRows,
          rowConfig,
          zoom,
        );
        final frozenWidth = _totalColumnWidth(
          freezeLayout.frozenColumns,
          columnConfig,
          zoom,
        );
        final scrollableHeight = _boundedExtent(
          constraints.maxHeight - frozenHeight,
        );
        final scrollableWidth = _boundedExtent(
          constraints.maxWidth - frozenWidth,
        );
        final rowSlice = SheetViewportMetrics.viewportSlice(
          indexes: freezeLayout.scrollingRows,
          scrollOffset: _scrollOffset(widget.verticalController),
          viewportExtent: scrollableHeight,
          extentFor: (row) =>
              SheetViewportMetrics.rowHeight(row, rowConfig, zoom),
        );
        final columnSlice = SheetViewportMetrics.viewportSlice(
          indexes: freezeLayout.scrollingColumns,
          scrollOffset: _scrollOffset(widget.horizontalController),
          viewportExtent: scrollableWidth,
          extentFor: (col) =>
              SheetViewportMetrics.columnWidth(col, columnConfig, zoom),
        );

        _publishViewportStats(
          visibleRows: visibleRows.length,
          visibleColumns: visibleColumns.length,
          rowSlice: rowSlice,
          columnSlice: columnSlice,
        );

        final miniToolbarFrame = _selectionMiniToolbarFrame(
          constraints: constraints,
          selection: selection,
          editingCell: editingCell,
          freezeLayout: freezeLayout,
          rowConfig: rowConfig,
          columnConfig: columnConfig,
          zoom: zoom,
          frozenHeight: frozenHeight,
          frozenWidth: frozenWidth,
        );

        final scrollableGrid = Positioned(
          left: frozenWidth,
          top: frozenHeight,
          right: 0,
          bottom: 0,
          child: SingleChildScrollView(
            controller: widget.verticalController,
            child: SingleChildScrollView(
              controller: widget.horizontalController,
              scrollDirection: Axis.horizontal,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanStart: (details) {
                  final address = _cellFromContentPosition(
                    details.localPosition,
                    freezeLayout.scrollingRows,
                    freezeLayout.scrollingColumns,
                    rowConfig,
                    columnConfig,
                    zoom,
                  );
                  if (address == null) return;
                  _rangeStart = address;
                  _selectCell(address, applyFormatPainter: false);
                },
                onPanUpdate: (details) {
                  if (_rangeStart == null) return;
                  final address = _cellFromContentPosition(
                    details.localPosition,
                    freezeLayout.scrollingRows,
                    freezeLayout.scrollingColumns,
                    rowConfig,
                    columnConfig,
                    zoom,
                  );
                  if (address == null) return;
                  ref.read(selectedCellProvider.notifier).state = CellSelection(
                    _rangeStart!,
                    address,
                  );
                },
                onPanEnd: (_) {
                  _rangeStart = null;
                  final selection = ref.read(selectedCellProvider);
                  if (selection != null) {
                    _applyFormatPainter(selection);
                  }
                },
                child: SizedBox(
                  width: columnSlice.contentExtent,
                  height: rowSlice.contentExtent,
                  child: Stack(
                    children: _buildVirtualCells(
                      rowSlice,
                      columnSlice,
                      rowConfig,
                      columnConfig,
                      zoom,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        return Stack(
          children: [
            scrollableGrid,
            if (freezeLayout.hasFrozenRows && scrollableWidth > 0)
              Positioned(
                left: frozenWidth,
                top: 0,
                right: 0,
                height: frozenHeight,
                child: _buildFrozenRowsPane(
                  freezeLayout,
                  columnSlice,
                  rowConfig,
                  columnConfig,
                  zoom,
                ),
              ),
            if (freezeLayout.hasFrozenColumns && scrollableHeight > 0)
              Positioned(
                left: 0,
                top: frozenHeight,
                width: frozenWidth,
                bottom: 0,
                child: _buildFrozenColumnsPane(
                  freezeLayout,
                  rowSlice,
                  rowConfig,
                  columnConfig,
                  zoom,
                ),
              ),
            if (freezeLayout.hasFrozenRows && freezeLayout.hasFrozenColumns)
              Positioned(
                left: 0,
                top: 0,
                width: frozenWidth,
                height: frozenHeight,
                child: _buildFrozenCornerPane(
                  freezeLayout,
                  rowConfig,
                  columnConfig,
                  zoom,
                ),
              ),
            if (freezeLayout.hasFrozenRows)
              Positioned(
                left: 0,
                top: frozenHeight - 1,
                right: 0,
                child: const Divider(
                  height: 1,
                  thickness: 1,
                  color: KySheetColors.accent,
                ),
              ),
            if (freezeLayout.hasFrozenColumns)
              Positioned(
                left: frozenWidth - 1,
                top: 0,
                bottom: 0,
                child: const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: KySheetColors.accent,
                ),
              ),
            if (miniToolbarFrame != null && selection != null)
              Positioned(
                left: miniToolbarFrame.left,
                top: miniToolbarFrame.top,
                width: miniToolbarFrame.width,
                height: miniToolbarFrame.height,
                child: SheetSelectionMiniToolbar(selection: selection),
              ),
          ],
        );
      },
    );
  }

  Rect? _selectionMiniToolbarFrame({
    required BoxConstraints constraints,
    required CellSelection? selection,
    required CellAddress? editingCell,
    required SheetFreezePaneLayout freezeLayout,
    required Map<int, RowConfig> rowConfig,
    required Map<int, ColumnConfig> columnConfig,
    required double zoom,
    required double frozenHeight,
    required double frozenWidth,
  }) {
    if (selection == null || editingCell != null) return null;

    final width = _boundedExtent(constraints.maxWidth);
    final height = _boundedExtent(constraints.maxHeight);
    const margin = 8.0;
    const gap = 8.0;
    if (width < 160 || height < SheetSelectionMiniToolbar.height + margin * 2) {
      return null;
    }

    final anchorRect = _cellViewportRect(
      selection.start,
      freezeLayout: freezeLayout,
      rowConfig: rowConfig,
      columnConfig: columnConfig,
      zoom: zoom,
      frozenHeight: frozenHeight,
      frozenWidth: frozenWidth,
    );
    if (anchorRect == null ||
        !anchorRect.overlaps(Offset.zero & Size(width, height))) {
      return null;
    }

    final toolbarWidth = math.min(
      SheetSelectionMiniToolbar.maxWidth,
      width - margin * 2,
    );
    final maxLeft = width - toolbarWidth - margin;
    final left = (anchorRect.center.dx - toolbarWidth / 2)
        .clamp(margin, math.max(margin, maxLeft))
        .toDouble();
    final aboveTop = anchorRect.top - SheetSelectionMiniToolbar.height - gap;
    final belowTop = anchorRect.bottom + gap;
    final maxTop = height - SheetSelectionMiniToolbar.height - margin;
    final preferredTop = aboveTop >= margin ? aboveTop : belowTop;
    final top = preferredTop.clamp(margin, math.max(margin, maxTop)).toDouble();

    return Rect.fromLTWH(
      left,
      top,
      toolbarWidth,
      SheetSelectionMiniToolbar.height,
    );
  }

  Rect? _cellViewportRect(
    CellAddress address, {
    required SheetFreezePaneLayout freezeLayout,
    required Map<int, RowConfig> rowConfig,
    required Map<int, ColumnConfig> columnConfig,
    required double zoom,
    required double frozenHeight,
    required double frozenWidth,
  }) {
    final rowSpan = _viewportSpanForIndex(
      index: address.row,
      frozenIndexes: freezeLayout.frozenRows,
      scrollingIndexes: freezeLayout.scrollingRows,
      frozenExtent: frozenHeight,
      scrollOffset: _scrollOffset(widget.verticalController),
      extentFor: (row) => SheetViewportMetrics.rowHeight(row, rowConfig, zoom),
    );
    final columnSpan = _viewportSpanForIndex(
      index: address.col,
      frozenIndexes: freezeLayout.frozenColumns,
      scrollingIndexes: freezeLayout.scrollingColumns,
      frozenExtent: frozenWidth,
      scrollOffset: _scrollOffset(widget.horizontalController),
      extentFor: (column) =>
          SheetViewportMetrics.columnWidth(column, columnConfig, zoom),
    );
    if (rowSpan == null || columnSpan == null) return null;

    return Rect.fromLTWH(
      columnSpan.start,
      rowSpan.start,
      columnSpan.extent,
      rowSpan.extent,
    );
  }

  ({double start, double extent})? _viewportSpanForIndex({
    required int index,
    required List<int> frozenIndexes,
    required List<int> scrollingIndexes,
    required double frozenExtent,
    required double scrollOffset,
    required double Function(int index) extentFor,
  }) {
    if (frozenIndexes.contains(index)) {
      return (
        start: _extentBeforeIndex(frozenIndexes, index, extentFor),
        extent: extentFor(index),
      );
    }

    if (!scrollingIndexes.contains(index)) return null;

    return (
      start:
          frozenExtent +
          _extentBeforeIndex(scrollingIndexes, index, extentFor) -
          scrollOffset,
      extent: extentFor(index),
    );
  }

  double _extentBeforeIndex(
    List<int> indexes,
    int target,
    double Function(int index) extentFor,
  ) {
    var offset = 0.0;
    for (final index in indexes) {
      if (index == target) break;
      offset += extentFor(index);
    }
    return offset;
  }

  List<Widget> _buildVirtualCells(
    SheetViewportSlice rowSlice,
    SheetViewportSlice columnSlice,
    Map<int, RowConfig> rowConfig,
    Map<int, ColumnConfig> columnConfig,
    double zoom,
  ) {
    final cells = <Widget>[];
    var top = rowSlice.leadingExtent;

    for (final row in rowSlice.indexes) {
      final height = SheetViewportMetrics.rowHeight(row, rowConfig, zoom);
      var left = columnSlice.leadingExtent;

      for (final col in columnSlice.indexes) {
        final width = SheetViewportMetrics.columnWidth(col, columnConfig, zoom);
        final address = CellAddress(row, col);

        cells.add(
          Positioned(
            left: left,
            top: top,
            width: width,
            height: height,
            child: _buildGridCell(address, width: width, height: height),
          ),
        );

        left += width;
      }

      top += height;
    }

    return cells;
  }

  Widget _buildFrozenRowsPane(
    SheetFreezePaneLayout freezeLayout,
    SheetViewportSlice columnSlice,
    Map<int, RowConfig> rowConfig,
    Map<int, ColumnConfig> columnConfig,
    double zoom,
  ) {
    return ClipRect(
      child: Transform.translate(
        offset: Offset(-_scrollOffset(widget.horizontalController), 0),
        child: SizedBox(
          width: columnSlice.contentExtent,
          height: _totalRowHeight(freezeLayout.frozenRows, rowConfig, zoom),
          child: Stack(
            children: _buildPaneCells(
              rows: freezeLayout.frozenRows,
              columns: columnSlice.indexes,
              initialLeft: columnSlice.leadingExtent,
              rowConfig: rowConfig,
              columnConfig: columnConfig,
              zoom: zoom,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFrozenColumnsPane(
    SheetFreezePaneLayout freezeLayout,
    SheetViewportSlice rowSlice,
    Map<int, RowConfig> rowConfig,
    Map<int, ColumnConfig> columnConfig,
    double zoom,
  ) {
    return ClipRect(
      child: Transform.translate(
        offset: Offset(0, -_scrollOffset(widget.verticalController)),
        child: SizedBox(
          width: _totalColumnWidth(
            freezeLayout.frozenColumns,
            columnConfig,
            zoom,
          ),
          height: rowSlice.contentExtent,
          child: Stack(
            children: _buildPaneCells(
              rows: rowSlice.indexes,
              columns: freezeLayout.frozenColumns,
              initialTop: rowSlice.leadingExtent,
              rowConfig: rowConfig,
              columnConfig: columnConfig,
              zoom: zoom,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFrozenCornerPane(
    SheetFreezePaneLayout freezeLayout,
    Map<int, RowConfig> rowConfig,
    Map<int, ColumnConfig> columnConfig,
    double zoom,
  ) {
    return Stack(
      children: _buildPaneCells(
        rows: freezeLayout.frozenRows,
        columns: freezeLayout.frozenColumns,
        rowConfig: rowConfig,
        columnConfig: columnConfig,
        zoom: zoom,
      ),
    );
  }

  List<Widget> _buildPaneCells({
    required List<int> rows,
    required List<int> columns,
    required Map<int, RowConfig> rowConfig,
    required Map<int, ColumnConfig> columnConfig,
    required double zoom,
    double initialTop = 0,
    double initialLeft = 0,
  }) {
    final cells = <Widget>[];
    var top = initialTop;

    for (final row in rows) {
      final height = SheetViewportMetrics.rowHeight(row, rowConfig, zoom);
      var left = initialLeft;

      for (final col in columns) {
        final width = SheetViewportMetrics.columnWidth(col, columnConfig, zoom);
        final address = CellAddress(row, col);
        cells.add(
          Positioned(
            left: left,
            top: top,
            width: width,
            height: height,
            child: _buildGridCell(address, width: width, height: height),
          ),
        );
        left += width;
      }

      top += height;
    }

    return cells;
  }

  Widget _buildGridCell(
    CellAddress address, {
    required double width,
    required double height,
  }) {
    return SpreadsheetCell(
      address: address,
      width: width,
      height: height,
      onSelected: () => _selectCell(address),
      onEditRequested: _beginEditing,
      onEditCommitted: _commitEdit,
      onEditCanceled: _cancelEditing,
      onFillDragStart: _startFillDrag,
      onFillDragUpdate: _updateFillDrag,
      onFillDragEnd: _endFillDrag,
      onSecondaryTapDown: (details) =>
          _showCellContextMenu(address, details.globalPosition),
    );
  }

  void _publishViewportStats({
    required int visibleRows,
    required int visibleColumns,
    required SheetViewportSlice rowSlice,
    required SheetViewportSlice columnSlice,
  }) {
    final nextStats = SheetViewportStats(
      visibleRows: visibleRows,
      visibleColumns: visibleColumns,
      renderedRows: rowSlice.renderedCount,
      renderedColumns: columnSlice.renderedCount,
      firstRenderedRow: rowSlice.firstIndex,
      lastRenderedRow: rowSlice.lastIndex,
      firstRenderedColumn: columnSlice.firstIndex,
      lastRenderedColumn: columnSlice.lastIndex,
    );
    if (_lastViewportStats == nextStats) return;
    _lastViewportStats = nextStats;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifier = ref.read(sheetViewportStatsProvider.notifier);
      if (notifier.state != nextStats) {
        notifier.state = nextStats;
      }
    });
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (ref.read(editingCellProvider) != null) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    final pressed = HardwareKeyboard.instance.logicalKeysPressed;
    final isShiftPressed =
        pressed.contains(LogicalKeyboardKey.shiftLeft) ||
        pressed.contains(LogicalKeyboardKey.shiftRight);
    final isShortcutPressed =
        pressed.contains(LogicalKeyboardKey.controlLeft) ||
        pressed.contains(LogicalKeyboardKey.controlRight) ||
        pressed.contains(LogicalKeyboardKey.metaLeft) ||
        pressed.contains(LogicalKeyboardKey.metaRight);

    if (isShortcutPressed && key == LogicalKeyboardKey.keyZ) {
      if (isShiftPressed) {
        ref.read(spreadsheetProvider.notifier).redo();
      } else {
        ref.read(spreadsheetProvider.notifier).undo();
      }
      return KeyEventResult.handled;
    }
    if (isShortcutPressed && key == LogicalKeyboardKey.keyY) {
      ref.read(spreadsheetProvider.notifier).redo();
      return KeyEventResult.handled;
    }
    if (isShortcutPressed && key == LogicalKeyboardKey.keyC) {
      final selection = ref.read(selectedCellProvider);
      if (selection != null) {
        unawaited(ref.read(toolbarControllerProvider).copy(selection));
      }
      return KeyEventResult.handled;
    }
    if (isShortcutPressed && key == LogicalKeyboardKey.keyX) {
      final selection = ref.read(selectedCellProvider);
      if (selection != null) {
        unawaited(ref.read(toolbarControllerProvider).cut(selection));
      }
      return KeyEventResult.handled;
    }
    if (isShortcutPressed && key == LogicalKeyboardKey.keyV) {
      final selection = ref.read(selectedCellProvider);
      if (selection != null) {
        unawaited(ref.read(toolbarControllerProvider).paste(selection));
      }
      return KeyEventResult.handled;
    }
    if (isShortcutPressed && _handleFormattingShortcut(key)) {
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.f2) {
      _beginEditing(ref.read(selectedCellProvider)?.start);
      return KeyEventResult.handled;
    }
    final editCharacter = _printableEditCharacter(event);
    if (editCharacter != null) {
      _beginEditing(
        ref.read(selectedCellProvider)?.start,
        initialValue: editCharacter,
      );
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      _moveSelection(rowDelta: -1, extend: isShiftPressed);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      _moveSelection(rowDelta: 1, extend: isShiftPressed);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      _moveSelection(colDelta: -1, extend: isShiftPressed);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      _moveSelection(colDelta: 1, extend: isShiftPressed);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter) {
      _moveSelection(rowDelta: isShiftPressed ? -1 : 1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.tab) {
      _moveSelection(colDelta: isShiftPressed ? -1 : 1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.delete ||
        key == LogicalKeyboardKey.backspace) {
      final selection = ref.read(selectedCellProvider);
      if (selection != null) {
        ref.read(spreadsheetProvider.notifier).clearCells(selection.getCells());
      }
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  bool _handleFormattingShortcut(LogicalKeyboardKey key) {
    final isFormattingKey =
        key == LogicalKeyboardKey.keyB ||
        key == LogicalKeyboardKey.keyI ||
        key == LogicalKeyboardKey.keyU;
    if (!isFormattingKey) return false;

    final selection = ref.read(selectedCellProvider);
    if (selection == null) return true;

    final toolbar = ref.read(toolbarControllerProvider);
    if (key == LogicalKeyboardKey.keyB) {
      toolbar.toggleBold(selection);
      return true;
    }
    if (key == LogicalKeyboardKey.keyI) {
      toolbar.toggleItalic(selection);
      return true;
    }
    if (key == LogicalKeyboardKey.keyU) {
      toolbar.toggleUnderline(selection);
      return true;
    }
    return false;
  }

  void _selectCell(CellAddress address, {bool applyFormatPainter = true}) {
    _focusNode.requestFocus();
    _setUserSelection(
      CellSelection(address),
      applyFormatPainter: applyFormatPainter,
    );
  }

  Future<void> _showCellContextMenu(
    CellAddress address,
    Offset globalPosition,
  ) async {
    _focusNode.requestFocus();
    ref.read(editingCellProvider.notifier).state = null;
    ref.read(editingCellDraftProvider.notifier).state = null;

    var selection = ref.read(selectedCellProvider);
    if (!(selection?.contains(address) ?? false)) {
      selection = CellSelection(address);
      ref.read(selectedCellProvider.notifier).state = selection;
    }
    final contextSelection = selection;
    if (contextSelection == null) return;

    final filterSummary = SheetColumnFilterSummaryBuilder.forColumn(
      column: address.col,
      filters: ref.read(filterProvider),
      filterRules: ref.read(sheetFilterRulesProvider),
    );
    final freezePane = ref.read(freezePanesProvider);
    final findValue = ref.read(spreadsheetProvider)[address]?.value.trim();
    final contextMenuState = SheetCellContextMenuState.forCell(
      clickedCell: address,
      hasColumnFilter: filterSummary.hasFilter,
      columnFilterDetail: filterSummary.detailLabel,
      hasFreezePane: freezePane != null,
      canFindThisValue: findValue != null && findValue.isNotEmpty,
    );
    final action = await showMenu<SheetCellContextAction>(
      context: context,
      position: RelativeRect.fromLTRB(
        globalPosition.dx,
        globalPosition.dy,
        globalPosition.dx,
        globalPosition.dy,
      ),
      constraints: const BoxConstraints(minWidth: 224, maxHeight: 560),
      items: SheetCellContextMenu.items(state: contextMenuState),
    );
    if (!mounted || action == null) return;

    await _handleCellContextAction(action, contextSelection, address);
  }

  Future<void> _handleCellContextAction(
    SheetCellContextAction action,
    CellSelection selection,
    CellAddress address,
  ) async {
    final toolbar = ref.read(toolbarControllerProvider);
    switch (action) {
      case SheetCellContextAction.edit:
        _beginEditing(selection.start);
      case SheetCellContextAction.copy:
        await toolbar.copy(selection);
      case SheetCellContextAction.cut:
        await toolbar.cut(selection);
      case SheetCellContextAction.paste:
        await toolbar.paste(selection);
      case SheetCellContextAction.clearContents:
        ref.read(spreadsheetProvider.notifier).clearCells(selection.getCells());
      case SheetCellContextAction.clearFormatting:
        toolbar.clearFormatting(selection);
      case SheetCellContextAction.insertRowAbove:
        toolbar.insertRowsAbove(selection);
      case SheetCellContextAction.insertRowBelow:
        toolbar.insertRowsBelow(selection);
      case SheetCellContextAction.insertColumnLeft:
        toolbar.insertColumnsLeft(selection);
      case SheetCellContextAction.insertColumnRight:
        toolbar.insertColumnsRight(selection);
      case SheetCellContextAction.deleteRow:
        toolbar.deleteRows(selection);
      case SheetCellContextAction.deleteColumn:
        toolbar.deleteColumns(selection);
      case SheetCellContextAction.sortAscending:
        _sortFromColumnHeader(address.col, ascending: true);
      case SheetCellContextAction.sortDescending:
        _sortFromColumnHeader(address.col, ascending: false);
      case SheetCellContextAction.keepOnlyValue:
        toolbar.keepOnlyCellValue(address);
      case SheetCellContextAction.excludeValue:
        toolbar.excludeCellValue(address);
      case SheetCellContextAction.clearColumnFilter:
        toolbar.removeFilterColumn(address.col);
      case SheetCellContextAction.findThisValue:
        _openFindReplaceForCell(address);
      case SheetCellContextAction.openSortFilter:
        _openSortFilterForColumn(address.col);
      case SheetCellContextAction.openInspector:
        _openSidebarPanel(SheetSidebarPanel.cellInspector);
      case SheetCellContextAction.openDataValidation:
        _openSidebarPanel(SheetSidebarPanel.dataValidation);
      case SheetCellContextAction.openChartBuilder:
        _openSidebarPanel(SheetSidebarPanel.chartBuilder);
      case SheetCellContextAction.openConditionalFormat:
        _openSidebarPanel(SheetSidebarPanel.conditionalFormat);
      case SheetCellContextAction.freezePanesHere:
        toolbar.freezePanesAt(CellSelection(address));
      case SheetCellContextAction.unfreezePanes:
        toolbar.unfreezePanes();
    }
  }

  void _openSidebarPanel(SheetSidebarPanel panel) {
    ref.read(activeSidebarPanelProvider.notifier).state = panel;
  }

  void _openFindReplaceForCell(CellAddress address) {
    final value = ref.read(spreadsheetProvider)[address]?.value.trim();
    if (value == null || value.isEmpty) return;
    ref.read(findReplaceQueryProvider.notifier).state = value;
    ref.read(findReplaceReplacementProvider.notifier).state = '';
    ref.read(findReplaceScopeProvider.notifier).state =
        SheetSearchScope.cellValues;
    ref.read(findReplaceCurrentIndexProvider.notifier).state = 0;
    _openSidebarPanel(SheetSidebarPanel.findReplace);
  }

  void _openSortFilterForColumn(int column) {
    _openSidebarPanel(SheetSidebarPanel.sortFilter);
    ref.read(selectedCellProvider.notifier).state = CellSelection(
      CellAddress(0, column),
      CellAddress(widget.rows - 1, column),
    );
  }

  void _selectRow(int row) {
    _focusNode.requestFocus();
    _setUserSelection(
      CellSelection(CellAddress(row, 0), CellAddress(row, widget.cols - 1)),
    );
  }

  void _selectColumn(int col) {
    _focusNode.requestFocus();
    _setUserSelection(
      CellSelection(CellAddress(0, col), CellAddress(widget.rows - 1, col)),
    );
  }

  void _handleColumnHeaderAction(int column, SheetColumnHeaderAction action) {
    switch (action) {
      case SheetColumnHeaderAction.insertLeft:
        _applyColumnSelectionAction(
          column,
          ref.read(toolbarControllerProvider).insertColumnsLeft,
        );
      case SheetColumnHeaderAction.insertRight:
        _applyColumnSelectionAction(
          column,
          ref.read(toolbarControllerProvider).insertColumnsRight,
        );
      case SheetColumnHeaderAction.deleteColumn:
        _applyColumnSelectionAction(
          column,
          ref.read(toolbarControllerProvider).deleteColumns,
        );
      case SheetColumnHeaderAction.hideColumn:
        _applyColumnSelectionAction(
          column,
          ref.read(toolbarControllerProvider).hideColumns,
        );
      case SheetColumnHeaderAction.unhideAdjacentColumns:
        _unhideAdjacentColumns(column);
      case SheetColumnHeaderAction.autoFitColumn:
        _autoFitColumn(column);
      case SheetColumnHeaderAction.sortAscending:
        _sortFromColumnHeader(column, ascending: true);
      case SheetColumnHeaderAction.sortDescending:
        _sortFromColumnHeader(column, ascending: false);
      case SheetColumnHeaderAction.filter:
        unawaited(_showColumnFilterDialog(column));
      case SheetColumnHeaderAction.clearFilter:
        ref.read(toolbarControllerProvider).removeFilterColumn(column);
      case SheetColumnHeaderAction.openSidebar:
        _openSortFilterForColumn(column);
    }
  }

  void _handleRowHeaderAction(int row, SheetRowHeaderAction action) {
    switch (action) {
      case SheetRowHeaderAction.insertAbove:
        _applyRowSelectionAction(
          row,
          ref.read(toolbarControllerProvider).insertRowsAbove,
        );
      case SheetRowHeaderAction.insertBelow:
        _applyRowSelectionAction(
          row,
          ref.read(toolbarControllerProvider).insertRowsBelow,
        );
      case SheetRowHeaderAction.deleteRow:
        _applyRowSelectionAction(
          row,
          ref.read(toolbarControllerProvider).deleteRows,
        );
      case SheetRowHeaderAction.hideRow:
        _applyRowSelectionAction(
          row,
          ref.read(toolbarControllerProvider).hideRows,
        );
      case SheetRowHeaderAction.unhideAdjacentRows:
        _unhideAdjacentRows(row);
      case SheetRowHeaderAction.autoFitRow:
        _autoFitRow(row);
    }
  }

  void _applyColumnSelectionAction(
    int column,
    void Function(CellSelection selection) action,
  ) {
    final selection = CellSelection(
      CellAddress(0, column),
      CellAddress(widget.rows - 1, column),
    );
    ref.read(selectedCellProvider.notifier).state = selection;
    action(selection);
  }

  void _applyRowSelectionAction(
    int row,
    void Function(CellSelection selection) action,
  ) {
    final selection = CellSelection(
      CellAddress(row, 0),
      CellAddress(row, widget.cols - 1),
    );
    ref.read(selectedCellProvider.notifier).state = selection;
    action(selection);
  }

  bool _hasHiddenAdjacentRow(int row, Map<int, RowConfig> rowConfig) {
    return (row > 0 && (rowConfig[row - 1]?.hidden ?? false)) ||
        (row < widget.rows - 1 && (rowConfig[row + 1]?.hidden ?? false));
  }

  bool _hasHiddenAdjacentColumn(
    int column,
    Map<int, ColumnConfig> columnConfig,
  ) {
    return (column > 0 && (columnConfig[column - 1]?.hidden ?? false)) ||
        (column < widget.cols - 1 &&
            (columnConfig[column + 1]?.hidden ?? false));
  }

  void _unhideAdjacentRows(int row) {
    final nextConfig = Map<int, RowConfig>.from(ref.read(rowConfigProvider));
    var changed = false;

    if (row > 0 && (nextConfig[row - 1]?.hidden ?? false)) {
      nextConfig[row - 1] = nextConfig[row - 1]!.copyWith(hidden: false);
      changed = true;
    }
    if (row < widget.rows - 1 && (nextConfig[row + 1]?.hidden ?? false)) {
      nextConfig[row + 1] = nextConfig[row + 1]!.copyWith(hidden: false);
      changed = true;
    }

    if (changed) ref.read(rowConfigProvider.notifier).state = nextConfig;
  }

  void _unhideAdjacentColumns(int column) {
    final nextConfig = Map<int, ColumnConfig>.from(
      ref.read(columnConfigProvider),
    );
    var changed = false;

    if (column > 0 && (nextConfig[column - 1]?.hidden ?? false)) {
      nextConfig[column - 1] = nextConfig[column - 1]!.copyWith(hidden: false);
      changed = true;
    }
    if (column < widget.cols - 1 && (nextConfig[column + 1]?.hidden ?? false)) {
      nextConfig[column + 1] = nextConfig[column + 1]!.copyWith(hidden: false);
      changed = true;
    }

    if (changed) ref.read(columnConfigProvider.notifier).state = nextConfig;
  }

  void _sortFromColumnHeader(int column, {required bool ascending}) {
    final selection = _selectionForColumnSort(column);
    ref.read(selectedCellProvider.notifier).state = selection;
    ref
        .read(toolbarControllerProvider)
        .sortSelection(selection, ascending: ascending, sortColumn: column);
  }

  CellSelection _selectionForColumnSort(int column) {
    final currentSelection = ref.read(selectedCellProvider);
    if (currentSelection != null &&
        currentSelection.isRange() &&
        currentSelection.spansColumn(column)) {
      return currentSelection;
    }

    final data = ref.read(spreadsheetProvider);
    if (data.isEmpty) {
      return CellSelection(
        CellAddress(0, column),
        CellAddress(widget.rows - 1, column),
      );
    }

    final maxRow = data.keys
        .map((address) => address.row)
        .reduce(math.max)
        .clamp(0, widget.rows - 1)
        .toInt();
    final maxCol = math
        .max(column, data.keys.map((address) => address.col).reduce(math.max))
        .clamp(0, widget.cols - 1)
        .toInt();

    return CellSelection(CellAddress(0, 0), CellAddress(maxRow, maxCol));
  }

  Future<void> _showColumnFilterDialog(int column) async {
    final filters = ref.read(filterProvider);
    final filterRules = ref.read(sheetFilterRulesProvider);
    final activeRules = SheetFilterEvaluator.effectiveRules(
      filters: filters,
      filterRules: filterRules,
    );
    final sortColumn = ref.read(sortColumnProvider);
    final result = await showDialog<SheetColumnFilterDialogResult>(
      context: context,
      builder: (context) => SheetColumnFilterDialog(
        column: column,
        initialRule: activeRules[column] ?? const SheetFilterRule(),
        values: SheetColumnFilterValueBuilder.build(
          column: column,
          cells: ref.read(spreadsheetProvider),
        ),
        isSorted: sortColumn == column,
        sortAscending: ref.read(sortAscendingProvider),
      ),
    );
    if (result == null) return;

    final toolbar = ref.read(toolbarControllerProvider);
    switch (result.action) {
      case SheetColumnFilterDialogAction.sortAscending:
        _sortFromColumnHeader(column, ascending: true);
        return;
      case SheetColumnFilterDialogAction.sortDescending:
        _sortFromColumnHeader(column, ascending: false);
        return;
      case SheetColumnFilterDialogAction.clearSort:
        toolbar.clearSort();
        break;
      case SheetColumnFilterDialogAction.clearFilter:
        toolbar.removeFilterColumn(column);
        break;
      case SheetColumnFilterDialogAction.applyFilter:
        final rule = result.rule;
        if (rule == null) {
          toolbar.removeFilterColumn(column);
        } else {
          toolbar.setFilterRule(column, rule);
        }
        break;
    }

    ref.read(selectedCellProvider.notifier).state = CellSelection(
      CellAddress(0, column),
      CellAddress(widget.rows - 1, column),
    );
  }

  void _selectAll() {
    _focusNode.requestFocus();
    _setUserSelection(
      CellSelection(
        CellAddress(0, 0),
        CellAddress(widget.rows - 1, widget.cols - 1),
      ),
    );
  }

  void _setUserSelection(
    CellSelection selection, {
    bool applyFormatPainter = true,
  }) {
    ref.read(editingCellProvider.notifier).state = null;
    ref.read(editingCellDraftProvider.notifier).state = null;
    ref.read(selectedCellProvider.notifier).state = selection;
    if (applyFormatPainter) {
      _applyFormatPainter(selection);
    }
  }

  void _applyFormatPainter(CellSelection selection) {
    ref.read(sheetFormatPainterControllerProvider).applyTo(selection);
  }

  void _moveSelection({
    int rowDelta = 0,
    int colDelta = 0,
    bool extend = false,
  }) {
    final selection = ref.read(selectedCellProvider);
    final anchor = selection?.start ?? CellAddress(0, 0);
    final current = selection?.end ?? anchor;
    final next = CellAddress(
      _clampIndex(current.row + rowDelta, widget.rows - 1),
      _clampIndex(current.col + colDelta, widget.cols - 1),
    );

    ref.read(selectedCellProvider.notifier).state = extend
        ? CellSelection(anchor, next)
        : CellSelection(next);
    ref.read(editingCellProvider.notifier).state = null;
    ref.read(editingCellDraftProvider.notifier).state = null;
    _scrollCellIntoView(next);
  }

  void _handleNavigationRequest(SheetNavigationRequest request) {
    final selection = request.selection;
    final clampedSelection = CellSelection(
      _clampAddress(selection.start),
      selection.end == null ? null : _clampAddress(selection.end!),
    );

    if (clampedSelection.label != selection.label) {
      ref.read(selectedCellProvider.notifier).state = clampedSelection;
    }

    _focusNode.requestFocus();
    _scrollCellIntoView(clampedSelection.start);
  }

  void _beginEditing(CellAddress? address, {String? initialValue}) {
    if (address == null) return;
    ref.read(selectedCellProvider.notifier).state = CellSelection(address);
    ref.read(editingCellDraftProvider.notifier).state = initialValue;
    ref.read(editingCellProvider.notifier).state = address;
    _scrollCellIntoView(address);
  }

  void _commitEdit(
    CellAddress address,
    String value,
    CellEditCommitIntent intent,
  ) {
    ref.read(spreadsheetProvider.notifier).updateCellValue(address, value);
    ref.read(editingCellProvider.notifier).state = null;
    ref.read(editingCellDraftProvider.notifier).state = null;
    _focusNode.requestFocus();
    _moveAfterCommit(address, intent);
  }

  void _cancelEditing() {
    ref.read(editingCellProvider.notifier).state = null;
    ref.read(editingCellDraftProvider.notifier).state = null;
    _focusNode.requestFocus();
  }

  void _startFillDrag(DragStartDetails details) {
    _fillSourceSelection = ref.read(selectedCellProvider);
    _fillDragOffset = Offset.zero;
    ref.read(fillPreviewProvider.notifier).state = null;
  }

  void _updateFillDrag(DragUpdateDetails details) {
    final source = _fillSourceSelection;
    if (source == null) return;

    _fillDragOffset += details.delta;
    final rowConfig = ref.read(rowConfigProvider);
    final columnConfig = ref.read(columnConfigProvider);
    final zoom = ref.read(zoomLevelProvider);
    final preview = _fillPreviewForDrag(
      source,
      _fillDragOffset,
      rowConfig,
      columnConfig,
      zoom,
    );

    ref.read(fillPreviewProvider.notifier).state = preview;
  }

  void _endFillDrag(DragEndDetails details) {
    final source = _fillSourceSelection;
    final preview = ref.read(fillPreviewProvider);
    _fillSourceSelection = null;
    _fillDragOffset = Offset.zero;
    ref.read(fillPreviewProvider.notifier).state = null;

    if (source == null || preview == null) return;

    final fillCells = SheetFillSeries.buildFill(
      sourceSelection: source,
      targetSelection: preview,
      cells: ref.read(spreadsheetProvider),
    );
    ref.read(spreadsheetProvider.notifier).fillCells(fillCells);
    if (fillCells.isNotEmpty) {
      ref.read(selectedCellProvider.notifier).state = preview;
    }
  }

  CellSelection? _fillPreviewForDrag(
    CellSelection source,
    Offset dragOffset,
    Map<int, RowConfig> rowConfig,
    Map<int, ColumnConfig> columnConfig,
    double zoom,
  ) {
    final isVertical = dragOffset.dy.abs() >= dragOffset.dx.abs();

    if (isVertical) {
      final visibleRows = SheetViewportMetrics.visibleRows(
        widget.rows,
        rowConfig,
      );
      final targetRow = _targetIndexAfterDrag(
        boundaryIndex: dragOffset.dy >= 0 ? source.maxRow : source.minRow,
        delta: dragOffset.dy,
        visibleIndexes: visibleRows,
        extentFor: (row) =>
            SheetViewportMetrics.rowHeight(row, rowConfig, zoom),
      );
      if (targetRow == null) return null;

      return CellSelection(
        CellAddress(math.min(source.minRow, targetRow), source.minCol),
        CellAddress(math.max(source.maxRow, targetRow), source.maxCol),
      );
    }

    final visibleColumns = SheetViewportMetrics.visibleColumns(
      widget.cols,
      columnConfig,
    );
    final targetCol = _targetIndexAfterDrag(
      boundaryIndex: dragOffset.dx >= 0 ? source.maxCol : source.minCol,
      delta: dragOffset.dx,
      visibleIndexes: visibleColumns,
      extentFor: (col) =>
          SheetViewportMetrics.columnWidth(col, columnConfig, zoom),
    );
    if (targetCol == null) return null;

    return CellSelection(
      CellAddress(source.minRow, math.min(source.minCol, targetCol)),
      CellAddress(source.maxRow, math.max(source.maxCol, targetCol)),
    );
  }

  int? _targetIndexAfterDrag({
    required int boundaryIndex,
    required double delta,
    required List<int> visibleIndexes,
    required double Function(int index) extentFor,
  }) {
    if (delta == 0) return null;

    final movingForward = delta > 0;
    final distance = delta.abs();
    final candidates = movingForward
        ? visibleIndexes.where((index) => index > boundaryIndex)
        : visibleIndexes.reversed.where((index) => index < boundaryIndex);

    var accumulated = 0.0;
    int? target;
    for (final index in candidates) {
      final extent = extentFor(index);
      accumulated += extent;
      if (distance >= accumulated - (extent / 2)) {
        target = index;
      } else {
        break;
      }
    }

    return target;
  }

  void _moveAfterCommit(CellAddress address, CellEditCommitIntent intent) {
    final next = switch (intent) {
      CellEditCommitIntent.stay => address,
      CellEditCommitIntent.nextRow => CellAddress(
        _clampIndex(address.row + 1, widget.rows - 1),
        address.col,
      ),
      CellEditCommitIntent.previousRow => CellAddress(
        _clampIndex(address.row - 1, widget.rows - 1),
        address.col,
      ),
      CellEditCommitIntent.nextColumn => CellAddress(
        address.row,
        _clampIndex(address.col + 1, widget.cols - 1),
      ),
      CellEditCommitIntent.previousColumn => CellAddress(
        address.row,
        _clampIndex(address.col - 1, widget.cols - 1),
      ),
    };

    ref.read(selectedCellProvider.notifier).state = CellSelection(next);
    _scrollCellIntoView(next);
  }

  void _resizeColumn(int column, double delta, double zoom) {
    if (zoom == 0 || delta == 0) return;
    final configs = ref.read(columnConfigProvider);
    final currentWidth =
        configs[column]?.width ?? KySheetMetrics.defaultColumnWidth;
    _setColumnWidth(column, currentWidth + (delta / zoom));
  }

  void _resizeRow(int row, double delta, double zoom) {
    if (zoom == 0 || delta == 0) return;
    final configs = ref.read(rowConfigProvider);
    final currentHeight =
        configs[row]?.height ?? KySheetMetrics.defaultRowHeight;
    _setRowHeight(row, currentHeight + (delta / zoom));
  }

  void _autoFitColumn(int column) {
    final data = ref.read(spreadsheetProvider);
    var nextWidth = KySheetMetrics.minColumnWidth;

    for (final entry in data.entries) {
      if (entry.key.col != column || entry.value.value.isEmpty) continue;

      final textLength = entry.value.value.length;
      final fontSize = entry.value.style.fontSize;
      final isBold = entry.value.style.bold;
      final estimatedWidth =
          textLength * (fontSize / 1.9) + (isBold ? 12 : 0) + 28.0;
      nextWidth = nextWidth < estimatedWidth ? estimatedWidth : nextWidth;
    }

    _setColumnWidth(column, nextWidth);
  }

  void _autoFitRow(int row) {
    final data = ref.read(spreadsheetProvider);
    var nextHeight = KySheetMetrics.defaultRowHeight;

    for (final entry in data.entries) {
      if (entry.key.row != row || entry.value.value.isEmpty) continue;

      final lineCount = entry.value.value.split('\n').length;
      final fontSize = entry.value.style.fontSize;
      final estimatedHeight = (lineCount * (fontSize + 8.0)) + 10.0;
      nextHeight = nextHeight < estimatedHeight ? estimatedHeight : nextHeight;
    }

    _setRowHeight(row, nextHeight);
  }

  void _setColumnWidth(int column, double width) {
    final nextWidth = width
        .clamp(KySheetMetrics.minColumnWidth, KySheetMetrics.maxColumnWidth)
        .toDouble();
    final nextConfig = Map<int, ColumnConfig>.from(
      ref.read(columnConfigProvider),
    );
    nextConfig[column] = (nextConfig[column] ?? ColumnConfig(index: column))
        .copyWith(width: nextWidth);
    ref.read(columnConfigProvider.notifier).state = nextConfig;
  }

  void _setRowHeight(int row, double height) {
    final nextHeight = height
        .clamp(KySheetMetrics.minRowHeight, KySheetMetrics.maxRowHeight)
        .toDouble();
    final nextConfig = Map<int, RowConfig>.from(ref.read(rowConfigProvider));
    nextConfig[row] = (nextConfig[row] ?? RowConfig(index: row)).copyWith(
      height: nextHeight,
    );
    ref.read(rowConfigProvider.notifier).state = nextConfig;
  }

  String? _printableEditCharacter(KeyDownEvent event) {
    final pressed = HardwareKeyboard.instance.logicalKeysPressed;
    final hasShortcutModifier =
        pressed.contains(LogicalKeyboardKey.controlLeft) ||
        pressed.contains(LogicalKeyboardKey.controlRight) ||
        pressed.contains(LogicalKeyboardKey.metaLeft) ||
        pressed.contains(LogicalKeyboardKey.metaRight) ||
        pressed.contains(LogicalKeyboardKey.altLeft) ||
        pressed.contains(LogicalKeyboardKey.altRight);

    if (hasShortcutModifier) return null;

    final character = event.character;
    if (character == null || character.isEmpty || character.length != 1) {
      return null;
    }
    if (character.codeUnitAt(0) < 32) return null;
    return character;
  }

  void _scrollCellIntoView(CellAddress address) {
    final zoom = ref.read(zoomLevelProvider);
    final rowConfig = ref.read(rowConfigProvider);
    final columnConfig = ref.read(columnConfigProvider);
    final freezePane = ref.read(freezePanesProvider);
    final visibleRows = SheetFilterEvaluator.visibleRows(
      rows: SheetViewportMetrics.visibleRows(widget.rows, rowConfig),
      filters: ref.read(filterProvider),
      filterRules: ref.read(sheetFilterRulesProvider),
      cells: ref.read(spreadsheetProvider),
    );
    final visibleColumns = SheetViewportMetrics.visibleColumns(
      widget.cols,
      columnConfig,
    );
    final freezeLayout = SheetFreezePaneLayout.from(
      freezePane: freezePane,
      visibleRows: visibleRows,
      visibleColumns: visibleColumns,
    );
    final frozenHeight = _totalRowHeight(
      freezeLayout.frozenRows,
      rowConfig,
      zoom,
    );
    final frozenWidth = _totalColumnWidth(
      freezeLayout.frozenColumns,
      columnConfig,
      zoom,
    );
    final rowTop =
        SheetViewportMetrics.rowOffset(address.row, rowConfig, zoom) -
        frozenHeight;
    final colLeft =
        SheetViewportMetrics.columnOffset(address.col, columnConfig, zoom) -
        frozenWidth;

    if (freezePane == null || address.row >= freezePane.row) {
      _scrollAxisIntoView(
        widget.verticalController,
        rowTop,
        SheetViewportMetrics.rowHeight(address.row, rowConfig, zoom),
      );
    }
    if (freezePane == null || address.col >= freezePane.col) {
      _scrollAxisIntoView(
        widget.horizontalController,
        colLeft,
        SheetViewportMetrics.columnWidth(address.col, columnConfig, zoom),
      );
    }
  }

  void _scrollAxisIntoView(
    ScrollController controller,
    double leading,
    double size,
  ) {
    if (!controller.hasClients) return;
    final position = controller.position;
    final visibleStart = controller.offset;
    final visibleEnd = visibleStart + position.viewportDimension;
    double? nextOffset;

    if (leading < visibleStart) {
      nextOffset = leading;
    } else if (leading + size > visibleEnd) {
      nextOffset = leading + size - position.viewportDimension;
    }

    if (nextOffset != null) {
      _jumpTo(controller, nextOffset);
    }
  }

  CellAddress? _cellFromContentPosition(
    Offset position,
    List<int> visibleRows,
    List<int> visibleColumns,
    Map<int, RowConfig> rowConfig,
    Map<int, ColumnConfig> columnConfig,
    double zoom,
  ) {
    final row = _indexFromOffset(
      position.dy,
      visibleRows,
      (index) => SheetViewportMetrics.rowHeight(index, rowConfig, zoom),
    );
    final col = _indexFromOffset(
      position.dx,
      visibleColumns,
      (index) => SheetViewportMetrics.columnWidth(index, columnConfig, zoom),
    );

    if (row == null || col == null) return null;
    return CellAddress(row, col);
  }

  int? _indexFromOffset(
    double offset,
    List<int> indexes,
    double Function(int index) extentFor,
  ) {
    var cursor = 0.0;
    for (final index in indexes) {
      final extent = extentFor(index);
      if (offset >= cursor && offset < cursor + extent) {
        return index;
      }
      cursor += extent;
    }
    return null;
  }

  double _scrollOffset(ScrollController controller) {
    return controller.hasClients ? controller.offset : 0;
  }

  double _boundedExtent(double extent) {
    return extent.isFinite ? extent.clamp(0, double.infinity).toDouble() : 0;
  }

  double _totalRowHeight(
    List<int> rows,
    Map<int, RowConfig> rowConfig,
    double zoom,
  ) {
    return rows.fold(
      0,
      (sum, row) => sum + SheetViewportMetrics.rowHeight(row, rowConfig, zoom),
    );
  }

  double _totalColumnWidth(
    List<int> columns,
    Map<int, ColumnConfig> columnConfig,
    double zoom,
  ) {
    return columns.fold(
      0,
      (sum, column) =>
          sum + SheetViewportMetrics.columnWidth(column, columnConfig, zoom),
    );
  }

  int _clampIndex(int value, int max) {
    return value.clamp(0, max).toInt();
  }

  CellAddress _clampAddress(CellAddress address) {
    return CellAddress(
      _clampIndex(address.row, widget.rows - 1),
      _clampIndex(address.col, widget.cols - 1),
    );
  }
}
