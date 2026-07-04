import 'cell_crdt.dart';

/// A CRDT for managing an entire sheet's state in collaborative editing.
/// 
/// This aggregates multiple CellCRDT instances and handles sheet-level operations
/// like row/column insertion, deletion, and merging.
class SheetCRDT {
  /// Unique identifier for this sheet
  final String sheetId;
  
  /// Map of cell IDs to their CRDT state
  final Map<String, CellCRDT> _cells = {};
  
  /// Vector clock for sheet-level operations
  final Map<String, int> _vectorClock = {};
  
  /// Track merged cell ranges
  final List<MergedCellRange> _mergedRanges = [];
  
  /// Track column widths
  final Map<int, double> _columnWidths = {};
  
  /// Track row heights
  final Map<int, double> _rowHeights = {};
  
  SheetCRDT({required this.sheetId});
  
  /// Get the value of a cell
  dynamic getCellValue(String cellId) {
    return _cells[cellId]?.value;
  }
  
  /// Set a cell value locally
  void setCellValue(String cellId, dynamic value, String clientId) {
    if (!_cells.containsKey(cellId)) {
      _cells[cellId] = CellCRDT(cellId: cellId);
    }
    
    final cell = _cells[cellId]!;
    // Convert dynamic value to CellValue (simplified - in real impl would handle types)
    final cellValue = CellValue.fromDynamic(value);
    cell.set(cellValue, clientId);
    
    _incrementVectorClock(clientId);
  }
  
  /// Apply a remote cell operation
  void applyRemoteCellOperation(CellOperation operation) {
    final cellId = operation.cellId;
    
    if (!_cells.containsKey(cellId)) {
      _cells[cellId] = CellCRDT(cellId: cellId);
    }
    
    _cells[cellId]!.applyRemote(operation);
    _mergeVectorClock(operation.vectorClock);
  }
  
  /// Merge a range of cells
  void mergeCells(String range, String clientId) {
    // Parse range (e.g., "A1:B2")
    final mergedRange = MergedCellRange.fromString(range);
    
    if (!_mergedRanges.contains(mergedRange)) {
      _mergedRanges.add(mergedRange);
      _incrementVectorClock(clientId);
    }
  }
  
  /// Unmerge cells in a range
  void unmergeCells(String range, String clientId) {
    final mergedRange = MergedCellRange.fromString(range);
    _mergedRanges.remove(mergedRange);
    _incrementVectorClock(clientId);
  }
  
  /// Set column width
  void setColumnWidth(int column, double width, String clientId) {
    _columnWidths[column] = width;
    _incrementVectorClock(clientId);
  }
  
  /// Set row height
  void setRowHeight(int row, double height, String clientId) {
    _rowHeights[row] = height;
    _incrementVectorClock(clientId);
  }
  
  /// Get all cells with values
  Map<String, dynamic> getAllValues() {
    final result = <String, dynamic>{};
    for (final entry in _cells.entries) {
      if (entry.value.value != null) {
        result[entry.key] = entry.value.value?.toDynamic();
      }
    }
    return result;
  }
  
  /// Get merged ranges
  List<MergedCellRange> get mergedRanges => List.unmodifiable(_mergedRanges);
  
  /// Get column widths
  Map<int, double> get columnWidths => Map.unmodifiable(_columnWidths);
  
  /// Get row heights
  Map<int, double> get rowHeights => Map.unmodifiable(_rowHeights);
  
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
  
  /// Serialize sheet state
  Map<String, dynamic> toJson() {
    return {
      'sheetId': sheetId,
      'cells': _cells.map((key, value) => MapEntry(key, value.toJson())),
      'mergedRanges': _mergedRanges.map((r) => r.toString()).toList(),
      'columnWidths': _columnWidths,
      'rowHeights': _rowHeights,
      'vectorClock': _vectorClock,
    };
  }
  
  /// Deserialize sheet state
  factory SheetCRDT.fromJson(Map<String, dynamic> json) {
    final sheet = SheetCRDT(sheetId: json['sheetId'] as String);
    
    if (json['cells'] != null) {
      final cellsJson = json['cells'] as Map<String, dynamic>;
      cellsJson.forEach((key, value) {
        sheet._cells[key] = CellCRDT.fromJson(value as Map<String, dynamic>);
      });
    }
    
    if (json['mergedRanges'] != null) {
      for (final rangeStr in json['mergedRanges'] as List) {
        sheet._mergedRanges.add(MergedCellRange.fromString(rangeStr as String));
      }
    }
    
    if (json['columnWidths'] != null) {
      sheet._columnWidths.addAll(
        Map<int, double>.from(json['columnWidths'] as Map),
      );
    }
    
    if (json['rowHeights'] != null) {
      sheet._rowHeights.addAll(
        Map<int, double>.from(json['rowHeights'] as Map),
      );
    }
    
    if (json['vectorClock'] != null) {
      sheet._vectorClock.addAll(
        Map<String, int>.from(json['vectorClock'] as Map),
      );
    }
    
    return sheet;
  }
}

/// Represents a merged cell range (e.g., A1:B2)
class MergedCellRange {
  final int startRow;
  final int startColumn;
  final int endRow;
  final int endColumn;
  
  MergedCellRange({
    required this.startRow,
    required this.startColumn,
    required this.endRow,
    required this.endColumn,
  });
  
  /// Parse from string format "A1:B2"
  factory MergedCellRange.fromString(String range) {
    final parts = range.split(':');
    if (parts.length != 2) {
      throw FormatException('Invalid range format: $range');
    }
    
    final start = _parseCellId(parts[0]);
    final end = _parseCellId(parts[1]);
    
    return MergedCellRange(
      startRow: start[0],
      startColumn: start[1],
      endRow: end[0],
      endColumn: end[1],
    );
  }
  
  static List<int> _parseCellId(String cellId) {
    // Extract column letters and row number
    final regex = RegExp(r'^([A-Z]+)(\d+)$');
    final match = regex.firstMatch(cellId.toUpperCase());
    
    if (match == null) {
      throw FormatException('Invalid cell ID: $cellId');
    }
    
    final colStr = match.group(1)!;
    final rowStr = match.group(2)!;
    
    // Convert column letters to number (A=1, B=2, ..., Z=26, AA=27, etc.)
    int column = 0;
    for (int i = 0; i < colStr.length; i++) {
      column = column * 26 + (colStr.codeUnitAt(i) - 'A'.codeUnitAt(0) + 1);
    }
    
    return [int.parse(rowStr), column];
  }
  
  @override
  String toString() {
    final start = _cellIdToString(startRow, startColumn);
    final end = _cellIdToString(endRow, endColumn);
    return '$start:$end';
  }
  
  String _cellIdToString(int row, int column) {
    // Convert column number to letters
    String colStr = '';
    int col = column;
    while (col > 0) {
      col--;
      colStr = String.fromCharCode('A'.codeUnitAt(0) + (col % 26)) + colStr;
      col ~/= 26;
    }
    return '$colStr$row';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MergedCellRange &&
        other.startRow == startRow &&
        other.startColumn == startColumn &&
        other.endRow == endRow &&
        other.endColumn == endColumn;
  }
  
  @override
  int get hashCode => Object.hash(startRow, startColumn, endRow, endColumn);
}
