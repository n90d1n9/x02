import 'package:ky_sheet/src/core/commands/command.dart';
import 'package:ky_sheet/src/core/events/sheet_events.dart';

/// Command to change the value of a single cell.
class ChangeCellValueCommand extends Command with MergeableCommand {
  final String sheetId;
  final int row;
  final int col;
  final dynamic newValue;
  
  dynamic? _oldValue;
  bool _executed = false;

  ChangeCellValueCommand({
    required this.sheetId,
    required this.row,
    required this.col,
    required this.newValue,
    String? id,
  }) : super(id: id);

  // Injected dependency - set before execution
  late void Function(String, int, int, dynamic) _setCellValue;
  late dynamic Function(String, int, int) _getCellValue;

  void setDependencies({
    required void Function(String, int, int, dynamic) setCellValue,
    required dynamic Function(String, int, int) getCellValue,
  }) {
    _setCellValue = setCellValue;
    _getCellValue = getCellValue;
  }

  @override
  void execute() {
    if (_executed) return;
    _oldValue = _getCellValue(sheetId, row, col);
    _setCellValue(sheetId, row, col, newValue);
    _executed = true;
    markAsExecuted();
  }

  @override
  void undo() {
    if (!_executed) return;
    _setCellValue(sheetId, row, col, _oldValue);
    _executed = false;
  }

  @override
  SheetEvent get event {
    return CellChangedEvent(sheetId, row, col, _oldValue, newValue);
  }

  @override
  String get description => 'Change cell (${row + 1}, ${col + 1})';

  @override
  bool canMergeWith(Command other) {
    if (other is! ChangeCellValueCommand) return false;
    // Merge if same cell and executed within short time window
    return other.sheetId == sheetId && 
           other.row == row && 
           other.col == col &&
           other.createdAt.difference(createdAt).inMilliseconds < 500;
  }

  @override
  Command? mergeWith(Command other) {
    if (!canMergeWith(other)) return null;
    // Return the newer command as it contains the latest value
    return other;
  }
}

/// Command to rename a sheet.
class RenameSheetCommand extends Command {
  final String sheetId;
  final String newName;
  String? _oldName;
  bool _executed = false;

  late void Function(String, String) _renameSheet;
  late String Function(String) _getSheetName;

  RenameSheetCommand({
    required this.sheetId,
    required this.newName,
    String? id,
  }) : super(id: id);

  void setDependencies({
    required void Function(String, String) renameSheet,
    required String Function(String) getSheetName,
  }) {
    _renameSheet = renameSheet;
    _getSheetName = getSheetName;
  }

  @override
  void execute() {
    if (_executed) return;
    _oldName = _getSheetName(sheetId);
    _renameSheet(sheetId, newName);
    _executed = true;
    markAsExecuted();
  }

  @override
  void undo() {
    if (!_executed || _oldName == null) return;
    _renameSheet(sheetId, _oldName!);
    _executed = false;
  }

  @override
  SheetEvent get event {
    return SheetRenamedEvent(sheetId, _oldName ?? '', newName);
  }

  @override
  String get description => 'Rename sheet to "$newName"';
}

/// Command to add a new sheet.
class AddSheetCommand extends Command {
  final String name;
  final int index;
  String? _createdSheetId;
  bool _executed = false;

  late String Function(String, int) _addSheet;
  late void Function(String) _removeSheet;

  AddSheetCommand({
    required this.name,
    required this.index,
    String? id,
  }) : super(id: id);

  void setDependencies({
    required String Function(String, int) addSheet,
    required void Function(String) removeSheet,
  }) {
    _addSheet = addSheet;
    _removeSheet = removeSheet;
  }

  @override
  void execute() {
    if (_executed) return;
    _createdSheetId = _addSheet(name, index);
    _executed = true;
    markAsExecuted();
  }

  @override
  void undo() {
    if (!_executed || _createdSheetId == null) return;
    _removeSheet(_createdSheetId!);
    _executed = false;
  }

  @override
  SheetEvent get event {
    return SheetAddedEvent(_createdSheetId ?? '', name, index);
  }

  @override
  String get description => 'Add sheet "$name"';
}
