/// Core collaboration engine for real-time multi-user editing.
/// 
/// This module implements a CRDT (Conflict-Free Replicated Data Type) based approach
/// to ensure eventual consistency across multiple clients without central locking.
library ky_sheet_collab;

export 'src/crdt/cell_crdt.dart';
export 'src/crdt/sheet_crdt.dart';
export 'src/crdt/document_crdt.dart';
export 'src/presence/presence_manager.dart';
export 'src/presence/user_cursor.dart';
export 'src/sync/operation.dart';
export 'src/sync/sync_engine.dart';
export 'src/history/collaborative_history.dart';
