import '../model/cell/cell_address.dart';
import '../model/sheet_history_entry.dart';
import '../model/undo_redo_action.dart';

class SheetHistorySummarizer {
  const SheetHistorySummarizer._();

  static SheetHistorySnapshot summarize({
    required List<UndoRedoAction> undoStack,
    required List<UndoRedoAction> redoStack,
    int maxEntriesPerStack = 20,
  }) {
    return SheetHistorySnapshot(
      undoEntries: _entriesForStack(
        stack: SheetHistoryStack.undo,
        actions: undoStack,
        maxEntries: maxEntriesPerStack,
      ),
      redoEntries: _entriesForStack(
        stack: SheetHistoryStack.redo,
        actions: redoStack,
        maxEntries: maxEntriesPerStack,
      ),
      undoCount: undoStack.length,
      redoCount: redoStack.length,
    );
  }

  static List<SheetHistoryEntry> _entriesForStack({
    required SheetHistoryStack stack,
    required List<UndoRedoAction> actions,
    required int maxEntries,
  }) {
    final entries = <SheetHistoryEntry>[];
    final limitedCount = actions.length.clamp(0, maxEntries).toInt();

    for (var offset = 0; offset < limitedCount; offset++) {
      final stackIndex = actions.length - 1 - offset;
      final action = actions[stackIndex];
      entries.add(
        SheetHistoryEntry(
          stack: stack,
          stackIndex: stackIndex,
          action: action,
          changedAddresses: _changedAddresses(action),
          isNextAction: offset == 0,
        ),
      );
    }

    return entries;
  }

  static List<CellAddress> _changedAddresses(UndoRedoAction action) {
    final addresses = {...action.before.keys, ...action.after.keys}.toList()
      ..sort((left, right) {
        final rowCompare = left.row.compareTo(right.row);
        return rowCompare == 0 ? left.col.compareTo(right.col) : rowCompare;
      });

    return addresses;
  }
}
