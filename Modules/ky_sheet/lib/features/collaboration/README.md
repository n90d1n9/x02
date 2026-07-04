# KySheet Collaboration Engine

Real-time collaborative editing engine for ky_sheet spreadsheet, implementing CRDT-based conflict resolution similar to Google Sheets and Microsoft Excel Online.

## Features

### Core Capabilities

- **CRDT-Based Conflict Resolution**: Last-Writer-Wins (LWW) with vector clocks for guaranteed eventual consistency
- **Real-Time Presence**: Track multiple users' cursors, selections, and editing states
- **Collaborative Undo/Redo**: Intelligent undo that respects causality across multiple users
- **Operation Synchronization**: Efficient sync protocol for low-latency collaboration
- **Offline Support**: Queue operations locally when disconnected, sync when reconnected

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    KySheet Application                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │  Document    │  │   Presence   │  │    Sync      │       │
│  │    CRDT      │  │   Manager    │  │   Engine     │       │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘       │
│         │                 │                 │                │
│  ┌──────▼───────┐  ┌──────▼───────┐  ┌──────▼───────┐       │
│  │   Sheet      │  │ User Cursors │  │  Operations  │       │
│  │    CRDT      │  │  & Selection │  │   History    │       │
│  └──────┬───────┘  └──────────────┘  └──────────────┘       │
│         │                                                   │
│  ┌──────▼───────┐                                           │
│  │    Cell      │                                           │
│  │    CRDT      │                                           │
│  └──────────────┘                                           │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Components

### CRDT Layer (`src/crdt/`)

#### CellCRDT
Conflict-Free Replicated Data Type for individual cells:
- Vector clock-based conflict resolution
- Operation history tracking
- JSON serialization for network transmission

#### SheetCRDT
Manages a single sheet's collaborative state:
- Aggregates multiple CellCRDT instances
- Handles merged cell ranges
- Tracks column widths and row heights
- Sheet-level vector clock

#### DocumentCRDT
Top-level document management:
- Multiple sheets coordination
- Sheet ordering and navigation
- Document metadata (title, last modified)
- Global vector clock

### Presence Layer (`src/presence/`)

#### PresenceManager
Tracks active users in a session:
- User join/leave events
- Activity timeout detection
- Real-time callbacks

#### UserCursor
Represents user cursor state:
- Cell position (A1 notation)
- Edit mode status
- Character offset within cell

### Sync Layer (`src/sync/`)

#### Operation
Base class for all collaborative operations:
- CellSetOperation: Set cell value/formula
- CellClearOperation: Clear cell content
- MergeCellsOperation: Merge/unmerge cells
- RowColumnOperation: Insert/delete rows/columns

#### SyncEngine
Manages operation synchronization:
- Local operation creation and application
- Remote operation reception and application
- Pending operation tracking
- Acknowledgment handling

### History Layer (`src/history/`)

#### CollaborativeHistory
Multi-user undo/redo support:
- Per-client undo stacks
- Inverse operation generation
- Causality-respecting undo
- Operation filtering and querying

## Usage

### Basic Setup

```dart
import 'package:ky_sheet/features/collaboration/ky_sheet_collab.dart';

// Create a new document
final document = DocumentCRDT(documentId: 'doc_123');

// Create sync engine for a client
final syncEngine = SyncEngine(
  clientId: 'user_abc',
  document: document,
);

// Set up callbacks
syncEngine.onOperationReady = (operation) {
  // Send operation to server/other clients
  broadcastOperation(operation);
};

syncEngine.onOperationsReceived = (operations) {
  // Update UI with remote changes
  refreshSpreadsheet();
};
```

### Setting Cell Values

```dart
// Set a cell value (automatically creates and broadcasts operation)
syncEngine.setCell('sheet_1', 'A1', 'Hello World');

// Set a formula
syncEngine.setCell('sheet_1', 'B1', null, formula: '=SUM(A1:A10)');

// Clear a cell
syncEngine.clearCell('sheet_1', 'C1');
```

### Managing Presence

```dart
final presenceManager = PresenceManager(sessionId: 'session_xyz');

// Set up presence callbacks
presenceManager.onUserJoin = (user) {
  showUserJoinedNotification(user.userName);
};

presenceManager.onCursorUpdate = (userId, cursor) {
  updateUserCursorUI(userId, cursor);
};

// Update local user's cursor
presenceManager.updateCursor('user_abc', UserCursor.fromCellId('A1'));
```

### Undo/Redo

```dart
final history = CollaborativeHistory(
  document: document,
  clientId: 'user_abc',
);

// Add operations to history (called by sync engine)
history.addOperation(operation);

// Undo last action
if (history.canUndo) {
  final inverseOp = history.undo();
  // Apply inverse operation
}

// Redo
if (history.canRedo) {
  final op = history.redo();
  // Re-apply operation
}
```

## Network Protocol

### Operation Transmission

Operations are serialized to JSON and transmitted via WebSocket or similar real-time channel:

```json
{
  "type": "cell_set",
  "id": "user_abc_1_1625097600000",
  "clientId": "user_abc",
  "timestamp": "2024-01-15T10:30:00.000Z",
  "vectorClock": {"user_abc": 5, "user_def": 3},
  "sheetId": "sheet_1",
  "cellId": "A1",
  "value": "Hello",
  "formula": null
}
```

### Presence Updates

```json
{
  "type": "presence_update",
  "userId": "user_abc",
  "userName": "John Doe",
  "color": "#FF5733",
  "cursor": {
    "cellId": "B2",
    "column": 1,
    "row": 1,
    "charOffset": 0,
    "isEditing": true
  },
  "selection": {
    "startCell": "A1",
    "endCell": "C3"
  }
}
```

## Conflict Resolution

The engine uses a combination of strategies:

1. **Vector Clocks**: Track causality between operations
2. **Last-Writer-Wins**: For concurrent updates, the latest timestamp wins
3. **Operation Transformation**: Future enhancement for better merge semantics
4. **Cell-Level Locking**: Optional fine-grained locking for critical sections

## Performance Considerations

- **Batching**: Group multiple operations for efficient transmission
- **Compression**: Use compression for large operation payloads
- **Incremental Sync**: Only transmit differential changes
- **Lazy Loading**: Load sheet data on-demand for large spreadsheets

## Security

- **Authentication**: Verify user identity before allowing operations
- **Authorization**: Check permissions for each operation type
- **Audit Logging**: Record all operations for compliance
- **Encryption**: Encrypt operations in transit and at rest

## Limitations & Future Work

- [ ] Operation transformation for better conflict resolution
- [ ] Comment collaboration
- [ ] Chat integration
- [ ] Version history browsing
- [ ] Granular permissions per sheet/cell
- [ ] End-to-end encryption
- [ ] Mobile optimization

## License

MIT License - See LICENSE file for details
