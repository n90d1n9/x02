import '../crdt/document_crdt.dart';
import 'operation.dart';

/// Collaborative history manager for undo/redo in multi-user environments.
/// 
/// Tracks operations from all users and provides intelligent undo/redo
/// that respects causality and doesn't interfere with other users' changes.
class CollaborativeHistory {
  /// Reference to the document
  final DocumentCRDT document;
  
  /// Current client ID (for filtering own operations)
  final String clientId;
  
  /// Full operation history from all clients
  final List<Operation> _allOperations = [];
  
  /// Undo stack for this client
  final List<Operation> _undoStack = [];
  
  /// Redo stack for this client
  final List<Operation> _redoStack = [];
  
  /// Maximum history size
  final int maxHistorySize;
  
  CollaborativeHistory({
    required this.document,
    required this.clientId,
    this.maxHistorySize = 1000,
  });
  
  /// Add an operation to history
  void addOperation(Operation operation) {
    _allOperations.add(operation);
    
    // Only add own operations to undo stack
    if (operation.clientId == clientId) {
      _undoStack.add(operation);
      _redoStack.clear(); // Clear redo stack on new operation
      
      // Trim history if needed
      _trimHistory();
    }
  }
  
  /// Undo the last operation by this client
  Operation? undo() {
    if (_undoStack.isEmpty) {
      return null;
    }
    
    final operation = _undoStack.removeLast();
    _redoStack.add(operation);
    
    // Generate inverse operation
    final inverse = _createInverseOperation(operation);
    
    return inverse;
  }
  
  /// Redo the last undone operation
  Operation? redo() {
    if (_redoStack.isEmpty) {
      return null;
    }
    
    final operation = _redoStack.removeLast();
    _undoStack.add(operation);
    
    // Re-apply the original operation
    return operation;
  }
  
  /// Create an inverse operation for undo
  Operation _createInverseOperation(Operation operation) {
    if (operation is CellSetOperation) {
      // Get current value to store in inverse
      final sheet = document.getSheet(operation.sheetId);
      final currentValue = sheet?.getCellValue(operation.cellId);
      
      // Return clear operation if we're undoing a set
      return CellClearOperation(
        id: 'inverse_${operation.id}',
        clientId: clientId,
        timestamp: DateTime.now(),
        vectorClock: operation.vectorClock,
        sheetId: operation.sheetId,
        cellId: operation.cellId,
      );
    } else if (operation is CellClearOperation) {
      // Can't undo a clear without knowing the previous value
      // In a real implementation, we'd store the previous value
      throw UnsupportedError('Cannot undo cell clear without previous value');
    } else if (operation is MergeCellsOperation) {
      return MergeCellsOperation(
        id: 'inverse_${operation.id}',
        clientId: clientId,
        timestamp: DateTime.now(),
        vectorClock: operation.vectorClock,
        sheetId: operation.sheetId,
        range: operation.range,
        unmerge: !operation.unmerge,
      );
    } else if (operation is RowColumnOperation) {
      // Calculate inverse for row/column operations
      String inverseType;
      switch (operation.operationType) {
        case 'insert_row':
          inverseType = 'delete_row';
          break;
        case 'delete_row':
          inverseType = 'insert_row';
          break;
        case 'insert_column':
          inverseType = 'delete_column';
          break;
        case 'delete_column':
          inverseType = 'insert_column';
          break;
        default:
          throw UnsupportedError('Unknown operation type: ${operation.operationType}');
      }
      
      return RowColumnOperation(
        id: 'inverse_${operation.id}',
        clientId: clientId,
        timestamp: DateTime.now(),
        vectorClock: operation.vectorClock,
        sheetId: operation.sheetId,
        operationType: inverseType,
        index: operation.index,
        count: operation.count,
      );
    }
    
    throw UnsupportedError('Cannot create inverse for operation type: ${operation.runtimeType}');
  }
  
  /// Get operations by a specific user
  List<Operation> getOperationsByUser(String userId) {
    return _allOperations.where((op) => op.clientId == userId).toList();
  }
  
  /// Get operations in a time range
  List<Operation> getOperationsInTimeRange(DateTime start, DateTime end) {
    return _allOperations
        .where((op) => op.timestamp.isAfter(start) && op.timestamp.isBefore(end))
        .toList();
  }
  
  /// Get all operations
  List<Operation> getAllOperations() => List.unmodifiable(_allOperations);
  
  /// Check if undo is available
  bool get canUndo => _undoStack.isNotEmpty;
  
  /// Check if redo is available
  bool get canRedo => _redoStack.isNotEmpty;
  
  /// Get undo stack size
  int get undoStackSize => _undoStack.length;
  
  /// Get redo stack size
  int get redoStackSize => _redoStack.length;
  
  /// Trim history to maximum size
  void _trimHistory() {
    if (_allOperations.length > maxHistorySize) {
      final toRemove = _allOperations.length - maxHistorySize;
      _allOperations.removeRange(0, toRemove);
    }
  }
  
  /// Clear all history
  void clear() {
    _allOperations.clear();
    _undoStack.clear();
    _redoStack.clear();
  }
  
  /// Export history for persistence
  Map<String, dynamic> toJson() {
    return {
      'clientId': clientId,
      'allOperationsCount': _allOperations.length,
      'undoStackSize': _undoStack.length,
      'redoStackSize': _redoStack.length,
      'operations': _allOperations.map((op) => op.toJson()).toList(),
    };
  }
  
  /// Import history from persistence
  factory CollaborativeHistory.fromJson(
    Map<String, dynamic> json,
    DocumentCRDT document,
  ) {
    final history = CollaborativeHistory(
      document: document,
      clientId: json['clientId'] as String,
    );
    
    if (json['operations'] != null) {
      for (final opJson in json['operations'] as List) {
        final operation = Operation.fromJson(opJson as Map<String, dynamic>);
        history._allOperations.add(operation);
        
        if (operation.clientId == history.clientId) {
          history._undoStack.add(operation);
        }
      }
    }
    
    return history;
  }
}
