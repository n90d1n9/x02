import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../model/workbook_sheet.dart';
import '../utils/sheet_engine_codec.dart';
import '../utils/sheet_workbook_codec.dart';
import 'sheet_engine_operation_provider.dart';
import 'sheet_find_replace_provider.dart';
import 'sheet_formula_preview_provider.dart';
import 'sheet_named_range_provider.dart';
import 'sheet_recent_sheet_provider.dart';
import 'sheet_table_provider.dart';
import 'spreadsheet_provider.dart';

/// Shared workbook state for sheet ordering, active sheet, and sheet metadata.
final workbookProvider = StateNotifierProvider<WorkbookNotifier, SheetWorkbook>(
  (ref) => WorkbookNotifier(ref),
);

/// Coordinates workbook sheet lifecycle and active-sheet state hydration.
class WorkbookNotifier extends StateNotifier<SheetWorkbook> {
  WorkbookNotifier(this.ref) : super(SheetWorkbook.initial());

  final Ref ref;
  var _nextSheetNumber = 2;

  void switchToSheet(String id) {
    if (id == state.activeSheetId) return;
    final target = state.sheets.where((sheet) => sheet.id == id).firstOrNull;
    if (target == null || target.hidden) return;

    final savedSheets = _sheetsWithActiveSnapshot();
    final savedTarget = savedSheets.firstWhere((sheet) => sheet.id == id);
    state = state.copyWith(sheets: savedSheets, activeSheetId: id);
    _loadSheet(savedTarget);
  }

  /// Switches to a nearby visible sheet, wrapping around the workbook edges.
  void switchToAdjacentVisibleSheet(int delta) {
    if (delta == 0) return;

    final visibleSheets = state.visibleSheets;
    if (visibleSheets.length <= 1) return;

    final activeIndex = visibleSheets.indexWhere(
      (sheet) => sheet.id == state.activeSheetId,
    );
    if (activeIndex == -1) return;

    final targetIndex = (activeIndex + delta).remainder(visibleSheets.length);
    final normalizedTargetIndex = targetIndex < 0
        ? targetIndex + visibleSheets.length
        : targetIndex;

    switchToSheet(visibleSheets[normalizedTargetIndex].id);
  }

  void addSheet() {
    final savedSheets = _sheetsWithActiveSnapshot();
    final sheet = WorkbookSheet(
      id: _nextSheetId(),
      name: _nextSheetName(savedSheets),
    );

    state = SheetWorkbook(
      sheets: [...savedSheets, sheet],
      activeSheetId: sheet.id,
    );
    _loadSheet(sheet);
  }

  void duplicateActiveSheet() {
    duplicateSheet(state.activeSheetId);
  }

  void duplicateSheet(String id) {
    final savedSheets = _sheetsWithActiveSnapshot();
    final source = savedSheets.firstWhere(
      (sheet) => sheet.id == id,
      orElse: () =>
          savedSheets.firstWhere((sheet) => sheet.id == state.activeSheetId),
    );
    final copy = source
        .clone(
          id: _nextSheetId(),
          name: _uniqueName('${source.name} Copy', savedSheets),
        )
        .copyWith(hidden: false);

    state = SheetWorkbook(
      sheets: [...savedSheets, copy],
      activeSheetId: copy.id,
    );
    _loadSheet(copy);
  }

  void renameSheet(String id, String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    state = state.copyWith(
      sheets: [
        for (final sheet in state.sheets)
          if (sheet.id == id)
            sheet.copyWith(name: _uniqueName(trimmed, state.sheets, id))
          else
            sheet,
      ],
    );
  }

  /// Applies or clears the presentation color shown on a sheet tab.
  void setSheetTabColor(String id, Color? color) {
    state = state.copyWith(
      sheets: [
        for (final sheet in state.sheets)
          if (sheet.id == id)
            sheet.copyWith(tabColor: color, clearTabColor: color == null)
          else
            sheet,
      ],
    );
  }

  void moveSheet(String id, int delta) {
    if (delta == 0) return;

    final visibleSheets = state.visibleSheets;
    final visibleIndex = visibleSheets.indexWhere((sheet) => sheet.id == id);
    if (visibleIndex == -1) return;

    final targetVisibleIndex = (visibleIndex + delta).clamp(
      0,
      visibleSheets.length - 1,
    );
    if (targetVisibleIndex == visibleIndex) return;

    moveSheetToVisibleIndex(id, targetVisibleIndex);
  }

  /// Moves a visible sheet to a target visible tab position.
  void moveSheetToVisibleIndex(String id, int targetVisibleIndex) {
    final savedSheets = _sheetsWithActiveSnapshot();
    final visibleSheets = [
      for (final sheet in savedSheets)
        if (!sheet.hidden) sheet,
    ];
    final visibleIndex = visibleSheets.indexWhere((sheet) => sheet.id == id);
    if (visibleIndex == -1 || visibleSheets.length <= 1) return;

    final normalizedTargetIndex = targetVisibleIndex.clamp(
      0,
      visibleSheets.length - 1,
    );
    if (normalizedTargetIndex == visibleIndex) return;

    final reorderedVisibleSheets = List<WorkbookSheet>.from(visibleSheets);
    final sheet = reorderedVisibleSheets.removeAt(visibleIndex);
    reorderedVisibleSheets.insert(normalizedTargetIndex, sheet);

    var visibleCursor = 0;
    final nextSheets = [
      for (final sheet in savedSheets)
        if (sheet.hidden) sheet else reorderedVisibleSheets[visibleCursor++],
    ];

    state = state.copyWith(sheets: nextSheets);
  }

