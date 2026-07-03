import 'package:flutter_riverpod/legacy.dart';

import '../utils/sheet_engine_edit_codec.dart';

final sheetEngineOperationLogProvider =
    StateNotifierProvider<
      SheetEngineOperationLogNotifier,
      SheetEngineOperationLogState
    >((ref) => SheetEngineOperationLogNotifier());

class SheetEngineOperationLogState {
  SheetEngineOperationLogState({
    this.documentId = 'sheet-1',
    this.actorId = 'ky-sheet',
    this.nextSequence = 1,
    List<Map<String, dynamic>> operations = const [],
  }) : operations = List.unmodifiable(operations);

  final String documentId;
  final String actorId;
  final int nextSequence;
  final List<Map<String, dynamic>> operations;

  bool get isEmpty => operations.isEmpty;

  SheetEngineOperationLogState copyWith({
    String? documentId,
    String? actorId,
    int? nextSequence,
    List<Map<String, dynamic>>? operations,
  }) {
    return SheetEngineOperationLogState(
      documentId: documentId ?? this.documentId,
      actorId: actorId ?? this.actorId,
      nextSequence: nextSequence ?? this.nextSequence,
      operations: operations ?? this.operations,
    );
  }

  Map<String, dynamic> toJson() {
    return SheetEngineEditCodec.operationLog(
      operations,
      metadata: {'document_id': documentId, 'actor_id': actorId},
    );
  }
}

class SheetEngineOperationLogNotifier
    extends StateNotifier<SheetEngineOperationLogState> {
  SheetEngineOperationLogNotifier({DateTime Function()? now})
    : _now = now ?? DateTime.now,
      super(SheetEngineOperationLogState());

  final DateTime Function() _now;

  void configure({String? documentId, String? actorId}) {
    state = state.copyWith(documentId: documentId, actorId: actorId);
  }

  void clear({String? documentId, String? actorId}) {
    state = SheetEngineOperationLogState(
      documentId: documentId ?? state.documentId,
      actorId: actorId ?? state.actorId,
    );
  }

  void appendEdits(
    Iterable<Object> edits, {
    String source = 'ky_sheet',
    String? description,
  }) {
    final editList = edits.toList(growable: false);
    if (editList.isEmpty) return;

    var sequence = state.nextSequence;
    final operations = <Map<String, dynamic>>[];
    final timestampMs = _now().millisecondsSinceEpoch;

    for (final edit in editList) {
      operations.add(
        SheetEngineEditCodec.operation(
          operationId: 'ky-sheet-op-$sequence',
          documentId: state.documentId,
          actorId: state.actorId,
          sequence: sequence,
          timestampMs: timestampMs,
          edit: edit,
          metadata: {
            if (source.isNotEmpty) 'source': source,
            if (description != null && description.isNotEmpty)
              'description': description,
          },
        ),
      );
      sequence++;
    }

    state = state.copyWith(
      operations: [...state.operations, ...operations],
      nextSequence: sequence,
    );
  }

  Map<String, dynamic> exportLog() {
    return state.toJson();
  }
}
