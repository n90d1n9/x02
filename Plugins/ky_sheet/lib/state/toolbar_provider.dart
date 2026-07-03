import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/cell/cell_address.dart';
import '../model/cell/cell_data.dart';
import '../model/cell/cell_selection.dart';
import '../model/cell/cell_style.dart';
import '../model/cell/cell_validation.dart';
import '../model/sheet_filter_rule.dart';
import '../model/sheet_table.dart';
import '../utils/sheet_cell_quick_filter_rule_builder.dart';
import '../utils/sheet_clipboard_codec.dart';
import '../utils/sheet_function_insert_builder.dart';
import 'sheet_table_provider.dart';
import 'spreadsheet_provider.dart';

final toolbarControllerProvider = Provider((ref) {
  return ToolbarController(ref);
});

/// Coordinates spreadsheet toolbar commands against the active sheet state.
class ToolbarController {
  final Ref ref;

  ToolbarController(this.ref);

  void _formatSelection(
    CellSelection selection,
    CellStyle Function(CellData current) buildStyle, {
    String description = 'Format cells',
    bool createMissing = true,
  }) {
    ref
        .read(spreadsheetProvider.notifier)
        .updateCellStyles(
          selection.getCells(),
          buildStyle,
          description: description,
          createMissing: createMissing,
        );
  }

  void _updateSelectionCells(
    CellSelection selection,
    CellData Function(CellAddress address, CellData current) buildCell, {
    String description = 'Update cells',
    bool createMissing = true,
    bool recalculate = true,
  }) {
    ref
        .read(spreadsheetProvider.notifier)
        .updateCells(
          selection.getCells(),
          buildCell,
          description: description,
          createMissing: createMissing,
          recalculate: recalculate,
        );
  }

  void toggleBold(CellSelection selection) {
    _formatSelection(
      selection,
      (current) => current.style.copyWith(bold: !current.style.bold),
      description: 'Toggle bold',
    );
  }

  void toggleItalic(CellSelection selection) {
    _formatSelection(
      selection,
      (current) => current.style.copyWith(italic: !current.style.italic),
      description: 'Toggle italic',
    );
  }

  void toggleUnderline(CellSelection selection) {
    _formatSelection(
      selection,
      (current) => current.style.copyWith(underline: !current.style.underline),
      description: 'Toggle underline',
    );
  }

  void setAlign(CellSelection selection, TextAlign align) {
    _formatSelection(
      selection,
      (current) => current.style.copyWith(align: align),
      description: 'Set alignment',
    );
  }

  void setBackground(CellSelection selection, Color color) {
    _formatSelection(
      selection,
      (current) => current.style.copyWith(backgroundColor: color),
      description: 'Set fill color',
    );
  }

  void formatAsTable(CellSelection selection) {
    ref.read(sheetTablesProvider.notifier).createFromSelection(selection);
  }

  Future<void> copy(CellSelection selection) async {
    final cells = selection.getCells();
    final data = ref.read(spreadsheetProvider);
    final clipboard = <CellAddress, CellData>{};
    final clipboardText = SheetClipboardCodec.encodeSelection(selection, data);

    final minRow = cells.map((c) => c.row).reduce(math.min);
    final minCol = cells.map((c) => c.col).reduce(math.min);

    for (final addr in cells) {
      final cellData = data[addr];
      if (cellData != null) {
        clipboard[CellAddress(addr.row - minRow, addr.col - minCol)] = cellData;
      }
    }
    ref.read(clipboardProvider.notifier).state = clipboard;
    ref.read(systemClipboardTextProvider.notifier).state = clipboardText;
    await Clipboard.setData(ClipboardData(text: clipboardText));
  }

  Future<void> cut(CellSelection selection) async {
    await copy(selection);
    final cells = selection.getCells();
    ref.read(spreadsheetProvider.notifier).clearCells(cells);
  }

