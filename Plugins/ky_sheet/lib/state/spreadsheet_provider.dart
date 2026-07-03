// Providers
import 'dart:math' as math;

import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as excel_lib;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../model/cell/cell_address.dart';
import '../model/cell/cell_data.dart';
import '../model/cell/cell_selection.dart';
import '../model/cell/cell_style.dart';
import '../model/column_config.dart';
import '../model/conditional_format_rule.dart';
import '../model/row_config.dart';
import '../model/sheet_filter_rule.dart';
import '../model/sheet_named_range.dart';
import '../model/sheet_search_match.dart';
import '../model/sheet_table.dart';
import '../model/undo_redo_action.dart';
import '../service/sheet_formula_engine.dart';
import '../utils/sheet_engine_operation_diff.dart';
import '../utils/sheet_engine_operation_replayer.dart';
import '../utils/sheet_find_replace_engine.dart';
import 'sheet_engine_operation_provider.dart';
import 'sheet_named_range_provider.dart';
import 'sheet_table_provider.dart';

final selectedCellProvider = StateProvider<CellSelection?>((ref) => null);
final editingCellProvider = StateProvider<CellAddress?>((ref) => null);
final editingCellDraftProvider = StateProvider<String?>((ref) => null);
final fillPreviewProvider = StateProvider<CellSelection?>((ref) => null);
final conditionalFormatRulesProvider =
    StateProvider<List<ConditionalFormatRule>>((ref) => []);

final undoStackProvider = StateProvider<List<UndoRedoAction>>((ref) => []);
final redoStackProvider = StateProvider<List<UndoRedoAction>>((ref) => []);

final clipboardProvider = StateProvider<Map<CellAddress, CellData>?>(
  (ref) => null,
);
final systemClipboardTextProvider = StateProvider<String?>((ref) => null);

final freezePanesProvider = StateProvider<CellAddress?>((ref) => null);

final filterProvider = StateProvider<Map<int, String>>((ref) => {});
final sheetFilterRulesProvider = StateProvider<Map<int, SheetFilterRule>>(
  (ref) => {},
);

final sortColumnProvider = StateProvider<int?>((ref) => null);
final sortAscendingProvider = StateProvider<bool>((ref) => true);

final columnConfigProvider = StateProvider<Map<int, ColumnConfig>>((ref) => {});
final rowConfigProvider = StateProvider<Map<int, RowConfig>>((ref) => {});

final searchQueryProvider = StateProvider<String>((ref) => '');
final searchResultsProvider = StateProvider<List<CellAddress>>((ref) => []);
final currentSearchIndexProvider = StateProvider<int>((ref) => 0);

final zoomLevelProvider = StateProvider<double>((ref) => 1.0);

final spreadsheetProvider =
    StateNotifierProvider<SpreadsheetNotifier, Map<CellAddress, CellData>>(
      (ref) => SpreadsheetNotifier(ref),
    );

const _maxHistoryEntries = 100;
const _formulaEngine = SheetFormulaEngine();

class SpreadsheetNotifier extends StateNotifier<Map<CellAddress, CellData>> {
  SpreadsheetNotifier([this._ref]) : super({});

  final Ref? _ref;
  bool _isApplyingHistory = false;

  bool get canUndo => _ref?.read(undoStackProvider).isNotEmpty ?? false;
  bool get canRedo => _ref?.read(redoStackProvider).isNotEmpty ?? false;

  void undo() {
    final ref = _ref;
    if (ref == null) return;

    final undoStack = ref.read(undoStackProvider);
    if (undoStack.isEmpty) return;

    final action = undoStack.last;
    ref.read(undoStackProvider.notifier).state = undoStack.sublist(
      0,
      undoStack.length - 1,
    );
    ref.read(redoStackProvider.notifier).state = [
      ...ref.read(redoStackProvider),
      action,
    ];

    _applyHistorySnapshot(action.before);
  }

  void redo() {
    final ref = _ref;
    if (ref == null) return;

    final redoStack = ref.read(redoStackProvider);
    if (redoStack.isEmpty) return;

    final action = redoStack.last;
    ref.read(redoStackProvider.notifier).state = redoStack.sublist(
      0,
      redoStack.length - 1,
    );
    ref.read(undoStackProvider.notifier).state = [
      ...ref.read(undoStackProvider),
      action,
    ];

    _applyHistorySnapshot(action.after);
  }

  void clearHistory() {
    final ref = _ref;
    if (ref == null) return;
    ref.read(undoStackProvider.notifier).state = [];
    ref.read(redoStackProvider.notifier).state = [];
  }

  void restoreSheetState(
    Map<CellAddress, CellData> nextState, {
    bool recalculate = true,
  }) {
    _isApplyingHistory = true;
    try {
      state = Map<CellAddress, CellData>.from(nextState);
      if (recalculate) {
        _recalculateFormulas();
      }
    } finally {
      _isApplyingHistory = false;
    }
    clearHistory();
  }

  void _commitChange(
    String description,
    Map<CellAddress, CellData> Function(Map<CellAddress, CellData> draft)
    buildNext, {
    bool recalculate = true,
    bool recordHistory = true,
    bool recordSheetEngineOperations = true,
  }) {
    final before = Map<CellAddress, CellData>.from(state);
    state = buildNext(Map<CellAddress, CellData>.from(state));
    if (recalculate) {
      _recalculateFormulas();
    }
    if (recordHistory) {
      _recordHistory(before, state, description);
    }
    if (recordSheetEngineOperations) {
      _recordSheetEngineOperations(before, state, description);
    }
  }

