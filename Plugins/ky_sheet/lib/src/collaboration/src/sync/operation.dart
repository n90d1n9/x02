/// Base operation class for collaborative editing.
abstract class Operation {
  /// Unique identifier for this operation
  final String id;
  
  /// Client/user who created this operation
  final String clientId;
  
  /// Timestamp when operation was created
  final DateTime timestamp;
  
  /// Vector clock for causality tracking
  final Map<String, int> vectorClock;
  
  /// Target sheet ID
  final String sheetId;
  
  Operation({
    required this.id,
    required this.clientId,
    required this.timestamp,
    required this.vectorClock,
    required this.sheetId,
  });
  
  /// Serialize operation to JSON
  Map<String, dynamic> toJson();
  
  /// Create operation from JSON
  factory Operation.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    switch (type) {
      case 'cell_set':
        return CellSetOperation.fromJson(json);
      case 'cell_clear':
        return CellClearOperation.fromJson(json);
      case 'merge_cells':
        return MergeCellsOperation.fromJson(json);
      case 'row_column_op':
        return RowColumnOperation.fromJson(json);
      default:
        throw FormatException('Unknown operation type: $type');
    }
  }
}

/// Operation to set a cell value
class CellSetOperation extends Operation {
  final String cellId;
  final dynamic value;
  final String? formula;
  
  CellSetOperation({
    required String id,
    required String clientId,
    required DateTime timestamp,
    required Map<String, int> vectorClock,
    required String sheetId,
    required this.cellId,
    required this.value,
    this.formula,
  }) : super(
    id: id,
    clientId: clientId,
    timestamp: timestamp,
    vectorClock: vectorClock,
    sheetId: sheetId,
  );
  
  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'cell_set',
      'id': id,
      'clientId': clientId,
      'timestamp': timestamp.toIso8601String(),
      'vectorClock': vectorClock,
      'sheetId': sheetId,
      'cellId': cellId,
      'value': value,
      'formula': formula,
    };
  }
  
  factory CellSetOperation.fromJson(Map<String, dynamic> json) {
    return CellSetOperation(
      id: json['id'] as String,
      clientId: json['clientId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      vectorClock: Map<String, int>.from(json['vectorClock'] as Map),
      sheetId: json['sheetId'] as String,
      cellId: json['cellId'] as String,
      value: json['value'],
      formula: json['formula'] as String?,
    );
  }
}

/// Operation to clear a cell
class CellClearOperation extends Operation {
  final String cellId;
  
  CellClearOperation({
    required String id,
    required String clientId,
    required DateTime timestamp,
    required Map<String, int> vectorClock,
    required String sheetId,
    required this.cellId,
  }) : super(
    id: id,
    clientId: clientId,
    timestamp: timestamp,
    vectorClock: vectorClock,
    sheetId: sheetId,
  );
  
  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'cell_clear',
      'id': id,
      'clientId': clientId,
      'timestamp': timestamp.toIso8601String(),
      'vectorClock': vectorClock,
      'sheetId': sheetId,
      'cellId': cellId,
    };
  }
  
  factory CellClearOperation.fromJson(Map<String, dynamic> json) {
    return CellClearOperation(
      id: json['id'] as String,
      clientId: json['clientId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      vectorClock: Map<String, int>.from(json['vectorClock'] as Map),
      sheetId: json['sheetId'] as String,
      cellId: json['cellId'] as String,
    );
  }
}

/// Operation to merge cells
class MergeCellsOperation extends Operation {
  final String range;
  final bool unmerge;
  
  MergeCellsOperation({
    required String id,
    required String clientId,
    required DateTime timestamp,
    required Map<String, int> vectorClock,
    required String sheetId,
    required this.range,
    this.unmerge = false,
  }) : super(
    id: id,
    clientId: clientId,
    timestamp: timestamp,
    vectorClock: vectorClock,
    sheetId: sheetId,
  );
  
  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'merge_cells',
      'id': id,
      'clientId': clientId,
      'timestamp': timestamp.toIso8601String(),
      'vectorClock': vectorClock,
      'sheetId': sheetId,
      'range': range,
      'unmerge': unmerge,
    };
  }
  
  factory MergeCellsOperation.fromJson(Map<String, dynamic> json) {
    return MergeCellsOperation(
      id: json['id'] as String,
      clientId: json['clientId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      vectorClock: Map<String, int>.from(json['vectorClock'] as Map),
      sheetId: json['sheetId'] as String,
      range: json['range'] as String,
      unmerge: json['unmerge'] as bool? ?? false,
    );
  }
}

/// Operation for row/column manipulation
class RowColumnOperation extends Operation {
  final String operationType; // 'insert_row', 'delete_row', 'insert_column', 'delete_column'
  final int index;
  final int? count;
  
  RowColumnOperation({
    required String id,
    required String clientId,
    required DateTime timestamp,
    required Map<String, int> vectorClock,
    required String sheetId,
    required this.operationType,
    required this.index,
    this.count = 1,
  }) : super(
    id: id,
    clientId: clientId,
    timestamp: timestamp,
    vectorClock: vectorClock,
    sheetId: sheetId,
  );
  
  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'row_column_op',
      'id': id,
      'clientId': clientId,
      'timestamp': timestamp.toIso8601String(),
      'vectorClock': vectorClock,
      'sheetId': sheetId,
      'operationType': operationType,
      'index': index,
      'count': count,
    };
  }
  
  factory RowColumnOperation.fromJson(Map<String, dynamic> json) {
    return RowColumnOperation(
      id: json['id'] as String,
      clientId: json['clientId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      vectorClock: Map<String, int>.from(json['vectorClock'] as Map),
      sheetId: json['sheetId'] as String,
      operationType: json['operationType'] as String,
      index: json['index'] as int,
      count: json['count'] as int?,
    );
  }
}