  Future<void> paste(CellSelection selection) async {
    final clipboard = ref.read(clipboardProvider);
    final lastWrittenText = ref.read(systemClipboardTextProvider);
    final systemData = await Clipboard.getData(Clipboard.kTextPlain);
    final systemText = systemData?.text;

    if (systemText != null &&
        systemText.isNotEmpty &&
        (clipboard == null || systemText != lastWrittenText)) {
      final rows = SheetClipboardCodec.decodeRows(systemText);
      if (rows.isNotEmpty) {
        ref
            .read(spreadsheetProvider.notifier)
            .pasteCellValues(rows, selection.start);
        ref.read(systemClipboardTextProvider.notifier).state = systemText;
        return;
      }
    }

    if (clipboard == null) return;
    ref
        .read(spreadsheetProvider.notifier)
        .pasteCells(clipboard, selection.start);
  }

  void toggleWrapText(CellSelection selection) {
    _formatSelection(
      selection,
      (current) => current.style.copyWith(wrapText: !current.style.wrapText),
      description: 'Toggle wrap text',
    );
  }

  void mergeCells(CellSelection selection) {
    if (!selection.isRange()) return;

    final cells = selection.getCells();
    final data = ref.read(spreadsheetProvider);
    final values = cells
        .map((addr) => data[addr]?.value ?? '')
        .where((v) => v.isNotEmpty)
        .join(' ');

    final startData = data[selection.start] ?? CellData();
    final replacements = <CellAddress, CellData?>{
      selection.start: startData.copyWith(value: values, clearFormula: true),
    };
    for (int i = 1; i < cells.length; i++) {
      replacements[cells[i]] = null;
    }

    ref
        .read(spreadsheetProvider.notifier)
        .replaceCells(replacements, description: 'Merge cells');
  }

  void insertFunction(CellAddress addr, String function) {
    final formula = SheetFunctionInsertBuilder.buildFormula(
      functionName: function,
      target: addr,
      cells: ref.read(spreadsheetProvider),
    );
    ref.read(spreadsheetProvider.notifier).updateCellValue(addr, formula);
  }

  // Font
  void setFontSize(CellSelection selection, double size) {
    _formatSelection(
      selection,
      (current) => current.style.copyWith(fontSize: size),
      description: 'Set font size',
    );
  }

  void increaseFontSize(CellSelection selection) {
    _formatSelection(
      selection,
      (current) => current.style.copyWith(fontSize: current.style.fontSize + 1),
      description: 'Increase font size',
    );
  }

  void decreaseFontSize(CellSelection selection) {
    _formatSelection(
      selection,
      (current) => current.style.copyWith(
        fontSize: math.max(8, current.style.fontSize - 1).toDouble(),
      ),
      description: 'Decrease font size',
    );
  }

  // Border Management
  void setBorder(
    CellSelection selection, {
    bool top = false,
    bool bottom = false,
    bool left = false,
    bool right = false,
  }) {
    _formatSelection(
      selection,
      (current) => current.style.copyWith(
        borderTop: top,
        borderBottom: bottom,
        borderLeft: left,
        borderRight: right,
      ),
      description: top || bottom || left || right
          ? 'Set borders'
          : 'Clear borders',
    );
  }

  void setAllBorders(CellSelection selection) {
    setBorder(selection, top: true, bottom: true, left: true, right: true);
  }

  void clearBorders(CellSelection selection) {
    setBorder(selection);
  }

  //--------------
  /// Insert rows above selection
  void insertRowsAbove(CellSelection selection) {
    final row = selection.start.row;
    final count = selection.isRange()
        ? selection.end!.row - selection.start.row + 1
        : 1;
    ref.read(spreadsheetProvider.notifier).insertRows(row, count);
  }

  /// Insert rows below selection
  void insertRowsBelow(CellSelection selection) {
    final row = selection.start.row;
    final count = selection.isRange()
        ? selection.end!.row - selection.start.row + 1
        : 1;
    ref.read(spreadsheetProvider.notifier).insertRows(row + 1, count);
  }

  /// Delete selected rows
  void deleteRows(CellSelection selection) {
    final startRow = selection.start.row;
    final endRow = selection.isRange()
        ? selection.end!.row
        : selection.start.row;
    ref.read(spreadsheetProvider.notifier).deleteRows(startRow, endRow);
  }