  void _replaceAllState(
    Map<CellAddress, CellData> nextState,
    String description, {
    bool recalculate = true,
    bool recordHistory = true,
    bool recordSheetEngineOperations = true,
  }) {
    final before = Map<CellAddress, CellData>.from(state);
    state = nextState;
    if (recalculate) {
      _recalculateFormulas();
    }
    if (recordHistory) {
      _recordHistory(before, state, description);
    }
    if (recordSheetEngineOperations) {
      _recordSheetEngineOperations(before, state, description);
    }
  }

  void _recordHistory(
    Map<CellAddress, CellData> before,
    Map<CellAddress, CellData> after,
    String description,
  ) {
    final ref = _ref;
    if (ref == null || _isApplyingHistory) return;

    final beforeDiff = <CellAddress, CellData?>{};
    final afterDiff = <CellAddress, CellData?>{};
    final addresses = {...before.keys, ...after.keys};

    for (final address in addresses) {
      final beforeCell = before[address];
      final afterCell = after[address];
      if (!_sameCellData(beforeCell, afterCell)) {
        beforeDiff[address] = beforeCell;
        afterDiff[address] = afterCell;
      }
    }

    if (beforeDiff.isEmpty) return;

    final nextUndoStack = [
      ...ref.read(undoStackProvider),
      UndoRedoAction(beforeDiff, afterDiff, description),
    ];
    ref
        .read(undoStackProvider.notifier)
        .state = nextUndoStack.length > _maxHistoryEntries
        ? nextUndoStack.sublist(nextUndoStack.length - _maxHistoryEntries)
        : nextUndoStack;
    ref.read(redoStackProvider.notifier).state = [];
  }

  void _recordSheetEngineOperations(
    Map<CellAddress, CellData> before,
    Map<CellAddress, CellData> after,
    String description,
  ) {
    final ref = _ref;
    if (ref == null || _isApplyingHistory) return;

    final edits = SheetEngineOperationDiff.buildEdits(
      before: before,
      after: after,
    );
    ref
        .read(sheetEngineOperationLogProvider.notifier)
        .appendEdits(edits, description: description);
  }

  void _applyHistorySnapshot(Map<CellAddress, CellData?> snapshot) {
    _isApplyingHistory = true;
    try {
      final nextState = Map<CellAddress, CellData>.from(state);
      snapshot.forEach((address, cellData) {
        if (cellData == null) {
          nextState.remove(address);
        } else {
          nextState[address] = cellData;
        }
      });
      state = nextState;
      _recalculateFormulas();
    } finally {
      _isApplyingHistory = false;
    }
  }

  bool _sameCellData(CellData? a, CellData? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    return a.toJson().toString() == b.toJson().toString();
  }

  void updateCell(CellAddress addr, CellData data) {
    _commitChange('Update ${addr.label}', (draft) {
      draft[addr] = data;
      return draft;
    });
  }

  void updateCells(
    Iterable<CellAddress> addresses,
    CellData Function(CellAddress address, CellData current) buildCell, {
    String description = 'Update cells',
    bool createMissing = true,
    bool recalculate = true,
  }) {
    final uniqueAddresses = addresses.toSet();
    if (uniqueAddresses.isEmpty) return;

    _commitChange(description, (draft) {
      for (final address in uniqueAddresses) {
        final current = draft[address];
        if (current == null && !createMissing) continue;

        draft[address] = buildCell(address, current ?? CellData());
      }
      return draft;
    }, recalculate: recalculate);
  }

  void updateCellStyles(
    Iterable<CellAddress> addresses,
    CellStyle Function(CellData current) buildStyle, {
    String description = 'Format cells',
    bool createMissing = true,
  }) {
    updateCells(
      addresses,
      (_, current) => current.copyWith(style: buildStyle(current)),
      description: description,
      createMissing: createMissing,
      recalculate: false,
    );
  }

  void replaceCells(
    Map<CellAddress, CellData?> cells, {
    String description = 'Update cells',
    bool recalculate = true,
  }) {
    if (cells.isEmpty) return;

    _commitChange(description, (draft) {
      cells.forEach((address, cellData) {
        if (cellData == null) {
          draft.remove(address);
        } else {
          draft[address] = cellData;
        }
      });
      return draft;
    }, recalculate: recalculate);
  }

  void updateCellValue(CellAddress addr, String value) {
    final current = state[addr] ?? CellData();

    // Validate input
    if (current.validation != null && !current.validation!.validate(value)) {
      return; // Validation failed
    }

    if (value.startsWith('=')) {
      _commitChange('Edit ${addr.label}', (draft) {
        draft[addr] = current.copyWith(formula: value, value: '');
        return draft;
      });
    } else {
      _commitChange('Edit ${addr.label}', (draft) {
        draft[addr] = current.copyWith(value: value, clearFormula: true);
        return draft;
      });
    }
  }

  void updateCellStyle(CellAddress addr, CellStyle style) {
    final current = state[addr] ?? CellData();
    _commitChange('Format ${addr.label}', (draft) {
      draft[addr] = current.copyWith(style: style);
      return draft;
    }, recalculate: false);
  }

  void clearCell(CellAddress addr) {
    _commitChange('Clear ${addr.label}', (draft) {
      draft.remove(addr);
      return draft;
    });
  }

  void clearCells(List<CellAddress> addresses) {
    _commitChange('Clear cells', (draft) {
      for (final addr in addresses) {
        draft.remove(addr);
      }
      return draft;
    });
  }

