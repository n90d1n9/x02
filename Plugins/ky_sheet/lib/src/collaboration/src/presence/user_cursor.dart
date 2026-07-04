/// Represents a user's cursor position in a spreadsheet.
class UserCursor {
  /// The cell ID where the cursor is located (e.g., "A1")
  final String cellId;
  
  /// Column index (0-based)
  final int column;
  
  /// Row index (0-based)
  final int row;
  
  /// Character offset within the cell (for edit mode)
  final int charOffset;
  
  /// Whether the cursor is in edit mode
  final bool isEditing;
  
  UserCursor({
    required this.cellId,
    required this.column,
    required this.row,
    this.charOffset = 0,
    this.isEditing = false,
  });
  
  /// Create from A1 notation
  factory UserCursor.fromCellId(String cellId, {int charOffset = 0, bool isEditing = false}) {
    final coords = _parseCellId(cellId);
    return UserCursor(
      cellId: cellId,
      column: coords[0],
      row: coords[1],
      charOffset: charOffset,
      isEditing: isEditing,
    );
  }
  
  static List<int> _parseCellId(String cellId) {
    final regex = RegExp(r'^([A-Z]+)(\d+)$');
    final match = regex.firstMatch(cellId.toUpperCase());
    
    if (match == null) {
      throw FormatException('Invalid cell ID: $cellId');
    }
    
    final colStr = match.group(1)!;
    final rowStr = match.group(2)!;
    
    // Convert column letters to number (A=0, B=1, ..., Z=25, AA=26, etc.)
    int column = 0;
    for (int i = 0; i < colStr.length; i++) {
      column = column * 26 + (colStr.codeUnitAt(i) - 'A'.codeUnitAt(0));
    }
    
    return [column, int.parse(rowStr) - 1]; // 0-based row
  }
  
  /// Get A1 notation from column and row
  static String cellIdFromCoords(int column, int row) {
    // Convert column number to letters
    String colStr = '';
    int col = column;
    do {
      colStr = String.fromCharCode('A'.codeUnitAt(0) + (col % 26)) + colStr;
      col = (col ~/ 26) - 1;
    } while (col >= 0);
    
    return '$colStr${row + 1}';
  }
  
  /// Move cursor to adjacent cell
  UserCursor move(int deltaColumn, int deltaRow) {
    final newColumn = column + deltaColumn;
    final newRow = row + deltaRow;
    
    if (newColumn < 0 || newRow < 0) {
      throw RangeError('Cursor cannot move to negative coordinates');
    }
    
    final newCellId = UserCursor.cellIdFromCoords(newColumn, newRow);
    return UserCursor(
      cellId: newCellId,
      column: newColumn,
      row: newRow,
      charOffset: 0,
      isEditing: false,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'cellId': cellId,
      'column': column,
      'row': row,
      'charOffset': charOffset,
      'isEditing': isEditing,
    };
  }
  
  factory UserCursor.fromJson(Map<String, dynamic> json) {
    return UserCursor(
      cellId: json['cellId'] as String,
      column: json['column'] as int,
      row: json['row'] as int,
      charOffset: json['charOffset'] as int? ?? 0,
      isEditing: json['isEditing'] as bool? ?? false,
    );
  }
  
  @override
  String toString() => 'UserCursor($cellId, col: $column, row: $row, offset: $charOffset, editing: $isEditing)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserCursor &&
        other.cellId == cellId &&
        other.column == column &&
        other.row == row &&
        other.charOffset == charOffset &&
        other.isEditing == isEditing;
  }
  
  @override
  int get hashCode => Object.hash(cellId, column, row, charOffset, isEditing);
}
