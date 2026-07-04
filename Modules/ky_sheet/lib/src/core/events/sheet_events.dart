/// Core event types for the spreadsheet engine.
/// Using sealed classes ensures exhaustive switching and type safety.
abstract class SheetEvent {
  final DateTime timestamp;
  final String? sourceId; // ID of the component/user triggering the event

  SheetEvent({this.sourceId}) : timestamp = DateTime.now();
}

// --- Document Lifecycle Events ---
class WorkbookCreatedEvent extends SheetEvent {}
class WorkbookOpenedEvent extends SheetEvent {
  final String filePath;
  WorkbookOpenedEvent(this.filePath);
}
class WorkbookSavedEvent extends SheetEvent {
  final String filePath;
  final bool success;
  WorkbookSavedEvent(this.filePath, this.success);
}
class WorkbookClosedEvent extends SheetEvent {}

// --- Sheet Structure Events ---
class SheetAddedEvent extends SheetEvent {
  final String sheetId;
  final String name;
  final int index;
  SheetAddedEvent(this.sheetId, this.name, this.index);
}

class SheetRemovedEvent extends SheetEvent {
  final String sheetId;
  SheetRemovedEvent(this.sheetId);
}

class SheetRenamedEvent extends SheetEvent {
  final String sheetId;
  final String oldName;
  final String newName;
  SheetRenamedEvent(this.sheetId, this.oldName, this.newName);
}

class SheetActivatedEvent extends SheetEvent {
  final String sheetId;
  SheetActivatedEvent(this.sheetId);
}

// --- Cell Data Events ---
class CellChangedEvent extends SheetEvent {
  final String sheetId;
  final int row;
  final int col;
  final dynamic oldValue;
  final dynamic newValue;
  
  CellChangedEvent(this.sheetId, this.row, this.col, this.oldValue, this.newValue);
}

class RangeChangedEvent extends SheetEvent {
  final String sheetId;
  final int startRow, endRow, startCol, endCol;
  RangeChangedEvent(this.sheetId, this.startRow, this.endRow, this.startCol, this.endCol);
}

// --- Formatting Events ---
class StyleAppliedEvent extends SheetEvent {
  final String sheetId;
  final List<String> cellIds; // List of "row,col" strings or specific range ID
  final Map<String, dynamic> styleProperties;
  StyleAppliedEvent(this.sheetId, this.cellIds, this.styleProperties);
}

// --- Undo/Redo Events ---
class UndoPerformedEvent extends SheetEvent {}
class RedoPerformedEvent extends SheetEvent {}