  int applySheetEngineEdit(
    Object? edit, {
    String description = 'Apply Waraq sheet_engine edit',
  }) {
    return applySheetEngineEditWithResult(
      edit,
      description: description,
    ).appliedEditCount;
  }

  SheetEngineOperationReplayResult applySheetEngineEditWithResult(
    Object? edit, {
    String description = 'Apply Waraq sheet_engine edit',
  }) {
    final result = SheetEngineOperationReplayer.applyEdit(
      cells: state,
      edit: edit,
    );
    _applySheetEngineReplayResult(result, description);
    return result;
  }

  int applySheetEngineOperation(
    Map<String, dynamic> operation, {
    String description = 'Apply Waraq sheet_engine operation',
    String? expectedDocumentId,
  }) {
    return applySheetEngineOperationWithResult(
      operation,
      description: description,
      expectedDocumentId: expectedDocumentId,
    ).appliedEditCount;
  }

  SheetEngineOperationReplayResult applySheetEngineOperationWithResult(
    Map<String, dynamic> operation, {
    String description = 'Apply Waraq sheet_engine operation',
    String? expectedDocumentId,
  }) {
    final result = SheetEngineOperationReplayer.applyOperation(
      cells: state,
      operation: operation,
      expectedDocumentId: expectedDocumentId ?? _sheetEngineDocumentId,
    );
    _applySheetEngineReplayResult(result, description);
    return result;
  }

  int applySheetEngineOperationLog(
    Map<String, dynamic> operationLog, {
    String description = 'Apply Waraq sheet_engine operation log',
    String? expectedDocumentId,
  }) {
    return applySheetEngineOperationLogWithResult(
      operationLog,
      description: description,
      expectedDocumentId: expectedDocumentId,
    ).appliedEditCount;
  }

  SheetEngineOperationReplayResult applySheetEngineOperationLogWithResult(
    Map<String, dynamic> operationLog, {
    String description = 'Apply Waraq sheet_engine operation log',
    String? expectedDocumentId,
  }) {
    final result = SheetEngineOperationReplayer.applyOperationLog(
      cells: state,
      operationLog: operationLog,
      expectedDocumentId: expectedDocumentId ?? _sheetEngineDocumentId,
    );
    _applySheetEngineReplayResult(result, description);
    return result;
  }

  void _applySheetEngineReplayResult(
    SheetEngineOperationReplayResult result,
    String description,
  ) {
    if (!result.hasAppliedEdits && !result.shouldRecalculate) return;

    _replaceAllState(
      result.cells,
      description,
      recalculate: result.shouldRecalculate,
      recordHistory: false,
      recordSheetEngineOperations: false,
    );
  }

  String? get _sheetEngineDocumentId {
    return _ref?.read(sheetEngineOperationLogProvider).documentId;
  }

  void pasteCells(Map<CellAddress, CellData> cells, CellAddress targetStart) {
    _commitChange('Paste cells', (draft) {
      cells.forEach((sourceAddr, data) {
        final targetAddr = CellAddress(
          targetStart.row + sourceAddr.row,
          targetStart.col + sourceAddr.col,
        );
        draft[targetAddr] = data;
      });
      return draft;
    });
  }

  void pasteCellValues(List<List<String>> rows, CellAddress targetStart) {
    if (rows.isEmpty) return;

    _commitChange('Paste values', (draft) {
      for (var row = 0; row < rows.length; row++) {
        for (var col = 0; col < rows[row].length; col++) {
          final address = CellAddress(
            targetStart.row + row,
            targetStart.col + col,
          );
          final value = rows[row][col];
          final current = draft[address] ?? CellData();

          if (current.validation != null &&
              !current.validation!.validate(value)) {
            continue;
          }

          if (value.isEmpty) {
            draft.remove(address);
          } else if (value.startsWith('=')) {
            draft[address] = current.copyWith(formula: value, value: '');
          } else {
            draft[address] = current.copyWith(value: value, clearFormula: true);
          }
        }
      }
      return draft;
    });
  }

  void fillCells(Map<CellAddress, CellData> cells) {
    if (cells.isEmpty) return;

    _commitChange('Fill cells', (draft) {
      draft.addAll(cells);
      return draft;
    });
  }

  void fillDown(CellAddress start, int count) {
    final sourceData = state[start];
    if (sourceData == null) return;

    _commitChange('Fill down', (draft) {
      for (int i = 1; i <= count; i++) {
        draft[CellAddress(start.row + i, start.col)] = sourceData;
      }
      return draft;
    });
  }

  void fillRight(CellAddress start, int count) {
    final sourceData = state[start];
    if (sourceData == null) return;

    _commitChange('Fill right', (draft) {
      for (int i = 1; i <= count; i++) {
        draft[CellAddress(start.row, start.col + i)] = sourceData;
      }
      return draft;
    });
  }

  void importFromExcel(excel_lib.Excel excel) {
    final newState = <CellAddress, CellData>{};

    for (var table in excel.tables.keys) {
      final sheet = excel.tables[table];
      if (sheet == null) continue;

      for (var row = 0; row < sheet.maxRows; row++) {
        for (var col = 0; col < sheet.maxColumns; col++) {
          final cell = sheet.cell(
            excel_lib.CellIndex.indexByColumnRow(
              columnIndex: col,
              rowIndex: row,
            ),
          );

          if (cell.value != null) {
            final cellData = CellData(
              value: cell.value.toString(),
              style: _convertExcelStyle(cell),
            );
            newState[CellAddress(row, col)] = cellData;
          }
        }
      }
      break; // Only import first sheet for now
    }

    _replaceAllState(
      newState,
      'Import Excel',
      recordSheetEngineOperations: false,
    );
    _clearSheetEngineOperations();
    _clearSheetMetadata();
  }

