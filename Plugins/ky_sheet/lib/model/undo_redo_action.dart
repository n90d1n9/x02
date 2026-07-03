import 'cell/cell_address.dart';
import 'cell/cell_data.dart';

class UndoRedoAction {
  final Map<CellAddress, CellData?> before;
  final Map<CellAddress, CellData?> after;
  final String description;

  UndoRedoAction(this.before, this.after, this.description);
}
