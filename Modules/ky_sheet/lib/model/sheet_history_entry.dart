import 'cell/cell_address.dart';
import 'undo_redo_action.dart';

enum SheetHistoryStack { undo, redo }

extension SheetHistoryStackLabel on SheetHistoryStack {
  String get label {
    return switch (this) {
      SheetHistoryStack.undo => 'Undo',
      SheetHistoryStack.redo => 'Redo',
    };
  }
}

class SheetHistorySnapshot {
  const SheetHistorySnapshot({
    required this.undoEntries,
    required this.redoEntries,
    required this.undoCount,
    required this.redoCount,
  });

  final List<SheetHistoryEntry> undoEntries;
  final List<SheetHistoryEntry> redoEntries;
  final int undoCount;
  final int redoCount;

  bool get isEmpty => undoCount == 0 && redoCount == 0;
  bool get canUndo => undoCount > 0;
  bool get canRedo => redoCount > 0;
}

class SheetHistoryEntry {
  const SheetHistoryEntry({
    required this.stack,
    required this.stackIndex,
    required this.action,
    required this.changedAddresses,
    required this.isNextAction,
  });

  final SheetHistoryStack stack;
  final int stackIndex;
  final UndoRedoAction action;
  final List<CellAddress> changedAddresses;
  final bool isNextAction;

  int get changedCellCount => changedAddresses.length;

  CellAddress? get primaryAddress {
    return changedAddresses.isEmpty ? null : changedAddresses.first;
  }

  String get title {
    final trimmed = action.description.trim();
    return trimmed.isEmpty ? 'Sheet change' : trimmed;
  }

  String get rangeLabel {
    final primary = primaryAddress;
    if (primary == null) return 'No cells';
    if (changedCellCount == 1) return primary.label;
    return '${primary.label} + ${changedCellCount - 1}';
  }

  String get detail {
    final countLabel =
        '$changedCellCount cell${changedCellCount == 1 ? '' : 's'}';
    return '$countLabel changed';
  }
}