  CellStyle _convertExcelStyle(excel_lib.Data cell) {
    final style = CellStyle();

    // Convert Excel cell style to our CellStyle
    // This is simplified - real implementation would be more complex
    if (cell.cellStyle != null) {
      final excelStyle = cell.cellStyle!;
      return style.copyWith(
        bold: excelStyle.isBold,
        italic: excelStyle.isItalic,
        underline: excelStyle.underline != excel_lib.Underline.None,
      );
    }

    return style;
  }

  void importFromCSV(String csvContent) {
    final rows = csv.decode(csvContent);
    final newState = <CellAddress, CellData>{};

    for (int r = 0; r < rows.length; r++) {
      for (int c = 0; c < rows[r].length; c++) {
        final value = rows[r][c]?.toString() ?? '';
        if (value.isNotEmpty) {
          newState[CellAddress(r, c)] = CellData(value: value);
        }
      }
    }

    _replaceAllState(
      newState,
      'Import CSV',
      recordSheetEngineOperations: false,
    );
    _clearSheetEngineOperations();
    _clearSheetMetadata();
  }

  String exportToCSV() {
    if (state.isEmpty) return '';

    final maxRow = state.keys.map((e) => e.row).reduce(math.max);
    final maxCol = state.keys.map((e) => e.col).reduce(math.max);

    final rows = <List<String>>[];
    for (int r = 0; r <= maxRow; r++) {
      final row = <String>[];
      for (int c = 0; c <= maxCol; c++) {
        final cell = state[CellAddress(r, c)];
        row.add(cell?.value ?? '');
      }
      rows.add(row);
    }

    return csv.encode(rows);
  }

  excel_lib.Excel exportToExcel() {
    final excel = excel_lib.Excel.createExcel();
    final sheet = excel['Sheet1'];

    state.forEach((addr, data) {
      final cell = sheet.cell(
        excel_lib.CellIndex.indexByColumnRow(
          columnIndex: addr.col,
          rowIndex: addr.row,
        ),
      );

      cell.value = excel_lib.TextCellValue(data.value);

      // Apply styling
      if (data.style.bold || data.style.italic) {
        cell.cellStyle = excel_lib.CellStyle(
          bold: data.style.bold,
          italic: data.style.italic,
        );
      }
    });

    return excel;
  }

  Map<String, dynamic> exportToJson() {
    final cellsJson = <String, dynamic>{};
    state.forEach((addr, data) {
      cellsJson['${addr.row},${addr.col}'] = data.toJson();
    });

    final ref = _ref;
    return {
      'cells': cellsJson,
      'version': '3.0',
      if (ref != null) 'metadata': _exportMetadata(ref),
    };
  }

  void importFromJson(Map<String, dynamic> json) {
    final newState = <CellAddress, CellData>{};
    final cellsJson = json['cells'] as Map<String, dynamic>? ?? {};
    cellsJson.forEach((key, value) {
      final parts = key.split(',');
      final addr = CellAddress(int.parse(parts[0]), int.parse(parts[1]));
      newState[addr] = CellData.fromJson(value);
    });
    _replaceAllState(
      newState,
      'Import JSON',
      recordSheetEngineOperations: false,
    );
    _clearSheetEngineOperations();
    _importMetadata(json['metadata']);
  }

  void _clearSheetEngineOperations() {
    _ref?.read(sheetEngineOperationLogProvider.notifier).clear();
  }

  Map<String, dynamic> _exportMetadata(Ref ref) {
    final rowConfig = ref.read(rowConfigProvider);
    final columnConfig = ref.read(columnConfigProvider);
    final freezePane = ref.read(freezePanesProvider);
    final sortColumn = ref.read(sortColumnProvider);
    final sortMetadata = <String, dynamic>{
      'ascending': ref.read(sortAscendingProvider),
    };
    if (sortColumn != null) {
      sortMetadata['column'] = sortColumn;
    }

    return {
      'conditionalFormatRules': [
        for (final rule in ref.read(conditionalFormatRulesProvider))
          rule.toJson(),
      ],
      'namedRanges': [
        for (final range in ref.read(sheetNamedRangesProvider)) range.toJson(),
      ],
      'rowConfig': {
        for (final entry in rowConfig.entries)
          entry.key.toString(): entry.value.toJson(),
      },
      'columnConfig': {
        for (final entry in columnConfig.entries)
          entry.key.toString(): entry.value.toJson(),
      },
      'filters': {
        for (final entry in ref.read(filterProvider).entries)
          entry.key.toString(): entry.value,
      },
      'filterRules': {
        for (final entry in ref.read(sheetFilterRulesProvider).entries)
          if (entry.value.isActive) entry.key.toString(): entry.value.toJson(),
      },
      'tables': [
        for (final table in ref.read(sheetTablesProvider)) table.toJson(),
      ],
      'sort': sortMetadata,
      if (freezePane != null) 'freezePane': freezePane.toJson(),
      'zoom': ref.read(zoomLevelProvider),
    };
  }

