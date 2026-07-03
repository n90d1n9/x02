import 'dart:convert';

enum SheetEngineOperationPayloadKind { edit, operation, operationLog }

class SheetEngineOperationPayload {
  const SheetEngineOperationPayload._({
    required this.kind,
    this.edit,
    this.operation,
    this.operationLog,
  });

  factory SheetEngineOperationPayload.edit(Object edit) {
    return SheetEngineOperationPayload._(
      kind: SheetEngineOperationPayloadKind.edit,
      edit: edit,
    );
  }

  factory SheetEngineOperationPayload.operation(
    Map<String, dynamic> operation,
  ) {
    return SheetEngineOperationPayload._(
      kind: SheetEngineOperationPayloadKind.operation,
      operation: operation,
    );
  }

  factory SheetEngineOperationPayload.operationLog(
    Map<String, dynamic> operationLog,
  ) {
    return SheetEngineOperationPayload._(
      kind: SheetEngineOperationPayloadKind.operationLog,
      operationLog: operationLog,
    );
  }

  final SheetEngineOperationPayloadKind kind;
  final Object? edit;
  final Map<String, dynamic>? operation;
  final Map<String, dynamic>? operationLog;
}

class SheetEngineOperationPayloadSummary {
  const SheetEngineOperationPayloadSummary({
    required this.kind,
    required this.operationCount,
    required this.matchingOperationCount,
    required this.skippedOperationCount,
    required this.targetDocumentIds,
  });

  factory SheetEngineOperationPayloadSummary.fromPayload(
    SheetEngineOperationPayload payload, {
    String? expectedDocumentId,
  }) {
    return switch (payload.kind) {
      SheetEngineOperationPayloadKind.edit =>
        const SheetEngineOperationPayloadSummary(
          kind: SheetEngineOperationPayloadKind.edit,
          operationCount: 1,
          matchingOperationCount: 1,
          skippedOperationCount: 0,
          targetDocumentIds: [],
        ),
      SheetEngineOperationPayloadKind.operation => _fromOperations(
        kind: SheetEngineOperationPayloadKind.operation,
        operations: [payload.operation],
        expectedDocumentId: expectedDocumentId,
      ),
      SheetEngineOperationPayloadKind.operationLog => _fromOperations(
        kind: SheetEngineOperationPayloadKind.operationLog,
        operations: payload.operationLog?['operations'],
        expectedDocumentId: expectedDocumentId,
      ),
    };
  }

  final SheetEngineOperationPayloadKind kind;
  final int operationCount;
  final int matchingOperationCount;
  final int skippedOperationCount;
  final List<String> targetDocumentIds;

  String get kindLabel {
    return switch (kind) {
      SheetEngineOperationPayloadKind.edit => 'Sheet edit',
      SheetEngineOperationPayloadKind.operation => 'Operation',
      SheetEngineOperationPayloadKind.operationLog => 'Operation log',
    };
  }

  String get targetDocumentsLabel {
    if (targetDocumentIds.isEmpty) return 'No document target';
    if (targetDocumentIds.length == 1) return targetDocumentIds.single;
    return targetDocumentIds.join(', ');
  }

  static SheetEngineOperationPayloadSummary _fromOperations({
    required SheetEngineOperationPayloadKind kind,
    required dynamic operations,
    String? expectedDocumentId,
  }) {
    final operationList = operations is List ? operations : [operations];
    var matching = 0;
    var skipped = 0;
    final documents = <String>{};

    for (final operationJson in operationList) {
      if (operationJson is! Map) {
        skipped++;
        continue;
      }

      final operation = Map<String, dynamic>.from(operationJson);
      final documentId = operation['document_id']?.toString();
      if (documentId == null || documentId.isEmpty) {
        documents.add('unknown');
      } else {
        documents.add(documentId);
      }

      if (expectedDocumentId == null || expectedDocumentId.isEmpty) {
        matching++;
      } else if (documentId == expectedDocumentId) {
        matching++;
      } else {
        skipped++;
      }
    }

    return SheetEngineOperationPayloadSummary(
      kind: kind,
      operationCount: operationList.length,
      matchingOperationCount: matching,
      skippedOperationCount: skipped,
      targetDocumentIds: documents.toList()..sort(),
    );
  }
}

class SheetEngineOperationPayloadParser {
  const SheetEngineOperationPayloadParser._();

  static SheetEngineOperationPayload parseText(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Paste a Waraq JSON payload first');
    }

    return parse(jsonDecode(trimmed));
  }

  static SheetEngineOperationPayloadSummary summarizeText(
    String text, {
    String? expectedDocumentId,
  }) {
    return SheetEngineOperationPayloadSummary.fromPayload(
      parseText(text),
      expectedDocumentId: expectedDocumentId,
    );
  }

  static SheetEngineOperationPayload parse(Object? value) {
    if (value == 'Recalculate') {
      return SheetEngineOperationPayload.edit(value!);
    }

    if (value is! Map) {
      throw const FormatException(
        'Expected a Waraq SheetEdit, operation, or operation log',
      );
    }

    final json = Map<String, dynamic>.from(value);
    if (json['operations'] is List) {
      return SheetEngineOperationPayload.operationLog(json);
    }
    if (json.containsKey('edit')) {
      return SheetEngineOperationPayload.operation(json);
    }
    if (_isEditJson(json)) {
      return SheetEngineOperationPayload.edit(json);
    }

    throw const FormatException(
      'Expected a Waraq SheetEdit, operation, or operation log',
    );
  }

  static bool _isEditJson(Map<String, dynamic> json) {
    return json.containsKey('SetCell') ||
        json.containsKey('ClearCell') ||
        json.containsKey('SetCellFormat');
  }
}