  void deleteSheet(String id) {
    if (state.sheets.length <= 1) return;
    final savedSheets = _sheetsWithActiveSnapshot();
    final deleteIndex = savedSheets.indexWhere((sheet) => sheet.id == id);
    if (deleteIndex == -1) return;

    final target = savedSheets[deleteIndex];
    if (!target.hidden && _visibleSheetCount(savedSheets) <= 1) return;

    final wasActive = id == state.activeSheetId;
    final remaining = [
      for (final sheet in savedSheets)
        if (sheet.id != id) sheet,
    ];

    final nextActive = wasActive
        ? _nearestVisibleSheet(remaining, deleteIndex)
        : null;
    final nextActiveId = nextActive?.id ?? state.activeSheetId;

    state = SheetWorkbook(sheets: remaining, activeSheetId: nextActiveId);
    ref.read(recentWorkbookSheetIdsProvider.notifier).remove(id);
    if (wasActive && nextActive != null) {
      _loadSheet(nextActive);
    }
  }

  /// Hides a visible sheet while keeping at least one sheet available.
  void hideSheet(String id) {
    final savedSheets = _sheetsWithActiveSnapshot();
    final index = savedSheets.indexWhere((sheet) => sheet.id == id);
    if (index == -1 || savedSheets[index].hidden) return;
    if (_visibleSheetCount(savedSheets) <= 1) return;

    final nextSheets = [
      for (final sheet in savedSheets)
        if (sheet.id == id) sheet.copyWith(hidden: true) else sheet,
    ];

    if (id != state.activeSheetId) {
      state = state.copyWith(sheets: nextSheets);
      return;
    }

    final nextActive = _nearestVisibleSheet(nextSheets, index);
    if (nextActive == null) return;

    state = SheetWorkbook(sheets: nextSheets, activeSheetId: nextActive.id);
    _loadSheet(nextActive);
  }

  /// Makes a hidden sheet visible again, optionally switching to it.
  void unhideSheet(String id, {bool makeActive = false}) {
    final savedSheets = _sheetsWithActiveSnapshot();
    final index = savedSheets.indexWhere((sheet) => sheet.id == id);
    if (index == -1) return;

    final nextSheets = [
      for (final sheet in savedSheets)
        if (sheet.id == id) sheet.copyWith(hidden: false) else sheet,
    ];

    if (!makeActive) {
      state = state.copyWith(sheets: nextSheets);
      return;
    }

    final target = nextSheets[index];
    state = SheetWorkbook(sheets: nextSheets, activeSheetId: target.id);
    _loadSheet(target);
  }

  Map<String, dynamic> exportToJson() {
    final workbook = state.copyWith(sheets: _sheetsWithActiveSnapshot());
    return SheetWorkbookCodec.encode(workbook);
  }

  Map<String, dynamic> exportToSheetEngineJson() {
    final workbook = state.copyWith(sheets: _sheetsWithActiveSnapshot());
    return SheetEngineCodec.encodeWorkbook(workbook);
  }

  void importFromJson(Map<String, dynamic> json) {
    final workbook = SheetWorkbookCodec.decode(json);
    _replaceWorkbook(workbook);
  }

  void importFromSheetEngineJson(Map<String, dynamic> json) {
    final workbook = SheetEngineCodec.decodeWorkbook(json);
    _replaceWorkbook(workbook);
  }

  void importFromAnyJson(Map<String, dynamic> json) {
    if (SheetEngineCodec.isSheetEngineJson(json)) {
      importFromSheetEngineJson(json);
      return;
    }
    importFromJson(json);
  }

  void _replaceWorkbook(SheetWorkbook workbook) {
    final normalizedWorkbook = _normalizeWorkbookVisibility(workbook);
    state = normalizedWorkbook;
    _nextSheetNumber = normalizedWorkbook.sheets.length + 1;
    ref.read(recentWorkbookSheetIdsProvider.notifier).clear();
    ref
        .read(sheetEngineOperationLogProvider.notifier)
        .clear(documentId: normalizedWorkbook.activeSheet.id);
    _loadSheet(normalizedWorkbook.activeSheet);
  }

  List<WorkbookSheet> _sheetsWithActiveSnapshot() {
    return [
      for (final sheet in state.sheets)
        if (sheet.id == state.activeSheetId) _captureSheet(sheet) else sheet,
    ];
  }

  WorkbookSheet _captureSheet(WorkbookSheet sheet) {
    return sheet.copyWith(
      cells: Map.of(ref.read(spreadsheetProvider)),
      metadata: _captureMetadata(),
    );
  }