  void _importMetadata(dynamic metadataJson) {
    final ref = _ref;
    if (ref == null) return;

    if (metadataJson is! Map) {
      _clearSheetMetadata();
      return;
    }

    final metadata = Map<String, dynamic>.from(metadataJson);
    final conditionalRulesJson = metadata['conditionalFormatRules'];
    ref
        .read(conditionalFormatRulesProvider.notifier)
        .state = conditionalRulesJson is List
        ? [
            for (final ruleJson in conditionalRulesJson)
              ConditionalFormatRule.fromJson(
                Map<String, dynamic>.from(ruleJson),
              ),
          ]
        : [];

    final namedRangesJson = metadata['namedRanges'];
    ref
        .read(sheetNamedRangesProvider.notifier)
        .replaceAll(
          namedRangesJson is List
              ? [
                  for (final rangeJson in namedRangesJson)
                    if (rangeJson is Map)
                      SheetNamedRange.fromJson(
                        Map<String, dynamic>.from(rangeJson),
                      ),
                ]
              : const [],
        );

    final rowConfigJson = metadata['rowConfig'];
    ref.read(rowConfigProvider.notifier).state = rowConfigJson is Map
        ? {
            for (final entry in rowConfigJson.entries)
              int.parse(entry.key.toString()): RowConfig.fromJson(
                Map<String, dynamic>.from(entry.value),
              ),
          }
        : {};

    final columnConfigJson = metadata['columnConfig'];
    ref.read(columnConfigProvider.notifier).state = columnConfigJson is Map
        ? {
            for (final entry in columnConfigJson.entries)
              int.parse(entry.key.toString()): ColumnConfig.fromJson(
                Map<String, dynamic>.from(entry.value),
              ),
          }
        : {};

    final filtersJson = metadata['filters'];
    final legacyFilters = filtersJson is Map
        ? {
            for (final entry in filtersJson.entries)
              int.parse(entry.key.toString()): entry.value.toString(),
          }
        : <int, String>{};
    ref.read(filterProvider.notifier).state = legacyFilters;

    final filterRulesJson = metadata['filterRules'];
    ref.read(sheetFilterRulesProvider.notifier).state = filterRulesJson is Map
        ? {
            for (final entry in filterRulesJson.entries)
              if (int.tryParse(entry.key.toString()) != null &&
                  entry.value is Map)
                int.parse(entry.key.toString()): SheetFilterRule.fromJson(
                  Map<String, dynamic>.from(entry.value),
                ),
          }
        : {
            for (final entry in legacyFilters.entries)
              if (entry.value.trim().isNotEmpty)
                entry.key: SheetFilterRule.contains(entry.value),
          };

    final sortJson = metadata['sort'];
    if (sortJson is Map) {
      final sort = Map<String, dynamic>.from(sortJson);
      ref.read(sortColumnProvider.notifier).state = sort['column'] as int?;
      ref.read(sortAscendingProvider.notifier).state =
          sort['ascending'] as bool? ?? true;
    } else {
      ref.read(sortColumnProvider.notifier).state = null;
      ref.read(sortAscendingProvider.notifier).state = true;
    }

    final freezePaneJson = metadata['freezePane'];
    ref.read(freezePanesProvider.notifier).state = freezePaneJson is Map
        ? CellAddress.fromJson(Map<String, dynamic>.from(freezePaneJson))
        : null;

    final tablesJson = metadata['tables'];
    ref
        .read(sheetTablesProvider.notifier)
        .replaceAll(
          tablesJson is List
              ? [
                  for (final tableJson in tablesJson)
                    if (tableJson is Map)
                      SheetTable.fromJson(Map<String, dynamic>.from(tableJson)),
                ]
              : const [],
        );

    ref.read(zoomLevelProvider.notifier).state =
        (metadata['zoom'] as num?)?.toDouble() ?? 1.0;
  }

  void _clearSheetMetadata() {
    final ref = _ref;
    if (ref == null) return;

    ref.read(conditionalFormatRulesProvider.notifier).state = [];
    ref.read(sheetNamedRangesProvider.notifier).replaceAll(const []);
    ref.read(rowConfigProvider.notifier).state = {};
    ref.read(columnConfigProvider.notifier).state = {};
    ref.read(filterProvider.notifier).state = {};
    ref.read(sheetFilterRulesProvider.notifier).state = {};
    ref.read(sheetTablesProvider.notifier).clear();
    ref.read(sortColumnProvider.notifier).state = null;
    ref.read(sortAscendingProvider.notifier).state = true;
    ref.read(freezePanesProvider.notifier).state = null;
    ref.read(zoomLevelProvider.notifier).state = 1.0;
  }

  List<CellAddress> search(String query) {
    return searchMatches(query).map((match) => match.address).toSet().toList()
      ..sort((a, b) {
        final rowCompare = a.row.compareTo(b.row);
        return rowCompare == 0 ? a.col.compareTo(b.col) : rowCompare;
      });
  }

  List<SheetSearchMatch> searchMatches(
    String query, {
    SheetSearchOptions options = const SheetSearchOptions(
      scope: SheetSearchScope.all,
    ),
  }) {
    return SheetFindReplaceEngine.findMatches(
      cells: state,
      query: query,
      options: options,
    );
  }

  void replaceAll(String find, String replace) {
    replaceAllMatches(
      find,
      replace,
      options: const SheetSearchOptions(scope: SheetSearchScope.cellValues),
    );
  }

  int replaceAllMatches(
    String find,
    String replacement, {
    SheetSearchOptions options = const SheetSearchOptions(),
  }) {
    final matches = searchMatches(find, options: options);
    return replaceSearchMatches(matches, find, replacement, options: options);
  }

  int replaceSearchMatch(
    SheetSearchMatch match,
    String find,
    String replacement, {
    SheetSearchOptions options = const SheetSearchOptions(),
  }) {
    return replaceSearchMatches(
      [match],
      find,
      replacement,
      options: options,
      replaceFirstOnly: true,
      description: 'Replace ${match.address.label}',
    );
  }

