import 'sheet_crdt.dart';

/// A CRDT for managing an entire document (workbook) with multiple sheets.
/// 
/// This is the top-level CRDT that coordinates multiple SheetCRDT instances
/// and handles document-level operations like sheet creation, deletion, and reordering.
class DocumentCRDT {
  /// Unique identifier for this document
  final String documentId;
  
  /// Map of sheet IDs to their CRDT state
  final Map<String, SheetCRDT> _sheets = {};
  
  /// Ordered list of sheet IDs (maintains tab order)
  final List<String> _sheetOrder = [];
  
  /// Vector clock for document-level operations
  final Map<String, int> _vectorClock = {};
  
  /// Document metadata
  String _title = 'Untitled Spreadsheet';
  DateTime _lastModified = DateTime.now();
  
  DocumentCRDT({required this.documentId});
  
  /// Get document title
  String get title => _title;
  
  /// Set document title
  void setTitle(String newTitle, String clientId) {
    _title = newTitle;
    _lastModified = DateTime.now();
    _incrementVectorClock(clientId);
  }
  
  /// Create a new sheet
  void createSheet({String? sheetId, String? name, int? index, String? clientId}) {
    final id = sheetId ?? _generateSheetId();
    final sheetName = name ?? 'Sheet${_sheets.length + 1}';
    
    // TODO: Set sheet name when SheetCRDT supports it
    final sheet = SheetCRDT(sheetId: id);
    
    _sheets[id] = sheet;
    
    if (index != null && index >= 0 && index <= _sheetOrder.length) {
      _sheetOrder.insert(index, id);
    } else {
      _sheetOrder.add(id);
    }
    
    if (clientId != null) {
      _incrementVectorClock(clientId);
    }
    
    return;
  }
  
  /// Delete a sheet
  bool deleteSheet(String sheetId, String clientId) {
    if (_sheets.containsKey(sheetId)) {
      _sheets.remove(sheetId);
      _sheetOrder.remove(sheetId);
      _incrementVectorClock(clientId);
      return true;
    }
    return false;
  }
  
  /// Rename a sheet (TODO: implement in SheetCRDT)
  void renameSheet(String sheetId, String newName, String clientId) {
    // TODO: Implement when SheetCRDT supports names
    _incrementVectorClock(clientId);
  }
  
  /// Reorder sheets (move sheet from one position to another)
  void reorderSheet(int fromIndex, int toIndex, String clientId) {
    if (fromIndex >= 0 && 
        fromIndex < _sheetOrder.length && 
        toIndex >= 0 && 
        toIndex < _sheetOrder.length) {
      
      final sheetId = _sheetOrder.removeAt(fromIndex);
      _sheetOrder.insert(toIndex, sheetId);
      _incrementVectorClock(clientId);
    }
  }
  
  /// Get a sheet by ID
  SheetCRDT? getSheet(String sheetId) {
    return _sheets[sheetId];
  }
  
  /// Get the active/first sheet
  SheetCRDT? get activeSheet {
    if (_sheetOrder.isEmpty) return null;
    return _sheets[_sheetOrder.first];
  }
  
  /// Get all sheets
  List<SheetCRDT> get sheets {
    return _sheetOrder.map((id) => _sheets[id]!).toList();
  }
  
  /// Get sheet order
  List<String> get sheetOrder => List.unmodifiable(_sheetOrder);
  
  /// Get last modified timestamp
  DateTime get lastModified => _lastModified;
  
  /// Apply a remote sheet operation
  void applyRemoteSheetOperation(String sheetId, dynamic operation, String clientId) {
    if (!_sheets.containsKey(sheetId)) {
      createSheet(sheetId: sheetId, clientId: null);
    }
    
    // TODO: Handle different types of sheet operations
    _mergeVectorClock({clientId: 1});
  }
  
  String _generateSheetId() {
    return 'sheet_${DateTime.now().millisecondsSinceEpoch}_${_sheets.length}';
  }
  
  Map<String, int> _incrementVectorClock(String clientId) {
    _vectorClock[clientId] = (_vectorClock[clientId] ?? 0) + 1;
    return Map.unmodifiable(_vectorClock);
  }
  
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
  
  /// Serialize document state
  Map<String, dynamic> toJson() {
    return {
      'documentId': documentId,
      'title': _title,
      'lastModified': _lastModified.toIso8601String(),
      'sheetOrder': _sheetOrder,
      'sheets': _sheets.map((key, value) => MapEntry(key, value.toJson())),
      'vectorClock': _vectorClock,
    };
  }
  
  /// Deserialize document state
  factory DocumentCRDT.fromJson(Map<String, dynamic> json) {
    final doc = DocumentCRDT(documentId: json['documentId'] as String);
    
    if (json['title'] != null) {
      doc._title = json['title'] as String;
    }
    
    if (json['lastModified'] != null) {
      doc._lastModified = DateTime.parse(json['lastModified'] as String);
    }
    
    if (json['sheetOrder'] != null) {
      doc._sheetOrder.addAll((json['sheetOrder'] as List).cast<String>());
    }
    
    if (json['sheets'] != null) {
      final sheetsJson = json['sheets'] as Map<String, dynamic>;
      sheetsJson.forEach((key, value) {
        doc._sheets[key] = SheetCRDT.fromJson(value as Map<String, dynamic>);
      });
    }
    
    if (json['vectorClock'] != null) {
      doc._vectorClock.addAll(
        Map<String, int>.from(json['vectorClock'] as Map),
      );
    }
    
    return doc;
  }
}
