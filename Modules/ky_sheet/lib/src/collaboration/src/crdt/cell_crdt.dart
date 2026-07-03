import 'package:ky_sheet/ky_sheet.dart';

/// A Conflict-Free Replicated Data Type (CRDT) for cell values.
/// 
/// This implementation uses a Last-Writer-Wins (LWW) strategy with vector clocks
/// to resolve conflicts in real-time collaborative editing scenarios.
class CellCRDT {
  /// Unique identifier for this cell (e.g., "A1", "B2")
  final String cellId;
  
  /// The current value of the cell
  CellValue? _value;
  
  /// Vector clock for conflict resolution
  final Map<String, int> _vectorClock = {};
  
  /// Timestamp of the last update
  DateTime _lastUpdated = DateTime.now();
  
  /// History of operations for undo/redo in collaborative context
  final List<CellOperation> _operationHistory = [];
  
  CellCRDT({required this.cellId, CellValue? initialValue}) {
    if (initialValue != null) {
      _value = initialValue;
    }
  }
  
  /// Get the current cell value
  CellValue? get value => _value;
  
  /// Get the vector clock
  Map<String, int> get vectorClock => Map.unmodifiable(_vectorClock);
  
  /// Get the last update timestamp
  DateTime get lastUpdated => _lastUpdated;
  
  /// Apply a local set operation
  void set(CellValue newValue, String clientId) {
    final operation = CellOperation(
      cellId: cellId,
      value: newValue,
      clientId: clientId,
      timestamp: DateTime.now(),
      vectorClock: _incrementVectorClock(clientId),
    );
    
    _applyOperation(operation);
    _operationHistory.add(operation);
  }
  
  /// Apply a remote operation from another client
  void applyRemote(CellOperation operation) {
    // Check if this operation is newer than our current state
    if (_shouldApply(operation)) {
      _applyOperation(operation);
      _operationHistory.add(operation);
      
      // Merge vector clocks
      _mergeVectorClock(operation.vectorClock);
    }
  }
  
  /// Determine if an operation should be applied based on vector clock
  bool _shouldApply(CellOperation operation) {
    // Last-Writer-Wins: compare timestamps if vector clocks are concurrent
    final comparison = _compareVectorClocks(operation.vectorClock);
    
    if (comparison > 0) {
      return true; // Operation is newer
    } else if (comparison < 0) {
      return false; // Operation is older
    } else {
      // Concurrent: use timestamp as tiebreaker
      return operation.timestamp.isAfter(_lastUpdated);
    }
  }
  
  /// Compare vector clocks: returns 1 if op is newer, -1 if older, 0 if concurrent
  int _compareVectorClocks(Map<String, int> opClock) {
    bool hasGreater = false;
    bool hasLesser = false;
    
    for (final entry in opClock.entries) {
      final clientId = entry.key;
      final opCount = entry.value;
      final localCount = _vectorClock[clientId] ?? 0;
      
      if (opCount > localCount) {
        hasGreater = true;
      } else if (opCount < localCount) {
        hasLesser = true;
      }
    }
    
    // Check for any entries in local clock not in op clock
    for (final clientId in _vectorClock.keys) {
      if (!opClock.containsKey(clientId)) {
        hasLesser = true;
      }
    }
    
    if (hasGreater && !hasLesser) return 1;
    if (hasLesser && !hasGreater) return -1;
    return 0; // Concurrent
  }
  
  /// Increment and return the updated vector clock
  Map<String, int> _incrementVectorClock(String clientId) {
    _vectorClock[clientId] = (_vectorClock[clientId] ?? 0) + 1;
    return Map.unmodifiable(_vectorClock);
  }
  
  /// Merge a remote vector clock with local clock
  void _mergeVectorClock(Map<String, int> remoteClock) {
    for (final entry in remoteClock.entries) {
      final clientId = entry.key;
      final remoteCount = entry.value;
      final localCount = _vectorClock[clientId] ?? 0;
      
      if (remoteCount > localCount) {
        _vectorClock[clientId] = remoteCount;
      }
    }
  }
  
  /// Apply an operation to the cell state
  void _applyOperation(CellOperation operation) {
    _value = operation.value;
    _lastUpdated = operation.timestamp;
    _vectorClock.addAll(operation.vectorClock);
  }
  
  /// Convert to JSON for serialization/transmission
  Map<String, dynamic> toJson() {
    return {
      'cellId': cellId,
      'value': _value?.toJson(),
      'vectorClock': _vectorClock,
      'lastUpdated': _lastUpdated.toIso8601String(),
    };
  }
  
  /// Create from JSON
  factory CellCRDT.fromJson(Map<String, dynamic> json) {
    final crdt = CellCRDT(cellId: json['cellId'] as String);
    if (json['value'] != null) {
      crdt._value = CellValue.fromJson(json['value'] as Map<String, dynamic>);
    }
    if (json['vectorClock'] != null) {
      crdt._vectorClock.addAll(
        Map<String, int>.from(json['vectorClock'] as Map),
      );
    }
    if (json['lastUpdated'] != null) {
      crdt._lastUpdated = DateTime.parse(json['lastUpdated'] as String);
    }
    return crdt;
  }
}

/// Represents an operation on a cell for collaborative editing
class CellOperation {
  final String cellId;
  final CellValue value;
  final String clientId;
  final DateTime timestamp;
  final Map<String, int> vectorClock;
  
  CellOperation({
    required this.cellId,
    required this.value,
    required this.clientId,
    required this.timestamp,
    required this.vectorClock,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'cellId': cellId,
      'value': value.toJson(),
      'clientId': clientId,
      'timestamp': timestamp.toIso8601String(),
      'vectorClock': vectorClock,
    };
  }
  
  factory CellOperation.fromJson(Map<String, dynamic> json) {
    return CellOperation(
      cellId: json['cellId'] as String,
      value: CellValue.fromJson(json['value'] as Map<String, dynamic>),
      clientId: json['clientId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      vectorClock: Map<String, int>.from(json['vectorClock'] as Map),
    );
  }
}