  int replaceSearchMatches(
    Iterable<SheetSearchMatch> matches,
    String find,
    String replacement, {
    SheetSearchOptions options = const SheetSearchOptions(),
    bool replaceFirstOnly = false,
    String description = 'Replace matches',
  }) {
    if (find.isEmpty) return 0;

    final targetsByAddress = <CellAddress, Set<SheetSearchTarget>>{};
    for (final match in matches) {
      targetsByAddress
          .putIfAbsent(match.address, () => <SheetSearchTarget>{})
          .add(match.target);
    }
    if (targetsByAddress.isEmpty) return 0;

    _commitChange(description, (draft) {
      for (final entry in targetsByAddress.entries) {
        final current = draft[entry.key];
        if (current == null) continue;

        draft[entry.key] = SheetFindReplaceEngine.replaceTargetsInCell(
          cell: current,
          targets: entry.value,
          find: find,
          replacement: replacement,
          options: options,
          replaceFirstOnly: replaceFirstOnly,
        );
      }
      return draft;
    });

    return targetsByAddress.length;
  }

  void _recalculateFormulas() {
    final newState = Map<CellAddress, CellData>.from(state);
    final namedRanges =
        _ref?.read(sheetNamedRangesProvider) ?? const <SheetNamedRange>[];
    bool hasChanges = true;
    int maxIterations = 10;
    int iteration = 0;

    while (hasChanges && iteration < maxIterations) {
      hasChanges = false;
      iteration++;

      for (final entry in newState.entries) {
        if (entry.value.formula != null) {
          final result = _formulaEngine.evaluate(
            entry.value.formula!,
            newState,
            namedRanges: namedRanges,
          );
          if (result != entry.value.value) {
            newState[entry.key] = entry.value.copyWith(value: result);
            hasChanges = true;
          }
        }
      }
    }
    state = newState;
  }

  // ignore: unused_element
  /// Insert a new row at the specified index
  void insertRow(int rowIndex) {
    insertRows(rowIndex, 1);
  }

  /// Delete a row at the specified index
  void deleteRow(int rowIndex) {
    deleteRows(rowIndex, rowIndex);
  }

  /// Insert a new column at the specified index
  void insertColumn(int colIndex) {
    insertColumns(colIndex, 1);
  }

  /// Delete a column at the specified index
  void deleteColumn(int colIndex) {
    deleteColumns(colIndex, colIndex);
  }

  /// Insert multiple rows starting at rowIndex
  void insertRows(int rowIndex, int count) {
    if (count <= 0) return;

    _commitChange('Insert rows', (draft) {
      final newState = <CellAddress, CellData>{};

      draft.forEach((addr, data) {
        if (addr.row < rowIndex) {
          newState[addr] = data;
        } else {
          newState[CellAddress(addr.row + count, addr.col)] = data;
        }
      });

      return newState;
    });
  }

  /// Insert multiple columns starting at colIndex
  void insertColumns(int colIndex, int count) {
    if (count <= 0) return;

    _commitChange('Insert columns', (draft) {
      final newState = <CellAddress, CellData>{};

      draft.forEach((addr, data) {
        if (addr.col < colIndex) {
          newState[addr] = data;
        } else {
          newState[CellAddress(addr.row, addr.col + count)] = data;
        }
      });

      return newState;
    });
  }

  /// Delete multiple rows starting from startRow to endRow
  void deleteRows(int startRow, int endRow) {
    final normalizedStart = math.min(startRow, endRow);
    final normalizedEnd = math.max(startRow, endRow);
    final count = normalizedEnd - normalizedStart + 1;

    _commitChange('Delete rows', (draft) {
      final newState = <CellAddress, CellData>{};

      draft.forEach((addr, data) {
        if (addr.row < normalizedStart) {
          newState[addr] = data;
        } else if (addr.row > normalizedEnd) {
          newState[CellAddress(addr.row - count, addr.col)] = data;
        }
      });

      return newState;
    });
  }

  /// Delete multiple columns starting from startCol to endCol
  void deleteColumns(int startCol, int endCol) {
    final normalizedStart = math.min(startCol, endCol);
    final normalizedEnd = math.max(startCol, endCol);
    final count = normalizedEnd - normalizedStart + 1;

    _commitChange('Delete columns', (draft) {
      final newState = <CellAddress, CellData>{};

      draft.forEach((addr, data) {
        if (addr.col < normalizedStart) {
          newState[addr] = data;
        } else if (addr.col > normalizedEnd) {
          newState[CellAddress(addr.row, addr.col - count)] = data;
        }
      });

      return newState;
    });
  }

  /// Move a row from source index to destination index
  void moveRow(int sourceRow, int destRow) {
    if (sourceRow == destRow) return;

    _commitChange('Move row', (draft) {
      final tempState = <CellAddress, CellData>{};
      final cellsToMove = <CellAddress, CellData>{};

      draft.forEach((addr, data) {
        if (addr.row == sourceRow) {
          cellsToMove[CellAddress(destRow, addr.col)] = data;
        } else {
          tempState[addr] = data;
        }
      });

      final newState = <CellAddress, CellData>{};
      tempState.forEach((addr, data) {
        if (sourceRow < destRow) {
          if (addr.row > sourceRow && addr.row <= destRow) {
            newState[CellAddress(addr.row - 1, addr.col)] = data;
          } else {
            newState[addr] = data;
          }
        } else {
          if (addr.row >= destRow && addr.row < sourceRow) {
            newState[CellAddress(addr.row + 1, addr.col)] = data;
          } else {
            newState[addr] = data;
          }
        }
      });

      newState.addAll(cellsToMove);
      return newState;
    });
  }