  /// Insert columns left of selection
  void insertColumnsLeft(CellSelection selection) {
    final col = selection.start.col;
    final count = selection.isRange()
        ? selection.end!.col - selection.start.col + 1
        : 1;
    ref.read(spreadsheetProvider.notifier).insertColumns(col, count);
  }

  /// Insert columns right of selection
  void insertColumnsRight(CellSelection selection) {
    final col = selection.start.col;
    final count = selection.isRange()
        ? selection.end!.col - selection.start.col + 1
        : 1;
    ref.read(spreadsheetProvider.notifier).insertColumns(col + 1, count);
  }

  /// Delete selected columns
  void deleteColumns(CellSelection selection) {
    final startCol = selection.start.col;
    final endCol = selection.isRange()
        ? selection.end!.col
        : selection.start.col;
    ref.read(spreadsheetProvider.notifier).deleteColumns(startCol, endCol);
  }

  /// Auto-fit column width
  void autoFitColumn(CellSelection selection) {
    final col = selection.start.col;
    ref.read(spreadsheetProvider.notifier).autoFitColumn(col, ref);
  }

  /// Auto-fit row height
  void autoFitRow(CellSelection selection) {
    final row = selection.start.row;
    ref.read(spreadsheetProvider.notifier).autoFitRow(row, ref);
  }

  /// Hide selected rows
  void hideRows(CellSelection selection) {
    final startRow = selection.start.row;
    final endRow = selection.isRange()
        ? selection.end!.row
        : selection.start.row;
    for (int row = startRow; row <= endRow; row++) {
      ref.read(spreadsheetProvider.notifier).hideRow(row, ref);
    }
  }

  /// Show selected rows
  void showRows(CellSelection selection) {
    final startRow = selection.start.row;
    final endRow = selection.isRange()
        ? selection.end!.row
        : selection.start.row;
    for (int row = startRow; row <= endRow; row++) {
      ref.read(spreadsheetProvider.notifier).showRow(row, ref);
    }
  }

  /// Hide selected columns
  void hideColumns(CellSelection selection) {
    final startCol = selection.start.col;
    final endCol = selection.isRange()
        ? selection.end!.col
        : selection.start.col;
    for (int col = startCol; col <= endCol; col++) {
      ref.read(spreadsheetProvider.notifier).hideColumn(col, ref);
    }
  }

  /// Show selected columns
  void showColumns(CellSelection selection) {
    final startCol = selection.start.col;
    final endCol = selection.isRange()
        ? selection.end!.col
        : selection.start.col;
    for (int col = startCol; col <= endCol; col++) {
      ref.read(spreadsheetProvider.notifier).showColumn(col, ref);
    }
  }

  //----------------------
  // Insert

  void insertRowAbove(CellSelection selection) {
    final row = selection.start.row;
    ref.read(spreadsheetProvider.notifier).insertRow(row);
  }

  void insertRowBelow(CellSelection selection) {
    final row = selection.start.row;
    ref.read(spreadsheetProvider.notifier).insertRow(row + 1);
  }

  void deleteRow(CellSelection selection) {
    final row = selection.start.row;
    ref.read(spreadsheetProvider.notifier).deleteRow(row);
  }

  void insertColumnLeft(CellSelection selection) {
    final col = selection.start.col;
    ref.read(spreadsheetProvider.notifier).insertColumn(col);
  }

  void insertColumnRight(CellSelection selection) {
    final col = selection.start.col;
    ref.read(spreadsheetProvider.notifier).insertColumn(col + 1);
  }

  void deleteColumn(CellSelection selection) {
    final col = selection.start.col;
    ref.read(spreadsheetProvider.notifier).deleteColumn(col);
  }

  // Sort Data
  void sortRange(CellSelection selection, {bool ascending = true}) {
    sortSelection(selection, ascending: ascending);
  }

  //----------
  /// Clear all formatting from selected cells while preserving values
  void clearFormatting(CellSelection selection) {
    _formatSelection(
      selection,
      (_) => const CellStyle(),
      description: 'Clear formatting',
      createMissing: false,
    );
  }

