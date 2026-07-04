# KySheet Architecture Refactoring Plan

## Current State Analysis

### Problems Identified
1. **Giant Provider Files**: `sheet_editor_provider.dart` (1,520+ lines) violates Single Responsibility Principle
2. **Tight Coupling**: UI components directly manipulate state instead of using commands
3. **Missing Separation of Concerns**: Business logic mixed with UI code
4. **Non-functional Menus**: File menu and other core features incomplete
5. **No Command Pattern**: Undo/Redo implemented ad-hoc without proper command abstraction
6. **Export Spaghetti**: 200+ exports in main library file without organization
7. **No Event System**: Components communicate through direct references
8. **Poor Testability**: Tight coupling makes unit testing nearly impossible

## Target Architecture

### Layer Structure
```
lib/
├── src/
│   ├── core/                    # Business logic, no UI dependencies
│   │   ├── events/              # Domain events (SheetEvent hierarchy)
│   │   ├── commands/            # Command pattern implementations
│   │   ├── services/            # Application services (FileService, etc.)
│   │   └── models/              # Core domain models
│   │
│   ├── features/                # Feature modules (UI + logic)
│   │   ├── file_menu/           # File menu feature
│   │   ├── grid/                # Spreadsheet grid feature
│   │   ├── toolbar/             # Toolbar feature
│   │   ├── formula_bar/         # Formula bar feature
│   │   └── sheet_tabs/          # Sheet navigation feature
│   │
│   ├── shared/                  # Shared utilities
│   │   ├── widgets/             # Reusable UI components
│   │   └── utils/               # Pure utility functions
│   │
│   └── infrastructure/          # External integrations
│       ├── storage/             # File I/O implementations
│       ├── excel/               # Excel import/export
│       └── collaboration/       # Real-time sync (future)
│
└── ky_sheet.dart                # Clean, organized exports
```

### Key Architectural Patterns

#### 1. Command Pattern
- All user actions encapsulated as commands
- Enables: Undo/Redo, transaction batching, remote sync, macro recording
- Example: `ChangeCellValueCommand`, `RenameSheetCommand`

#### 2. Event-Driven Communication
- Components publish events, subscribers react
- Decouples sender from receiver
- Example: `CellChangedEvent`, `SheetAddedEvent`

#### 3. Dependency Injection
- Services injected rather than created inline
- Enables testing with mocks
- Example: `StorageProvider` interface with `LocalFileStorage` implementation

#### 4. Feature Modules
- Each feature is self-contained
- Clear boundaries between features
- Features communicate through core events/commands

## Implementation Phases

### Phase 1: Foundation (Week 1-2) ✅ STARTED
- [x] Create event system (`SheetEvent` hierarchy)
- [x] Implement command pattern base classes
- [x] Build `CommandManager` for Undo/Redo
- [x] Create `FileService` abstraction
- [x] Add reusable widget library
- [ ] Fix File menu functionality
- [ ] Write unit tests for core components

### Phase 2: Core Refactoring (Week 3-4)
- [ ] Break down giant provider files
- [ ] Migrate cell operations to commands
- [ ] Implement proper event bus
- [ ] Refactor grid widget to use new architecture
- [ ] Fix toolbar functionality

### Phase 3: Feature Completion (Week 5-6)
- [ ] Complete File menu (Open, Save, Export, Import)
- [ ] Implement proper clipboard operations
- [ ] Add keyboard shortcut system
- [ ] Build formula bar component
- [ ] Improve sheet tab navigation

### Phase 4: Polish & Testing (Week 7-8)
- [ ] Add comprehensive unit tests
- [ ] Integration tests for critical paths
- [ ] Performance optimization
- [ ] Documentation
- [ ] Bug fixes

## Migration Strategy

### Incremental Approach
1. New code follows new architecture
2. Legacy code wrapped with adapters
3. Gradually migrate features one by one
4. Maintain backward compatibility during transition

### Breaking Changes Management
- Deprecate old APIs with warnings
- Provide migration guide
- Version bump for major changes

## Quality Metrics

### Code Quality Targets
- Max file size: 300 lines (except generated/codegen files)
- Test coverage: >80% for core, >60% for UI
- Zero circular dependencies
- All public APIs documented

### Performance Targets
- Grid scroll: 60fps with 10,000 cells
- Formula recalc: <100ms for typical sheets
- File save: <1s for 1MB workbook

## Next Immediate Actions

1. **Fix File Menu**: Connect `FileMenu` widget to `FileService`
2. **Test Command System**: Verify Undo/Redo works with new commands
3. **Create Adapters**: Bridge legacy providers to new command system
4. **Document API**: Add dartdoc comments to all public classes