  /// Move a column from source index to destination index
  void moveColumn(int sourceCol, int destCol) {
    if (sourceCol == destCol) return;

    _commitChange('Move column', (draft) {
      final tempState = <CellAddress, CellData>{};
      final cellsToMove = <CellAddress, CellData>{};

      draft.forEach((addr, data) {
        if (addr.col == sourceCol) {
          cellsToMove[CellAddress(addr.row, destCol)] = data;
        } else {
          tempState[addr] = data;
        }
      });

      final newState = <CellAddress, CellData>{};
      tempState.forEach((addr, data) {
        if (sourceCol < destCol) {
          if (addr.col > sourceCol && addr.col <= destCol) {
            newState[CellAddress(addr.row, addr.col - 1)] = data;
          } else {
            newState[addr] = data;
          }
        } else {
          if (addr.col >= destCol && addr.col < sourceCol) {
            newState[CellAddress(addr.row, addr.col + 1)] = data;
          } else {
            newState[addr] = data;
          }
        }
      });

      newState.addAll(cellsToMove);
      return newState;
    });
  }

  /// Hide a row
  void hideRow(int rowIndex, Ref ref) {
    final rowConfig = Map<int, RowConfig>.from(ref.read(rowConfigProvider));
    final existingConfig = rowConfig[rowIndex];
    rowConfig[rowIndex] = (existingConfig ?? RowConfig(index: rowIndex))
        .copyWith(hidden: true);
    ref.read(rowConfigProvider.notifier).state = rowConfig;
  }

  /// Show a hidden row
  void showRow(int rowIndex, Ref ref) {
    final rowConfig = Map<int, RowConfig>.from(ref.read(rowConfigProvider));
    final existingConfig = rowConfig[rowIndex];
    rowConfig[rowIndex] = (existingConfig ?? RowConfig(index: rowIndex))
        .copyWith(hidden: false);
    ref.read(rowConfigProvider.notifier).state = rowConfig;
  }

  /// Hide a column
  void hideColumn(int colIndex, Ref ref) {
    final colConfig = Map<int, ColumnConfig>.from(
      ref.read(columnConfigProvider),
    );
    final existingConfig = colConfig[colIndex];
    colConfig[colIndex] = (existingConfig ?? ColumnConfig(index: colIndex))
        .copyWith(hidden: true);
    ref.read(columnConfigProvider.notifier).state = colConfig;
  }

  /// Show a hidden column
  void showColumn(int colIndex, Ref ref) {
    final colConfig = Map<int, ColumnConfig>.from(
      ref.read(columnConfigProvider),
    );
    final existingConfig = colConfig[colIndex];
    colConfig[colIndex] = (existingConfig ?? ColumnConfig(index: colIndex))
        .copyWith(hidden: false);
    ref.read(columnConfigProvider.notifier).state = colConfig;
  }

  /// Set column width
  void setColumnWidth(int colIndex, double width, Ref ref) {
    final colConfig = Map<int, ColumnConfig>.from(
      ref.read(columnConfigProvider),
    );
    final existingConfig = colConfig[colIndex];
    colConfig[colIndex] = (existingConfig ?? ColumnConfig(index: colIndex))
        .copyWith(width: width);
    ref.read(columnConfigProvider.notifier).state = colConfig;
  }

  /// Set row height
  void setRowHeight(int rowIndex, double height, Ref ref) {
    final rowConfig = Map<int, RowConfig>.from(ref.read(rowConfigProvider));
    final existingConfig = rowConfig[rowIndex];
    rowConfig[rowIndex] = (existingConfig ?? RowConfig(index: rowIndex))
        .copyWith(height: height);
    ref.read(rowConfigProvider.notifier).state = rowConfig;
  }

  /// Toggle row visibility
  void toggleRowVisibility(int rowIndex, Ref ref) {
    final rowConfig = Map<int, RowConfig>.from(ref.read(rowConfigProvider));
    final existingConfig = rowConfig[rowIndex];
    final isCurrentlyHidden = existingConfig?.hidden ?? false;
    rowConfig[rowIndex] = (existingConfig ?? RowConfig(index: rowIndex))
        .copyWith(hidden: !isCurrentlyHidden);
    ref.read(rowConfigProvider.notifier).state = rowConfig;
  }

  /// Toggle column visibility
  void toggleColumnVisibility(int colIndex, Ref ref) {
    final colConfig = Map<int, ColumnConfig>.from(
      ref.read(columnConfigProvider),
    );
    final existingConfig = colConfig[colIndex];
    final isCurrentlyHidden = existingConfig?.hidden ?? false;
    colConfig[colIndex] = (existingConfig ?? ColumnConfig(index: colIndex))
        .copyWith(hidden: !isCurrentlyHidden);
    ref.read(columnConfigProvider.notifier).state = colConfig;
  }

  /// Reset row to default settings
  void resetRow(int rowIndex, Ref ref) {
    final rowConfig = Map<int, RowConfig>.from(ref.read(rowConfigProvider));
    rowConfig.remove(rowIndex); // Remove custom config to use defaults
    ref.read(rowConfigProvider.notifier).state = rowConfig;
  }