  /// Set text color for selected cells
  void setTextColor(CellSelection selection, Color color) {
    _formatSelection(
      selection,
      (current) => current.style.copyWith(textColor: color),
      description: 'Set text color',
    );
  }

  /// Apply number formatting to selected cells
  void setNumberFormat(CellSelection selection, String formatType) {
    _formatSelection(
      selection,
      (current) => current.style.copyWith(numberFormat: formatType),
      description: 'Set number format',
    );
  }

  /// Sort selected range
  void sortSelection(
    CellSelection selection, {
    bool ascending = true,
    int? sortColumn,
  }) {
    ref
        .read(spreadsheetProvider.notifier)
        .sortRange(selection, ascending: ascending, sortColumn: sortColumn);
  }

  /// Sorts a structured table by a column without moving the header row.
  void sortTableColumn(SheetTable table, int column, {bool ascending = true}) {
    final firstBodyRow = table.showHeaderRow ? table.minRow + 1 : table.minRow;
    final lastBodyRow = table.hasTotalsRow ? table.maxRow - 1 : table.maxRow;
    if (firstBodyRow > lastBodyRow) return;

    sortSelection(
      CellSelection(
        CellAddress(firstBodyRow, table.minCol),
        CellAddress(lastBodyRow, table.maxCol),
      ),
      ascending: ascending,
      sortColumn: column,
    );
    ref.read(sortColumnProvider.notifier).state = column;
    ref.read(sortAscendingProvider.notifier).state = ascending;
  }

  /// Clears the active sort marker while leaving the current row order intact.
  void clearSort() {
    ref.read(sortColumnProvider.notifier).state = null;
    ref.read(sortAscendingProvider.notifier).state = true;
  }

  /// Apply filter to selected column
  void applyFilter(CellSelection selection) {
    setFilter(selection.start.col, '');
  }

  void setFilter(int column, String query) {
    setFilterRule(column, SheetFilterRule.contains(query));
  }

  void setFilterRule(int column, SheetFilterRule rule) {
    final currentFilters = Map<int, String>.from(ref.read(filterProvider));
    final currentRules = Map<int, SheetFilterRule>.from(
      ref.read(sheetFilterRulesProvider),
    );
    final normalizedRule = rule.copyWith(value: rule.value.trim());

    if (!normalizedRule.isActive) {
      currentFilters.remove(column);
      currentRules.remove(column);
    } else {
      currentRules[column] = normalizedRule;
      if (normalizedRule.operator.requiresValue) {
        currentFilters[column] = normalizedRule.value;
      } else {
        currentFilters.remove(column);
      }
    }

    ref.read(filterProvider.notifier).state = currentFilters;
    ref.read(sheetFilterRulesProvider.notifier).state = currentRules;
  }

  /// Filters the clicked column down to rows matching the clicked cell value.
  void keepOnlyCellValue(CellAddress address) {
    _applyCellQuickFilter(address, SheetCellQuickFilterMode.keepOnly);
  }

  /// Filters the clicked column to exclude rows matching the clicked value.
  void excludeCellValue(CellAddress address) {
    _applyCellQuickFilter(address, SheetCellQuickFilterMode.exclude);
  }

  void _applyCellQuickFilter(
    CellAddress address,
    SheetCellQuickFilterMode mode,
  ) {
    final value = ref.read(spreadsheetProvider)[address]?.value ?? '';
    final rule = SheetCellQuickFilterRuleBuilder.build(
      value: value,
      mode: mode,
    );

    setFilterRule(address.col, rule);
  }

  /// Remove filter from selected column
  void removeFilter(CellSelection selection) {
    removeFilterColumn(selection.start.col);
  }

  void removeFilterColumn(int column) {
    clearFilterColumns([column]);
  }

  /// Clears filters from multiple columns while preserving unrelated filters.
  void clearFilterColumns(Iterable<int> columns) {
    final columnsToClear = columns.toSet();
    if (columnsToClear.isEmpty) return;

    final currentFilters = Map<int, String>.from(ref.read(filterProvider));
    final currentRules = Map<int, SheetFilterRule>.from(
      ref.read(sheetFilterRulesProvider),
    );
    var changed = false;
    for (final column in columnsToClear) {
      changed = currentFilters.remove(column) != null || changed;
      changed = currentRules.remove(column) != null || changed;
    }
    if (!changed) return;

    ref.read(filterProvider.notifier).state = currentFilters;
    ref.read(sheetFilterRulesProvider.notifier).state = currentRules;
  }