  SheetMetadata _captureMetadata() {
    return SheetMetadata(
      conditionalFormatRules: List.of(ref.read(conditionalFormatRulesProvider)),
      namedRanges: List.of(ref.read(sheetNamedRangesProvider)),
      rowConfig: Map.of(ref.read(rowConfigProvider)),
      columnConfig: Map.of(ref.read(columnConfigProvider)),
      filters: Map.of(ref.read(filterProvider)),
      filterRules: Map.of(ref.read(sheetFilterRulesProvider)),
      tables: List.of(ref.read(sheetTablesProvider)),
      sortColumn: ref.read(sortColumnProvider),
      sortAscending: ref.read(sortAscendingProvider),
      freezePane: ref.read(freezePanesProvider),
      zoom: ref.read(zoomLevelProvider),
    );
  }

  void _loadSheet(WorkbookSheet sheet) {
    ref
        .read(sheetEngineOperationLogProvider.notifier)
        .configure(documentId: sheet.id);
    ref.read(spreadsheetProvider.notifier).restoreSheetState(sheet.cells);
    _loadMetadata(sheet.metadata);
    ref.read(selectedCellProvider.notifier).state = null;
    ref.read(editingCellProvider.notifier).state = null;
    ref.read(editingCellDraftProvider.notifier).state = null;
    ref.read(formulaReferencePreviewProvider.notifier).state = const [];
    ref.read(formulaReferencePreviewContextProvider.notifier).state = null;
    ref.read(searchQueryProvider.notifier).state = '';
    ref.read(searchResultsProvider.notifier).state = [];
    ref.read(currentSearchIndexProvider.notifier).state = 0;
    ref.read(findReplaceQueryProvider.notifier).state = '';
    ref.read(findReplaceReplacementProvider.notifier).state = '';
    ref.read(findReplaceCurrentIndexProvider.notifier).state = 0;
    ref.read(recentWorkbookSheetIdsProvider.notifier).record(sheet.id);
  }

  void _loadMetadata(SheetMetadata metadata) {
    ref.read(conditionalFormatRulesProvider.notifier).state = List.of(
      metadata.conditionalFormatRules,
    );
    ref
        .read(sheetNamedRangesProvider.notifier)
        .replaceAll(metadata.namedRanges);
    ref.read(rowConfigProvider.notifier).state = Map.of(metadata.rowConfig);
    ref.read(columnConfigProvider.notifier).state = Map.of(
      metadata.columnConfig,
    );
    ref.read(filterProvider.notifier).state = Map.of(metadata.filters);
    ref.read(sheetFilterRulesProvider.notifier).state = Map.of(
      metadata.filterRules,
    );
    ref.read(sheetTablesProvider.notifier).replaceAll(metadata.tables);
    ref.read(sortColumnProvider.notifier).state = metadata.sortColumn;
    ref.read(sortAscendingProvider.notifier).state = metadata.sortAscending;
    ref.read(freezePanesProvider.notifier).state = metadata.freezePane;
    ref.read(zoomLevelProvider.notifier).state = metadata.zoom;
  }

  String _nextSheetId() {
    return 'sheet-${DateTime.now().microsecondsSinceEpoch}-${_nextSheetNumber++}';
  }

  String _nextSheetName(List<WorkbookSheet> sheets) {
    return _uniqueName('Sheet${sheets.length + 1}', sheets);
  }

  SheetWorkbook _normalizeWorkbookVisibility(SheetWorkbook workbook) {
    if (workbook.sheets.isEmpty) return SheetWorkbook.initial();

    var sheets = workbook.sheets;
    if (_visibleSheetCount(sheets) == 0) {
      sheets = [
        for (final entry in sheets.indexed)
          entry.$1 == 0 ? entry.$2.copyWith(hidden: false) : entry.$2,
      ];
    }

    final activeVisible = sheets.any(
      (sheet) => sheet.id == workbook.activeSheetId && !sheet.hidden,
    );
    final activeSheetId = activeVisible
        ? workbook.activeSheetId
        : sheets.firstWhere((sheet) => !sheet.hidden).id;

    return SheetWorkbook(sheets: sheets, activeSheetId: activeSheetId);
  }

  WorkbookSheet? _nearestVisibleSheet(List<WorkbookSheet> sheets, int index) {
    for (var cursor = index + 1; cursor < sheets.length; cursor += 1) {
      if (!sheets[cursor].hidden) return sheets[cursor];
    }

    for (var cursor = index - 1; cursor >= 0; cursor -= 1) {
      if (!sheets[cursor].hidden) return sheets[cursor];
    }

    return null;
  }

  int _visibleSheetCount(List<WorkbookSheet> sheets) {
    return sheets.where((sheet) => !sheet.hidden).length;
  }

  String _uniqueName(
    String baseName,
    List<WorkbookSheet> sheets, [
    String? ignoreId,
  ]) {
    final names = {
      for (final sheet in sheets)
        if (sheet.id != ignoreId) sheet.name.toLowerCase(),
    };
    if (!names.contains(baseName.toLowerCase())) return baseName;

    var suffix = 2;
    while (names.contains('$baseName $suffix'.toLowerCase())) {
      suffix++;
    }
    return '$baseName $suffix';
  }
}