  /// Reset column to default settings
  void resetColumn(int colIndex, Ref ref) {
    final colConfig = Map<int, ColumnConfig>.from(
      ref.read(columnConfigProvider),
    );
    colConfig.remove(colIndex); // Remove custom config to use defaults
    ref.read(columnConfigProvider.notifier).state = colConfig;
  }

  /// Replace the entire state with new data
  void replaceState(Map<CellAddress, CellData> newState) {
    _replaceAllState(newState, 'Replace sheet');
  }

  /// Get row height (returns default if no custom config)
  double getRowHeight(int rowIndex, Ref ref) {
    final rowConfig = ref.read(rowConfigProvider);
    return rowConfig[rowIndex]?.height ?? 40.0;
  }

  /// Get column width (returns default if no custom config)
  double getColumnWidth(int colIndex, Ref ref) {
    final colConfig = ref.read(columnConfigProvider);
    return colConfig[colIndex]?.width ?? 100.0;
  }

  /// Check if row is hidden
  bool isRowHidden(int rowIndex, Ref ref) {
    final rowConfig = ref.read(rowConfigProvider);
    return rowConfig[rowIndex]?.hidden ?? false;
  }

  /// Check if column is hidden
  bool isColumnHidden(int colIndex, Ref ref) {
    final colConfig = ref.read(columnConfigProvider);
    return colConfig[colIndex]?.hidden ?? false;
  }

  /// Auto-fit column width based on content
  void autoFitColumn(int colIndex, Ref ref) {
    final data = state;
    double maxWidth = 80.0; // minimum width

    // Find all cells in this column
    for (final entry in data.entries) {
      if (entry.key.col == colIndex && entry.value.value.isNotEmpty) {
        // Simple heuristic for text width
        final textLength = entry.value.value.length;
        final fontSize = entry.value.style.fontSize;
        final isBold = entry.value.style.bold;

        // More accurate width calculation considering font size and weight
        final estimatedWidth =
            textLength * (fontSize / 2) + (isBold ? 10 : 0) + 20.0;
        if (estimatedWidth > maxWidth) {
          maxWidth = estimatedWidth;
        }
      }
    }

    setColumnWidth(colIndex, maxWidth.clamp(40.0, 500.0), ref);
  }

  /// Auto-fit row height based on content
  void autoFitRow(int rowIndex, Ref ref) {
    final data = state;
    double maxHeight = 24.0; // minimum height

    // Find all cells in this row
    for (final entry in data.entries) {
      if (entry.key.row == rowIndex && entry.value.value.isNotEmpty) {
        // Calculate height based on line count and font size
        final lineCount = entry.value.value.split('\n').length;
        final fontSize = entry.value.style.fontSize;
        final estimatedHeight = lineCount * (fontSize + 8.0);

        if (estimatedHeight > maxHeight) {
          maxHeight = estimatedHeight;
        }
      }
    }

    setRowHeight(rowIndex, maxHeight.clamp(20.0, 200.0), ref);
  }

  /// Sort a range by one column while preserving row integrity.
  void sortRange(
    CellSelection selection, {
    bool ascending = true,
    int? sortColumn,
  }) {
    if (!selection.isRange()) return;

    final data = Map<CellAddress, CellData>.from(state);
    final minRow = selection.minRow;
    final maxRow = selection.maxRow;
    final minCol = selection.minCol;
    final maxCol = selection.maxCol;
    final effectiveSortColumn = (sortColumn ?? minCol)
        .clamp(minCol, maxCol)
        .toInt();

    final rows = [
      for (var row = minRow; row <= maxRow; row++)
        (
          originalRow: row,
          sortValue: data[CellAddress(row, effectiveSortColumn)]?.value ?? '',
          cells: [
            for (var col = minCol; col <= maxCol; col++)
              data[CellAddress(row, col)],
          ],
        ),
    ];

    rows.sort((a, b) {
      final result = _compareSortValues(
        a.sortValue,
        b.sortValue,
        ascending: ascending,
      );
      return result == 0 ? a.originalRow.compareTo(b.originalRow) : result;
    });

    _commitChange('Sort range', (draft) {
      for (var rowOffset = 0; rowOffset < rows.length; rowOffset++) {
        final targetRow = minRow + rowOffset;
        final row = rows[rowOffset];

        for (var colOffset = 0; colOffset <= maxCol - minCol; colOffset++) {
          final targetAddress = CellAddress(targetRow, minCol + colOffset);
          final cellData = row.cells[colOffset];

          if (cellData == null) {
            draft.remove(targetAddress);
          } else {
            draft[targetAddress] = cellData;
          }
        }
      }
      return draft;
    });

    final ref = _ref;
    if (ref != null) {
      ref.read(sortColumnProvider.notifier).state = effectiveSortColumn;
      ref.read(sortAscendingProvider.notifier).state = ascending;
    }
  }

  int _compareSortValues(
    String valueA,
    String valueB, {
    required bool ascending,
  }) {
    final a = valueA.trim();
    final b = valueB.trim();

    if (a.isEmpty && b.isEmpty) return 0;
    if (a.isEmpty) return 1;
    if (b.isEmpty) return -1;

    final numericA = double.tryParse(a);
    final numericB = double.tryParse(b);
    if (numericA != null && numericB != null) {
      final result = numericA.compareTo(numericB);
      return ascending ? result : -result;
    }

    final dateA = DateTime.tryParse(a);
    final dateB = DateTime.tryParse(b);
    if (dateA != null && dateB != null) {
      final result = dateA.compareTo(dateB);
      return ascending ? result : -result;
    }

    final result = a.toLowerCase().compareTo(b.toLowerCase());
    return ascending ? result : -result;
  }
}