  void clearFilters() {
    ref.read(filterProvider.notifier).state = {};
    ref.read(sheetFilterRulesProvider.notifier).state = {};
  }

  /// Freeze panes at selection
  void freezePanesAt(CellSelection selection) {
    ref.read(freezePanesProvider.notifier).state = selection.start;
  }

  void freezeFirstRow() {
    ref.read(freezePanesProvider.notifier).state = CellAddress(1, 0);
  }

  void freezeFirstColumn() {
    ref.read(freezePanesProvider.notifier).state = CellAddress(0, 1);
  }

  void freezeFirstRowAndColumn() {
    ref.read(freezePanesProvider.notifier).state = CellAddress(1, 1);
  }

  /// Unfreeze all panes
  void unfreezePanes() {
    ref.read(freezePanesProvider.notifier).state = null;
  }

  /// Zoom in
  void zoomIn() {
    final currentZoom = ref.read(zoomLevelProvider);
    final newZoom = (currentZoom * 1.2).clamp(0.5, 3.0);
    ref.read(zoomLevelProvider.notifier).state = newZoom;
  }

  /// Zoom out
  void zoomOut() {
    final currentZoom = ref.read(zoomLevelProvider);
    final newZoom = (currentZoom / 1.2).clamp(0.5, 3.0);
    ref.read(zoomLevelProvider.notifier).state = newZoom;
  }

  /// Reset zoom to 100%
  void resetZoom() {
    ref.read(zoomLevelProvider.notifier).state = 1.0;
  }

  void setZoom(double zoom) {
    ref.read(zoomLevelProvider.notifier).state = zoom.clamp(0.5, 3.0);
  }

  /// Search for text in spreadsheet
  void search(String query) {
    ref.read(searchQueryProvider.notifier).state = query;
    if (query.isNotEmpty) {
      final results = ref.read(spreadsheetProvider.notifier).search(query);
      ref.read(searchResultsProvider.notifier).state = results;
      ref.read(currentSearchIndexProvider.notifier).state = 0;
    } else {
      ref.read(searchResultsProvider.notifier).state = [];
    }
  }

  /// Navigate to next search result
  void nextSearchResult() {
    final results = ref.read(searchResultsProvider);
    final currentIndex = ref.read(currentSearchIndexProvider);
    if (results.isNotEmpty) {
      final nextIndex = (currentIndex + 1) % results.length;
      ref.read(currentSearchIndexProvider.notifier).state = nextIndex;

      // Create a single cell selection for the search result
      final selectedCell = CellSelection.single(results[nextIndex]);
      ref.read(selectedCellProvider.notifier).state = selectedCell;
    }
  }

  /// Navigate to previous search result
  void previousSearchResult() {
    final results = ref.read(searchResultsProvider);
    final currentIndex = ref.read(currentSearchIndexProvider);
    if (results.isNotEmpty) {
      final prevIndex = (currentIndex - 1 + results.length) % results.length;
      ref.read(currentSearchIndexProvider.notifier).state = prevIndex;

      // Create a single cell selection for the search result
      final selectedCell = CellSelection.single(results[prevIndex]);
      ref.read(selectedCellProvider.notifier).state = selectedCell;
    }
  }

  /// Replace all occurrences of text
  void replaceAll(String find, String replace) {
    ref.read(spreadsheetProvider.notifier).replaceAll(find, replace);
  }

  ///-----
  /// Apply data validation to selected cells
  void applyValidation(CellSelection selection, CellValidation validation) {
    _updateSelectionCells(
      selection,
      (_, current) => current.copyWith(validation: validation),
      description: 'Apply validation',
      recalculate: false,
    );
  }

  /// Clear data validation from selected cells
  void clearValidation(CellSelection selection) {
    _updateSelectionCells(
      selection,
      (_, current) => current.copyWith(clearValidation: true),
      description: 'Clear validation',
      createMissing: false,
      recalculate: false,
    );
  }

