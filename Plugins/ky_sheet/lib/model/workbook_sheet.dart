import 'package:flutter/material.dart';

import 'cell/cell_address.dart';
import 'cell/cell_data.dart';
import 'column_config.dart';
import 'conditional_format_rule.dart';
import 'row_config.dart';
import 'sheet_filter_rule.dart';
import 'sheet_named_range.dart';
import 'sheet_table.dart';

/// Immutable workbook state containing ordered sheets and the active sheet id.
class SheetWorkbook {
  const SheetWorkbook({required this.sheets, required this.activeSheetId});

  factory SheetWorkbook.initial() {
    return const SheetWorkbook(
      sheets: [WorkbookSheet(id: 'sheet-1', name: 'Sheet1')],
      activeSheetId: 'sheet-1',
    );
  }

  final List<WorkbookSheet> sheets;
  final String activeSheetId;

  /// Sheets currently visible in tab strips and sheet switchers.
  List<WorkbookSheet> get visibleSheets {
    return [
      for (final sheet in sheets)
        if (!sheet.hidden) sheet,
    ];
  }

  /// Sheets hidden from tab strips but retained in the workbook.
  List<WorkbookSheet> get hiddenSheets {
    return [
      for (final sheet in sheets)
        if (sheet.hidden) sheet,
    ];
  }

  WorkbookSheet get activeSheet {
    return sheets.firstWhere(
      (sheet) => sheet.id == activeSheetId,
      orElse: () => sheets.first,
    );
  }

  int get activeIndex {
    return sheets.indexWhere((sheet) => sheet.id == activeSheetId);
  }

  SheetWorkbook copyWith({List<WorkbookSheet>? sheets, String? activeSheetId}) {
    return SheetWorkbook(
      sheets: sheets ?? this.sheets,
      activeSheetId: activeSheetId ?? this.activeSheetId,
    );
  }
}

/// Immutable workbook sheet with grid cells, metadata, and tab presentation.
class WorkbookSheet {
  const WorkbookSheet({
    required this.id,
    required this.name,
    this.tabColor,
    this.hidden = false,
    this.cells = const {},
    this.metadata = const SheetMetadata(),
  });

  final String id;
  final String name;
  final Color? tabColor;

  /// Whether this sheet is hidden from workbook navigation tabs.
  final bool hidden;
  final Map<CellAddress, CellData> cells;
  final SheetMetadata metadata;

  WorkbookSheet copyWith({
    String? id,
    String? name,
    Color? tabColor,
    bool clearTabColor = false,
    bool? hidden,
    Map<CellAddress, CellData>? cells,
    SheetMetadata? metadata,
  }) {
    return WorkbookSheet(
      id: id ?? this.id,
      name: name ?? this.name,
      tabColor: clearTabColor ? null : tabColor ?? this.tabColor,
      hidden: hidden ?? this.hidden,
      cells: cells ?? this.cells,
      metadata: metadata ?? this.metadata,
    );
  }

  WorkbookSheet clone({required String id, required String name}) {
    return WorkbookSheet(
      id: id,
      name: name,
      tabColor: tabColor,
      hidden: hidden,
      cells: Map<CellAddress, CellData>.from(cells),
      metadata: metadata.copy(),
    );
  }
}

/// Per-sheet workbook metadata that is restored when a sheet becomes active.
class SheetMetadata {
  const SheetMetadata({
    this.conditionalFormatRules = const [],
    this.namedRanges = const [],
    this.rowConfig = const {},
    this.columnConfig = const {},
    this.filters = const {},
    this.filterRules = const {},
    this.tables = const [],
    this.sortColumn,
    this.sortAscending = true,
    this.freezePane,
    this.zoom = 1.0,
  });

  final List<ConditionalFormatRule> conditionalFormatRules;
  final List<SheetNamedRange> namedRanges;
  final Map<int, RowConfig> rowConfig;
  final Map<int, ColumnConfig> columnConfig;
  final Map<int, String> filters;
  final Map<int, SheetFilterRule> filterRules;
  final List<SheetTable> tables;
  final int? sortColumn;
  final bool sortAscending;
  final CellAddress? freezePane;
  final double zoom;

  SheetMetadata copy() {
    return SheetMetadata(
      conditionalFormatRules: List<ConditionalFormatRule>.from(
        conditionalFormatRules,
      ),
      namedRanges: List<SheetNamedRange>.from(namedRanges),
      rowConfig: Map<int, RowConfig>.from(rowConfig),
      columnConfig: Map<int, ColumnConfig>.from(columnConfig),
      filters: Map<int, String>.from(filters),
      filterRules: Map<int, SheetFilterRule>.from(filterRules),
      tables: List<SheetTable>.from(tables),
      sortColumn: sortColumn,
      sortAscending: sortAscending,
      freezePane: freezePane,
      zoom: zoom,
    );
  }
}
