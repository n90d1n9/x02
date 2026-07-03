/// State layer: owns the Rust document handle, the Dart-side tree cache
/// used for rendering, and undo/redo. This is the only place that calls
/// across the FFI boundary — `rendering/` and `editing/` never touch
/// generated Rust bindings directly, they go through `DocumentController`.
///
/// NOTE ON CODEGEN: this file imports `../rust/api/document.dart`, which
/// `flutter_rust_bridge_codegen generate` produces from
/// `ffi/src/api/document.rs` (see that crate's doc comment for the exact
/// command to run). That generated file isn't included in this delivery
/// because codegen requires the Flutter SDK; the import below documents
/// the exact function names/signatures codegen will produce for our
/// hand-written Rust API (u32 handles map to a plain Dart `int`; every
/// function is `#[frb(sync)]` so these are synchronous calls, not
/// `Future`s).
library rich_doc_state;

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/commands.dart';
import '../model/document_tree.dart';
import '../rust/api/document.dart' as rust;

class DocumentState {
  final DocumentTree tree;
  final bool canUndo;
  final bool canRedo;
  const DocumentState({required this.tree, required this.canUndo, required this.canRedo});
}

/// One document instance = one `DocumentController`. Wrap this provider
/// in a `.family` keyed by however your app identifies documents (e.g.
/// a doc id from your backend) if you need multiple documents open at
/// once without their undo stacks interfering.
class DocumentController extends Notifier<DocumentState> {
  late int _handle;

  // Undo/redo both hold *lists of raw Op JSON* (not CommandBatch),
  // because that's what `AgentResult.outcome.inverse` gives back — and
  // it's the same shape whether the edit that produced it came from a
  // keystroke or an agent tool call. See `_swap` for how one stack
  // feeds the other.
  final List<List<dynamic>> _undoStack = [];
  final List<List<dynamic>> _redoStack = [];

  @override
  DocumentState build() {
    _handle = rust.createDocument();
    ref.onDispose(() => rust.closeDocument(handle: _handle));
    return _fetchState();
  }

  /// Load a previously-saved document (full-fidelity JSON from
  /// `snapshotJson()`) into this controller, replacing the current one.
  void loadFrom(String snapshotJson) {
    rust.closeDocument(handle: _handle);
    _handle = rust.loadDocument(json: snapshotJson);
    _undoStack.clear();
    _redoStack.clear();
    state = _fetchState();
  }

  /// Full-fidelity snapshot for persistence.
  String snapshotJson() => rust.getSnapshot(handle: _handle);

  /// Plain nested JSON with no internal ids — for a backend, or for
  /// splicing into an LLM prompt as document context.
  String portableSnapshotJson() => rust.getPortableSnapshot(handle: _handle);

  /// The one path every human-driven edit goes through.
  bool apply(CommandBatch batch) => _applyAndTrack(batch.toJsonString());

  /// The one path an agent tool call goes through: raw command JSON in,
  /// identical atomicity/rollback and identical undo-stack entry as a
  /// human edit. This sharing is the actual point of the design — a
  /// user can hit Ctrl+Z on something an agent just did.
  bool applyAgentCommandJson(String commandJson) => _applyAndTrack(commandJson);

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  bool undo() => _undoStack.isEmpty ? false : _swap(_undoStack, _redoStack);
  bool redo() => _redoStack.isEmpty ? false : _swap(_redoStack, _undoStack);

  bool _applyAndTrack(String commandJson) {
    final resultJson = rust.applyCommand(handle: _handle, commandJson: commandJson);
    final result = jsonDecode(resultJson) as Map<String, dynamic>;
    if (result['ok'] != true) return false;
    final outcome = result['outcome'] as Map<String, dynamic>?;
    final inverseOps = (outcome?['inverse'] as List?) ?? const [];
    if (inverseOps.isNotEmpty) {
      _undoStack.add(inverseOps);
      _redoStack.clear();
    }
    state = _fetchState();
    return true;
  }

  /// Pop the last op-list off `from`, apply it, and push the *new*
  /// inverse that application produces onto `to`. Applying the inverse
  /// of a change itself returns the inverse-of-the-inverse — i.e. the
  /// original change — which is exactly what makes undo/redo symmetric
  /// without storing two separate representations of every edit.
  bool _swap(List<List<dynamic>> from, List<List<dynamic>> to) {
    final opsToApply = from.removeLast();
    final commandJson = jsonEncode({
      'ops': opsToApply.map((op) => {'command': 'op', 'payload': op}).toList(),
    });
    final resultJson = rust.applyCommand(handle: _handle, commandJson: commandJson);
    final result = jsonDecode(resultJson) as Map<String, dynamic>;
    if (result['ok'] != true) {
      from.add(opsToApply); // put it back; nothing changed
      return false;
    }
    final outcome = result['outcome'] as Map<String, dynamic>?;
    to.add((outcome?['inverse'] as List?) ?? const []);
    state = _fetchState();
    return true;
  }

  DocumentState _fetchState() {
    final json = jsonDecode(rust.getSnapshot(handle: _handle)) as Map<String, dynamic>;
    return DocumentState(tree: DocumentTree.fromJson(json), canUndo: canUndo, canRedo: canRedo);
  }
}

final documentControllerProvider = NotifierProvider<DocumentController, DocumentState>(DocumentController.new);
