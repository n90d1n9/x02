/// Core collaboration engine for real-time multi-user editing.
///
/// This module implements a CRDT (Conflict-Free Replicated Data Type) based approach
/// to ensure eventual consistency across multiple clients without central locking.
library ky_sheet_collab;

export 'crdt/cell_crdt.dart';
export 'crdt/sheet_crdt.dart';
export 'crdt/document_crdt.dart';
export 'presence/presence_manager.dart';
export 'presence/user_cursor.dart';
export 'sync/operation.dart';
export 'sync/sync_engine.dart';
export 'history/collaborative_history.dart';
