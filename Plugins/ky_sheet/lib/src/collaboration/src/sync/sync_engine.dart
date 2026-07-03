import 'operation.dart';
import '../crdt/document_crdt.dart';

/// Sync engine for managing real-time collaboration state.
/// 
/// Handles sending and receiving operations, managing pending operations,
/// and ensuring eventual consistency across all clients.
class SyncEngine {
  /// Unique identifier for this client
  final String clientId;
  
  /// Reference to the document CRDT
  final DocumentCRDT document;
  
  /// Pending operations waiting for acknowledgment
  final List<Operation> _pendingOperations = [];
  
  /// Operation history for undo/redo
  final List<Operation> _operationHistory = [];
  
  /// Sequence number for local operations
  int _sequenceNumber = 0;
  
  /// Callbacks
  Function(Operation)? onOperationReady;
  Function(List<Operation>)? onOperationsReceived;
  Function(String error)? onError;
  
  SyncEngine({
    required this.clientId,
    required this.document,
  });
  
  /// Generate a unique operation ID
  String _generateOperationId() {
    return '${clientId}_${_sequenceNumber++}_${DateTime.now().millisecondsSinceEpoch}';
  }
  
  /// Create and apply a cell set operation locally
  void setCell(String sheetId, String cellId, dynamic value, {String? formula}) {
    final operation = CellSetOperation(
      id: _generateOperationId(),
      clientId: clientId,
      timestamp: DateTime.now(),
      vectorClock: _getVectorClock(),
      sheetId: sheetId,
      cellId: cellId,
      value: value,
      formula: formula,
    );
    
    _applyLocalOperation(operation);
  }
  
  /// Create and apply a cell clear operation locally
  void clearCell(String sheetId, String cellId) {
    final operation = CellClearOperation(
      id: _generateOperationId(),
      clientId: clientId,
      timestamp: DateTime.now(),
      vectorClock: _getVectorClock(),
      sheetId: sheetId,
      cellId: cellId,
    );
    
    _applyLocalOperation(operation);
  }
  
  /// Create and apply a merge cells operation locally
  void mergeCells(String sheetId, String range, {bool unmerge = false}) {
    final operation = MergeCellsOperation(
      id: _generateOperationId(),
      clientId: clientId,
      timestamp: DateTime.now(),
      vectorClock: _getVectorClock(),
      sheetId: sheetId,
      range: range,
      unmerge: unmerge,
    );
    
    _applyLocalOperation(operation);
  }
  
  /// Create and apply a row/column operation locally
  void rowColumnOp(
    String sheetId,
    String operationType,
    int index, {
    int count = 1,
  }) {
    final operation = RowColumnOperation(
      id: _generateOperationId(),
      clientId: clientId,
      timestamp: DateTime.now(),
      vectorClock: _getVectorClock(),
      sheetId: sheetId,
      operationType: operationType,
      index: index,
      count: count,
    );
    
    _applyLocalOperation(operation);
  }
  
  /// Apply a local operation
  void _applyLocalOperation(Operation operation) {
    // Add to pending operations
    _pendingOperations.add(operation);
    
    // Add to history
    _operationHistory.add(operation);
    
    // Notify that operation is ready to send
    if (onOperationReady != null) {
      onOperationReady!(operation);
    }
  }
  
  /// Acknowledge that an operation was received by server/other clients
  void acknowledgeOperation(String operationId) {
    _pendingOperations.removeWhere((op) => op.id == operationId);
  }
  
  /// Receive and apply remote operations
  void receiveOperations(List<Operation> operations) {
    for (final operation in operations) {
      // Skip our own operations
      if (operation.clientId == clientId) {
        continue;
      }
      
      _applyRemoteOperation(operation);
    }
    
    // Notify about received operations
    if (onOperationsReceived != null) {
      onOperationsReceived!(operations);
    }
  }
  
  /// Apply a remote operation to the document
  void _applyRemoteOperation(Operation operation) {
    try {
      final sheet = document.getSheet(operation.sheetId);
      if (sheet == null) {
        onError?.call('Sheet not found: ${operation.sheetId}');
        return;
      }
      
      // Apply based on operation type
      if (operation is CellSetOperation) {
        sheet.applyRemoteCellOperation(CellOperation(
          cellId: operation.cellId,
          value: _toCellValue(operation.value),
          clientId: operation.clientId,
          timestamp: operation.timestamp,
          vectorClock: operation.vectorClock,
        ));
      } else if (operation is CellClearOperation) {
        // Clear cell logic
        sheet.applyRemoteCellOperation(CellOperation(
          cellId: operation.cellId,
          value: _toCellValue(null),
          clientId: operation.clientId,
          timestamp: operation.timestamp,
          vectorClock: operation.vectorClock,
        ));
      } else if (operation is MergeCellsOperation) {
        if (operation.unmerge) {
          sheet.unmergeCells(operation.range, operation.clientId);
        } else {
          sheet.mergeCells(operation.range, operation.clientId);
        }
      } else if (operation is RowColumnOperation) {
        // Handle row/column operations
        // TODO: Implement in SheetCRDT
      }
      
      // Add to history
      _operationHistory.add(operation);
    } catch (e) {
      onError?.call('Error applying operation: $e');
    }
  }
  
  /// Get current vector clock from document
  Map<String, int> _getVectorClock() {
    // In a real implementation, this would get the merged vector clock
    // from all sheets in the document
    return {clientId: _sequenceNumber};
  }
  
  /// Convert dynamic value to CellValue (placeholder)
  dynamic _toCellValue(dynamic value) {
    // In a real implementation, this would convert to proper CellValue type
    return value;
  }
  
  /// Get pending operations count
  int get pendingOperationsCount => _pendingOperations.length;
  
  /// Get operation history
  List<Operation> get history => List.unmodifiable(_operationHistory);
  
  /// Clear old operations from history (keep last N)
  void trimHistory(int keepCount) {
    if (_operationHistory.length > keepCount) {
      _operationHistory.removeRange(0, _operationHistory.length - keepCount);
    }
  }
  
  /// Serialize sync state for persistence
  Map<String, dynamic> toJson() {
    return {
      'clientId': clientId,
      'sequenceNumber': _sequenceNumber,
      'pendingOperations': _pendingOperations.map((op) => op.toJson()).toList(),
      'historyLength': _operationHistory.length,
    };
  }
  
  /// Deserialize sync state
  factory SyncEngine.fromJson(Map<String, dynamic> json, DocumentCRDT document) {
    final engine = SyncEngine(
      clientId: json['clientId'] as String,
      document: document,
    );
    
    engine._sequenceNumber = json['sequenceNumber'] as int;
    
    // Note: pending operations and history would need to be reconstructed
    // based on the document state
    
    return engine;
  }
}
