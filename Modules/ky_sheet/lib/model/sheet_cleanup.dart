import 'cell/cell_address.dart';
import 'cell/cell_data.dart';
import 'cell/cell_selection.dart';

enum SheetCleanupOperation {
  trimWhitespace,
  normalizeWhitespace,
  uppercase,
  lowercase,
  titleCase,
  clearDuplicateRows,
}

extension SheetCleanupOperationLabel on SheetCleanupOperation {
  String get label {
    return switch (this) {
      SheetCleanupOperation.trimWhitespace => 'Trim Whitespace',
      SheetCleanupOperation.normalizeWhitespace => 'Normalize Spaces',
      SheetCleanupOperation.uppercase => 'Uppercase',
      SheetCleanupOperation.lowercase => 'Lowercase',
      SheetCleanupOperation.titleCase => 'Title Case',
      SheetCleanupOperation.clearDuplicateRows => 'Clear Duplicate Rows',
    };
  }
}

class SheetCleanupPlan {
  const SheetCleanupPlan({
    required this.operation,
    required this.selection,
    required this.replacements,
    required this.scannedCellCount,
    required this.changedCellCount,
    required this.affectedRowCount,
  });

  final SheetCleanupOperation operation;
  final CellSelection selection;
  final Map<CellAddress, CellData?> replacements;
  final int scannedCellCount;
  final int changedCellCount;
  final int affectedRowCount;

  bool get hasChanges => replacements.isNotEmpty;

  String get changedLabel {
    if (operation == SheetCleanupOperation.clearDuplicateRows) {
      return '$affectedRowCount row${affectedRowCount == 1 ? '' : 's'}';
    }
    return '$changedCellCount cell${changedCellCount == 1 ? '' : 's'}';
  }
}
