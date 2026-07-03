import '../model/cell/cell_address.dart';
import '../model/cell/cell_data.dart';
import 'sheet_engine_codec.dart';

class SheetEngineOperationReplayResult {
  const SheetEngineOperationReplayResult({
    required this.cells,
    required this.appliedEditCount,
    required this.shouldRecalculate,
    this.skippedOperationCount = 0,
  });

  final Map<CellAddress, CellData> cells;
  final int appliedEditCount;
  final bool shouldRecalculate;
  final int skippedOperationCount;

  bool get hasAppliedEdits => appliedEditCount > 0;
  bool get hasSkippedOperations => skippedOperationCount > 0;
}

class SheetEngineOperationReplayer {
  const SheetEngineOperationReplayer._();

  static SheetEngineOperationReplayResult applyEdit({
    required Map<CellAddress, CellData> cells,
    required Object? edit,
  }) {
    return applyEdits(cells: cells, edits: [edit]);
  }

  static SheetEngineOperationReplayResult applyOperation({
    required Map<CellAddress, CellData> cells,
    required Map<String, dynamic> operation,
    String? expectedDocumentId,
  }) {
    if (!_targetsDocument(operation, expectedDocumentId)) {
      return SheetEngineOperationReplayResult(
        cells: Map<CellAddress, CellData>.from(cells),
        appliedEditCount: 0,
        shouldRecalculate: false,
        skippedOperationCount: 1,
      );
    }

    return applyEdit(cells: cells, edit: operation['edit']);
  }

  static SheetEngineOperationReplayResult applyOperationLog({
    required Map<CellAddress, CellData> cells,
    required Map<String, dynamic> operationLog,
    String? expectedDocumentId,
  }) {
    final operationsJson = operationLog['operations'];
    if (operationsJson is! List) {
      return SheetEngineOperationReplayResult(
        cells: Map<CellAddress, CellData>.from(cells),
        appliedEditCount: 0,
        shouldRecalculate: false,
      );
    }

    final draft = Map<CellAddress, CellData>.from(cells);
    var appliedEditCount = 0;
    var skippedOperationCount = 0;
    var shouldRecalculate = false;

    for (final operationJson in operationsJson) {
      if (operationJson is! Map) {
        skippedOperationCount++;
        continue;
      }

      final operation = Map<String, dynamic>.from(operationJson);
      if (!_targetsDocument(operation, expectedDocumentId)) {
        skippedOperationCount++;
        continue;
      }

      final outcome = _applyEdit(draft, operation['edit']);
      if (!outcome.applied) {
        skippedOperationCount++;
        continue;
      }

      appliedEditCount++;
      shouldRecalculate = shouldRecalculate || outcome.shouldRecalculate;
    }

    return SheetEngineOperationReplayResult(
      cells: draft,
      appliedEditCount: appliedEditCount,
      shouldRecalculate: shouldRecalculate,
      skippedOperationCount: skippedOperationCount,
    );
  }

  static SheetEngineOperationReplayResult applyEdits({
    required Map<CellAddress, CellData> cells,
    required Iterable<Object?> edits,
  }) {
    final draft = Map<CellAddress, CellData>.from(cells);
    var appliedEditCount = 0;
    var shouldRecalculate = false;

    for (final edit in edits) {
      final outcome = _applyEdit(draft, edit);
      if (!outcome.applied) continue;
      appliedEditCount++;
      shouldRecalculate = shouldRecalculate || outcome.shouldRecalculate;
    }

    return SheetEngineOperationReplayResult(
      cells: draft,
      appliedEditCount: appliedEditCount,
      shouldRecalculate: shouldRecalculate,
    );
  }

  static _ReplayEditOutcome _applyEdit(
    Map<CellAddress, CellData> draft,
    Object? edit,
  ) {
    if (edit == 'Recalculate') {
      return const _ReplayEditOutcome(applied: true, shouldRecalculate: true);
    }

    if (edit is! Map || edit.isEmpty) {
      return const _ReplayEditOutcome(applied: false, shouldRecalculate: false);
    }

    final editMap = Map<String, dynamic>.from(edit);
    if (editMap.containsKey('SetCell')) {
      return _applySetCell(draft, editMap['SetCell']);
    }
    if (editMap.containsKey('ClearCell')) {
      return _applyClearCell(draft, editMap['ClearCell']);
    }
    if (editMap.containsKey('SetCellFormat')) {
      return _applySetCellFormat(draft, editMap['SetCellFormat']);
    }

    return const _ReplayEditOutcome(applied: false, shouldRecalculate: false);
  }

  static _ReplayEditOutcome _applySetCell(
    Map<CellAddress, CellData> draft,
    dynamic payloadJson,
  ) {
    final payload = _asMap(payloadJson);
    final address = _decodePosition(payload?['position']);
    if (payload == null || address == null) {
      return const _ReplayEditOutcome(applied: false, shouldRecalculate: false);
    }

    final rawContent = payload['raw_content']?.toString() ?? '';
    final current = draft[address] ?? CellData();
    draft[address] = rawContent.startsWith('=')
        ? current.copyWith(formula: rawContent, value: '')
        : current.copyWith(value: rawContent, clearFormula: true);

    return const _ReplayEditOutcome(applied: true, shouldRecalculate: true);
  }

  static _ReplayEditOutcome _applyClearCell(
    Map<CellAddress, CellData> draft,
    dynamic payloadJson,
  ) {
    final payload = _asMap(payloadJson);
    final address = _decodePosition(payload?['position']);
    if (payload == null || address == null) {
      return const _ReplayEditOutcome(applied: false, shouldRecalculate: false);
    }

    draft.remove(address);
    return const _ReplayEditOutcome(applied: true, shouldRecalculate: true);
  }

  static _ReplayEditOutcome _applySetCellFormat(
    Map<CellAddress, CellData> draft,
    dynamic payloadJson,
  ) {
    final payload = _asMap(payloadJson);
    final address = _decodePosition(payload?['position']);
    if (payload == null || address == null) {
      return const _ReplayEditOutcome(applied: false, shouldRecalculate: false);
    }

    final current = draft[address] ?? CellData();
    draft[address] = current.copyWith(
      style: SheetEngineCodec.decodeCellFormat(payload['format']),
    );
    return const _ReplayEditOutcome(applied: true, shouldRecalculate: false);
  }

  static CellAddress? _decodePosition(dynamic positionJson) {
    final position = _asMap(positionJson);
    if (position == null) return null;

    final row = _asInt(position['row']);
    final col = _asInt(position['col']);
    if (row == null || col == null || row < 0 || col < 0) return null;

    return CellAddress(row, col);
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is! Map) return null;
    return Map<String, dynamic>.from(value);
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static bool _targetsDocument(
    Map<String, dynamic> operation,
    String? expectedDocumentId,
  ) {
    if (expectedDocumentId == null || expectedDocumentId.isEmpty) return true;
    return operation['document_id']?.toString() == expectedDocumentId;
  }
}

class _ReplayEditOutcome {
  const _ReplayEditOutcome({
    required this.applied,
    required this.shouldRecalculate,
  });

  final bool applied;
  final bool shouldRecalculate;
}
