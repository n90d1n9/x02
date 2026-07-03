import 'cell/cell_address.dart';
import 'sheet_filter_rule.dart';
import 'workbook_sheet.dart';

/// Presentation-ready labels for spreadsheet status bar indicators.
class SheetStatusIndicatorSummary {
  const SheetStatusIndicatorSummary({
    required this.activeSheetName,
    required this.activeSheetIndex,
    required this.sheetCount,
    required this.activeFilterCount,
    required this.sortColumn,
    required this.sortAscending,
    this.editingCell,
  });

  /// Builds status labels from workbook, edit, filter, and sort state.
  factory SheetStatusIndicatorSummary.fromState({
    required SheetWorkbook workbook,
    required Map<int, String> filters,
    required Map<int, SheetFilterRule> filterRules,
    required int? sortColumn,
    required bool sortAscending,
    CellAddress? editingCell,
  }) {
    final visibleSheets = workbook.visibleSheets;
    final sheetCount = visibleSheets.length;
    final rawIndex = visibleSheets.indexWhere(
      (sheet) => sheet.id == workbook.activeSheetId,
    );
    final activeSheetIndex = _boundedSheetIndex(rawIndex, sheetCount);
    final activeSheetName = sheetCount == 0
        ? 'No sheet'
        : visibleSheets[activeSheetIndex].name;

    return SheetStatusIndicatorSummary(
      activeSheetName: activeSheetName,
      activeSheetIndex: activeSheetIndex,
      sheetCount: sheetCount,
      activeFilterCount: _countActiveFilters(filters, filterRules),
      sortColumn: sortColumn,
      sortAscending: sortAscending,
      editingCell: editingCell,
    );
  }

  /// Active sheet display name.
  final String activeSheetName;

  /// Zero-based active sheet index.
  final int activeSheetIndex;

  /// Total workbook sheet count.
  final int sheetCount;

  /// Number of columns with active filters.
  final int activeFilterCount;

  /// Zero-based sorted column, when sorting is active.
  final int? sortColumn;

  /// Whether the active sort is ascending.
  final bool sortAscending;

  /// Cell currently being edited, when inline edit mode is active.
  final CellAddress? editingCell;

  bool get isEditing => editingCell != null;

  bool get hasFilters => activeFilterCount > 0;

  bool get hasSort => sortColumn != null;

  int get activeSheetNumber => sheetCount == 0 ? 0 : activeSheetIndex + 1;

  String get modeValue {
    return isEditing ? 'Editing ${editingCell!.label}' : 'Ready';
  }

  String get modeTooltip {
    return isEditing
        ? 'Editing cell ${editingCell!.label}'
        : 'Ready for spreadsheet input';
  }

  String get sheetValue => '$activeSheetNumber/$sheetCount';

  String get sheetTooltip {
    return 'Active sheet $activeSheetName ($activeSheetNumber of $sheetCount)';
  }

  String get filterValue => '$activeFilterCount active';

  String get filterTooltip {
    final suffix = activeFilterCount == 1 ? 'filter' : 'filters';
    return '$activeFilterCount active $suffix';
  }

  String get sortValue {
    if (sortColumn == null) return 'None';
    final columnLabel = CellAddress.colToLabel(sortColumn!);
    return '$columnLabel ${sortAscending ? 'A-Z' : 'Z-A'}';
  }

  String get sortTooltip {
    if (sortColumn == null) return 'No active sort';
    final columnLabel = CellAddress.colToLabel(sortColumn!);
    final direction = sortAscending ? 'ascending' : 'descending';
    return 'Sorted by column $columnLabel $direction';
  }

  static int _boundedSheetIndex(int rawIndex, int sheetCount) {
    if (sheetCount <= 0 || rawIndex < 0) return 0;
    if (rawIndex >= sheetCount) return sheetCount - 1;
    return rawIndex;
  }

  static int _countActiveFilters(
    Map<int, String> filters,
    Map<int, SheetFilterRule> filterRules,
  ) {
    final activeColumns = <int>{
      for (final entry in filters.entries)
        if (entry.value.trim().isNotEmpty) entry.key,
      for (final entry in filterRules.entries)
        if (entry.value.isActive) entry.key,
    };

    return activeColumns.length;
  }
}
