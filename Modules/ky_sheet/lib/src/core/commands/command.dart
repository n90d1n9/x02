import 'package:ky_sheet/src/core/events/sheet_events.dart';

/// Abstract command pattern for all spreadsheet operations.
/// Enables Undo/Redo, transaction batching, and remote synchronization.
abstract class Command {
  final String id;
  final DateTime createdAt;
  bool _hasBeenExecuted = false;

  Command({String? id}) 
    : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt = DateTime.now();

  /// Execute the command. Should be idempotent if called multiple times.
  void execute();

  /// Undo the effect of this command.
  void undo();

  /// Redo the effect after an undo.
  void redo() => execute();

  bool get hasBeenExecuted => _hasBeenExecuted;

  void markAsExecuted() => _hasBeenExecuted = true;

  /// Returns the event that this command generates when executed.
  SheetEvent get event;

  /// Merges this command with another if possible (for optimization).
  Command? mergeWith(Command other) => null;

  /// Description for UI display (e.g., in Undo history)
  String get description;
}

/// Marker interface for commands that can be merged together.
mixin MergeableCommand on Command {
  bool canMergeWith(Command other);
}
