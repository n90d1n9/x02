import 'package:ky_sheet/src/core/commands/command.dart';
import 'package:ky_sheet/src/core/events/sheet_events.dart';

/// Manages Undo/Redo stacks using the Command pattern.
/// Decoupled from UI and business logic - pure state management.
class CommandManager {
  final List<Command> _undoStack = [];
  final List<Command> _redoStack = [];
  
  // Configurable limits to prevent memory issues
  final int maxHistorySize;
  
  // Event stream for notifying listeners
  final void Function(SheetEvent)? onEvent;

  CommandManager({this.maxHistorySize = 100, this.onEvent});

  /// Execute a command and add it to the undo stack.
  void execute(Command command) {
    command.execute();
    
    // Merge with previous command if possible
    if (_undoStack.isNotEmpty) {
      final merged = _undoStack.last.mergeWith(command);
      if (merged != null) {
        _undoStack[_undoStack.length - 1] = merged;
        if (onEvent != null) onEvent!(merged.event);
        return;
      }
    }
    
    _undoStack.add(command);
    _redoStack.clear(); // Clear redo stack on new action
    
    // Enforce size limit
    while (_undoStack.length > maxHistorySize) {
      _undoStack.removeAt(0);
    }
    
    if (onEvent != null) onEvent!(command.event);
  }

  /// Undo the last executed command.
  bool canUndo() => _undoStack.isNotEmpty;

  void undo() {
    if (!canUndo()) return;
    
    final command = _undoStack.removeLast();
    command.undo();
    _redoStack.add(command);
    
    if (onEvent != null) onEvent!(UndoPerformedEvent());
  }

  /// Redo the last undone command.
  bool canRedo() => _redoStack.isNotEmpty;

  void redo() {
    if (!canRedo()) return;
    
    final command = _redoStack.removeLast();
    command.redo();
    _undoStack.add(command);
    
    if (onEvent != null) onEvent!(RedoPerformedEvent());
  }

  /// Clear all history (e.g., when opening a new file).
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }

  /// Get a description of the next undo action for UI display.
  String? getUndoDescription() {
    if (_undoStack.isEmpty) return null;
    return _undoStack.last.description;
  }

  /// Get a description of the next redo action for UI display.
  String? getRedoDescription() {
    if (_redoStack.isEmpty) return null;
    return _redoStack.last.description;
  }

  /// Execute multiple commands as a single transaction.
  void executeBatch(List<Command> commands) {
    if (commands.isEmpty) return;
    
    // In a real implementation, you might want a CompositeCommand
    // For now, execute sequentially but emit a single event
    for (final command in commands) {
      execute(command);
    }
  }
}