  //----------

  /// Apply required field validation
  void applyRequiredValidation(
    CellSelection selection, {
    String? errorMessage,
  }) {
    final validation = CellValidation(
      type: ValidationType.required,
      errorMessage: errorMessage ?? 'This field is required',
    );
    applyValidation(selection, validation);
  }

  /// Apply phone number validation
  void applyPhoneValidation(CellSelection selection, {String? errorMessage}) {
    final validation = CellValidation(
      type: ValidationType.phone,
      errorMessage: errorMessage ?? 'Please enter a valid phone number',
    );
    applyValidation(selection, validation);
  }

  /// Apply regex pattern validation
  void applyRegexValidation(
    CellSelection selection,
    String pattern, {
    String? errorMessage,
  }) {
    final validation = CellValidation(
      type: ValidationType.regex,
      pattern: pattern,
      errorMessage: errorMessage ?? 'Value must match the required pattern',
    );
    applyValidation(selection, validation);
  }

  /// Apply minimum length validation
  void applyMinLengthValidation(
    CellSelection selection,
    int minLength, {
    String? errorMessage,
  }) {
    final validation = CellValidation(
      type: ValidationType.minLength,
      min: minLength.toString(),
      errorMessage:
          errorMessage ?? 'Value must be at least $minLength characters long',
    );
    applyValidation(selection, validation);
  }

  /// Apply maximum length validation
  void applyMaxLengthValidation(
    CellSelection selection,
    int maxLength, {
    String? errorMessage,
  }) {
    final validation = CellValidation(
      type: ValidationType.maxLength,
      max: maxLength.toString(),
      errorMessage:
          errorMessage ?? 'Value must be at most $maxLength characters long',
    );
    applyValidation(selection, validation);
  }

  /// Apply minimum value validation (works for numbers, dates, and text length)
  void applyMinValidation(
    CellSelection selection,
    String minValue, {
    String? errorMessage,
  }) {
    final validation = CellValidation(
      type: ValidationType.min,
      min: minValue,
      errorMessage: errorMessage ?? 'Value must be at least $minValue',
    );
    applyValidation(selection, validation);
  }

  /// Apply maximum value validation (works for numbers, dates, and text length)
  void applyMaxValidation(
    CellSelection selection,
    String maxValue, {
    String? errorMessage,
  }) {
    final validation = CellValidation(
      type: ValidationType.max,
      max: maxValue,
      errorMessage: errorMessage ?? 'Value must be at most $maxValue',
    );
    applyValidation(selection, validation);
  }

  //------

  /// Apply number validation to selected cells
  void applyNumberValidation(
    CellSelection selection, {
    double? min,
    double? max,
    String? errorMessage,
  }) {
    final validation = CellValidation(
      type: ValidationType.number,
      min: min?.toString(),
      max: max?.toString(),
      errorMessage: errorMessage,
    );
    applyValidation(selection, validation);
  }

  /// Apply list validation to selected cells
  void applyListValidation(
    CellSelection selection,
    List<String> options, {
    String? errorMessage,
  }) {
    final validation = CellValidation(
      type: ValidationType.list,
      options: options,
      errorMessage: errorMessage,
    );
    applyValidation(selection, validation);
  }

  /// Apply date validation to selected cells
  void applyDateValidation(CellSelection selection, {String? errorMessage}) {
    final validation = CellValidation(
      type: ValidationType.date,
      errorMessage: errorMessage,
    );
    applyValidation(selection, validation);
  }

  /// Apply email validation to selected cells
  void applyEmailValidation(CellSelection selection, {String? errorMessage}) {
    final validation = CellValidation(
      type: ValidationType.email,
      errorMessage: errorMessage,
    );
    applyValidation(selection, validation);
  }

  /// Apply URL validation to selected cells
  void applyUrlValidation(CellSelection selection, {String? errorMessage}) {
    final validation = CellValidation(
      type: ValidationType.url,
      errorMessage: errorMessage,
    );
    applyValidation(selection, validation);
  }

  ////---------
}
