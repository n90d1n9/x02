# Ky Docs Improvement Plan - Missing Features & Next Steps

## Executive Summary

This document outlines the missing features, gaps, and recommended improvements for `Plugins/ky_docs` to achieve full MS Word/Google Docs parity with proper import/export/save functionality for sample documents.

---

## 1. Critical Missing Features

### 1.1 File Menu Integration Issues

**Current Status:** ✅ File menu widget exists (`file_menu.dart`)
**Problem:** ❌ Not properly connected to import/export services

**Missing Implementations:**
- [ ] **File → Open**: No file picker integration to open `Sample/sample01.docx` and `Sample/sample02-complete.docx`
- [ ] **File → Save**: No actual save implementation (currently just a callback)
- [ ] **File → Save As**: No dialog for choosing location/filename
- [ ] **File → Import → DOCX**: Callbacks exist but no service integration
- [ ] **File → Export → DOCX/PDF**: Callbacks exist but no service integration
- [ ] **Recent Documents**: No recent files list
- [ ] **Auto-save**: No automatic save functionality
- [ ] **Unsaved Changes Warning**: No prompt when closing with unsaved changes

### 1.2 Document Lifecycle Management

**Missing:**
- [ ] **Document State Tracking**: Dirty/clean state not tracked
- [ ] **Version History**: No versioning system for document revisions
- [ ] **Cloud Sync**: No integration with cloud storage (Google Drive, OneDrive, etc.)
- [ ] **Local Storage**: No persistent local database (SQLite/Hive) for drafts
- [ ] **Recovery System**: No auto-recovery for crashed sessions

### 1.3 Import/Export Gaps

**Current Implementation:** Uses Dart-based extractors
**Missing Rust FFI Integration:**
- [ ] **Native DOCX Parser**: `parser-docx` Rust parser not integrated via FFI
- [ ] **Native DOCX Writer**: No Rust-based DOCX generation
- [ ] **High-Fidelity Import**: Complex formatting, tables, images lost in current import
- [ ] **High-Fidelity Export**: Same fidelity issues on export
- [ ] **PDF Import**: Basic text extraction only, no layout preservation
- [ ] **ODT Support**: No OpenDocument Text format support
- [ ] **RTF Support**: No Rich Text Format support
- [ ] **HTML Import/Export**: No web format support

### 1.4 User Interface Gaps

**Missing UI Components:**
- [ ] **Ribbon Toolbar**: MS Word-style ribbon with tabs (Home, Insert, Layout, etc.)
- [ ] **Status Bar Enhancements**: Page count, word count, language, zoom slider
- [ ] **Mini Toolbar**: Contextual formatting toolbar on text selection
- [ ] **Right-Click Context Menu**: Custom context menu for editing operations
- [ ] **Navigation Pane**: Document outline with draggable sections
- [ ] **Thumbnails View**: Page thumbnail navigation
- [ ] **Split View**: Side-by-side document comparison
- [ ] **Focus Mode**: Distraction-free writing mode
- [ ] **Dark Mode**: Proper dark theme support
- [ ] **Customizable Toolbars**: User can add/remove toolbar buttons

### 1.5 Advanced Editing Features

**Missing Core Features:**
- [ ] **Track Changes**: Full track changes with accept/reject
- [ ] **Comments Thread**: Nested comment replies
- [ ] **Suggestions Mode**: Google Docs-style suggestion mode
- [ ] **Find & Replace**: Advanced find/replace with regex support
- [ ] **Go To Page**: Quick navigation to specific page
- [ ] **Bookmarks**: Add/edit/delete bookmarks
- [ ] **Cross-References**: Reference headings, figures, tables
- [ ] **Table of Contents**: Auto-generated TOC with updates
- [ ] **Footnotes/Endnotes**: Full footnote/endnote support
- [ ] **Citations & Bibliography**: Citation management (APA, MLA, Chicago)
- [ ] **Index**: Auto-generated index
- [ ] **Headers/Footers**: Different first page, odd/even pages
- [ ] **Page Numbers**: Various numbering formats and positions
- [ ] **Section Breaks**: Different headers/footers per section
- [ ] **Columns**: Multi-column layout
- [ ] **Text Boxes**: Floating text boxes
- [ ] **Word Art**: Decorative text effects
- [ ] **Equations**: LaTeX equation editor
- [ ] **Drawing Canvas**: Freehand drawing and shapes

### 1.6 Collaboration Features

**Missing:**
- [ ] **Real-time Collaboration**: Multiple users editing simultaneously
- [ ] **Presence Indicators**: Show who's viewing/editing
- [ ] **Chat**: In-document chat
- [ ] **Sharing Permissions**: View/Edit/Comment permissions
- [ ] **Activity Log**: Track all document activities
- [ ] **Mention System**: @mention collaborators in comments

### 1.7 AI-Powered Features

**Partially Implemented:**
- [ ] **AI Writing Assistant**: Grammar, style, tone suggestions
- [ ] **Auto-Summarize**: Generate document summaries
- [ ] **Paraphrasing**: Rewrite selected text
- [ ] **Translation**: Real-time translation
- [ ] **Smart Compose**: Predictive text completion
- [ ] **Plagiarism Check**: Detect copied content
- [ ] **Readability Score**: Flesch-Kincaid and other metrics
- [ ] **Outline Generator**: Auto-generate document structure

---

## 2. Architecture Improvements Needed

### 2.1 Rust FFI Integration

**Current:** Dart-only implementation with placeholder FFI
**Required:**
```rust
// Must implement in Plugins/Engine/docx_reader_ffi/src/lib.rs:
- docx_parse_full_fidelity(bytes) -> DocumentHandle
- docx_write_full_fidelity(DocumentHandle) -> Vec<u8>
- pdf_import_with_layout(bytes) -> DocumentHandle
- crdt_operation_apply(handle, operation) -> Outcome
- collaboration_sync(handle, remote_state) -> Delta
```

**Action Items:**
1. Build Rust FFI library for all platforms
2. Generate Dart bindings with `ffigen`
3. Replace Dart extractors with native calls
4. Implement memory-safe handle management

### 2.2 State Management

**Current:** Riverpod providers exist but incomplete
**Required:**
- [ ] Centralized document state machine
- [ ] Undo/Redo stack with command pattern
- [ ] Optimistic updates for collaboration
- [ ] Conflict resolution strategies
- [ ] Offline-first architecture

### 2.3 Performance Optimization

**Issues:**
- Large documents (>100 pages) will lag
- No virtual scrolling for long documents
- Image rendering not optimized
- No background threading for heavy operations

**Solutions:**
- [ ] Implement virtual scrolling for document canvas
- [ ] Use Isolates for import/export operations
- [ ] Lazy load images and embedded content
- [ ] Cache rendered pages
- [ ] Incremental parsing for large DOCX files

---

## 3. Sample Document Testing Plan

### 3.1 Test Cases for `Sample/sample01.docx`

**Expected Content Analysis:**
```dart
// Must preserve after import:
- Document title and metadata
- Paragraph styles (Normal, Heading 1-3)
- Character formatting (bold, italic, underline)
- Lists (bulleted, numbered)
- Tables with borders and merged cells
- Images with captions
- Headers and footers
- Page breaks and section breaks
```

**Test Workflow:**
1. File → Import → DOCX → Select `sample01.docx`
2. Verify preview shows correct structure
3. Confirm import preserves all formatting
4. Edit document (add text, change formatting)
5. File → Save As → `sample01_edited.docx`
6. Re-import edited file and verify changes persisted
7. Export to PDF and compare visual fidelity

### 3.2 Test Cases for `Sample/sample02-complete.docx`

**Large Document Challenges:**
- File size: ~18MB (complex content)
- Likely contains: images, tables, charts, complex formatting
- Performance testing required

**Test Workflow:**
1. Import with progress indicator
2. Monitor memory usage (<500MB target)
3. Scroll performance test (60 FPS target)
4. Search functionality test
5. Export time measurement (<30 seconds target)
6. Compare exported file size with original

---

## 4. Implementation Priority Matrix

### P0 - Critical (Must Have for MVP)
| Feature | Effort | Impact | Priority |
|---------|--------|--------|----------|
| File → Open (DOCX) | Medium | High | 1 |
| File → Save (DOCX) | Medium | High | 2 |
| File → Save As dialog | Low | High | 3 |
| Import DOCX with Rust parser | High | High | 4 |
| Export DOCX with Rust writer | High | High | 5 |
| Unsaved changes warning | Low | High | 6 |
| Auto-save every 30s | Low | High | 7 |
| Recent documents list | Low | Medium | 8 |

### P1 - High Priority
| Feature | Effort | Impact | Priority |
|---------|--------|--------|----------|
| Track Changes | High | High | 9 |
| Comments with threads | Medium | High | 10 |
| Find & Replace | Medium | High | 11 |
| Table of Contents | Medium | Medium | 12 |
| Headers/Footers editor | Medium | Medium | 13 |
| Page layout view | Medium | Medium | 14 |
| Print preview | Low | Medium | 15 |
| PDF export with options | Medium | High | 16 |

### P2 - Medium Priority
| Feature | Effort | Impact | Priority |
|---------|--------|--------|----------|
| Real-time collaboration | Very High | High | 17 |
| AI writing assistant | High | Medium | 18 |
| Ribbon toolbar | High | Medium | 19 |
| Dark mode | Low | Medium | 20 |
| Keyboard shortcuts | Low | Medium | 21 |
| Customizable toolbars | Medium | Low | 22 |
| Split view | Medium | Low | 23 |
| Focus mode | Low | Low | 24 |

### P3 - Future Enhancements
- Voice typing
- Offline mobile sync
- Add-ons/Extensions system
- Template gallery
- Advanced typography controls
- Accessibility checker
- Language tools integration

---

## 5. Specific Code Fixes Required

### 5.1 Connect File Menu to Services

**File:** `lib/docx/widgets/document_editor_app_bar.dart`

**Current Issue:** File menu callbacks not connected to actual services

**Fix Required:**
```dart
// Add provider access and connect callbacks
final importService = ref.read(documentImportServiceProvider);
final exportService = ref.read(documentExportServiceProvider);
final lifecycleService = ref.read(documentLifecycleOrchestrationServiceProvider);

DocumentFileMenu(
  onNew: () => lifecycleService.newDocument(),
  onOpen: () async {
    final imported = await importService.importDocx();
    if (imported != null) {
      lifecycleService.loadDocument(imported);
    }
  },
  onSave: () => lifecycleService.saveDocument(),
  onSaveAs: () => lifecycleService.saveDocumentAs(),
  onImport: (format) => _handleImport(format, importService),
  onExport: (format) => _handleExport(format, exportService),
  // ...
)
```

### 5.2 Implement Save As Dialog

**New File:** `lib/docx/widgets/editor_app_bar/save_as_dialog.dart`

```dart
class SaveAsDialog extends StatefulWidget {
  final String defaultFileName;
  final List<String> availableFormats;
  
  const SaveAsDialog({
    required this.defaultFileName,
    this.availableFormats = const ['docx', 'pdf', 'txt'],
  });
  
  // Show dialog with:
  // - Filename text field
  // - Location picker (if platform supports)
  // - Format dropdown
  // - Cancel/Save buttons
}
```

### 5.3 Add Dirty State Tracking

**File:** `lib/docx/states/document_notifier.dart`

```dart
class DocumentNotifier extends StateNotifier<DocumentState> {
  bool _isDirty = false;
  Timer? _autoSaveTimer;
  
  void markDirty() {
    _isDirty = true;
    _startAutoSaveTimer();
  }
  
  void markClean() {
    _isDirty = false;
    _autoSaveTimer?.cancel();
  }
  
  bool get isDirty => _isDirty;
  
  Future<bool> confirmCloseIfDirty() async {
    if (!_isDirty) return true;
    
    final shouldClose = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Unsaved Changes'),
        content: Text('You have unsaved changes. Do you want to save before closing?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Discard')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Save')),
        ],
      ),
    );
    
    if (shouldClose == true) {
      await save();
    }
    
    return shouldClose ?? false;
  }
}
```

### 5.4 Integrate Rust FFI Parser

**File:** `lib/engine/docx_parser_service.dart`

**Current:** Placeholder implementation
**Required:**
```dart
class DocxParserService {
  late DocumentEngineFFI _ffi;
  
  Future<DocumentImportContent> parseFullFidelity(Uint8List bytes) async {
    // Call Rust FFI instead of Dart extractor
    final handle = await _ffi.parseDocx(bytes);
    final json = await _ffi.documentToJson(handle);
    final metadata = await _ffi.extractMetadata(handle);
    
    return DocumentImportContent(
      text: await _ffi.getDocumentText(handle),
      docsEngineJson: json,
      metadata: metadata,
      method: DocumentImportMethod.nativeParser,
    );
  }
}
```

---

## 6. Testing Strategy

### 6.1 Unit Tests
- [ ] Import service tests with sample files
- [ ] Export service tests verifying file integrity
- [ ] Dirty state tracking tests
- [ ] Auto-save timer tests
- [ ] File menu action tests

### 6.2 Integration Tests
- [ ] Full import → edit → export cycle
- [ ] Large document performance tests
- [ ] Memory leak detection
- [ ] Concurrent save operations

### 6.3 Manual Testing Checklist
- [ ] Import `sample01.docx` and verify all content
- [ ] Import `sample02-complete.docx` and check performance
- [ ] Edit imported document and save
- [ ] Re-open saved file and verify persistence
- [ ] Export to PDF and compare with original
- [ ] Test auto-save by crashing app
- [ ] Test unsaved changes warning
- [ ] Test recent documents list

---

## 7. Documentation Updates Needed

- [ ] **User Guide**: How to import/export documents
- [ ] **API Reference**: Complete service documentation
- [ ] **Architecture Diagram**: Updated with FFI layer
- [ ] **Performance Guide**: Best practices for large documents
- [ ] **Troubleshooting**: Common import/export issues
- [ ] **Migration Guide**: From Quill to native engine

---

## 8. Recommended Next Steps (Immediate Action)

### Week 1: Critical Fixes
1. Connect File menu to import/export services
2. Implement Save As dialog
3. Add dirty state tracking and auto-save
4. Test with `sample01.docx` end-to-end

### Week 2: Rust FFI Integration
1. Build Rust FFI library for target platform
2. Generate Dart bindings
3. Replace Dart DOCX parser with native calls
4. Test with `sample02-complete.docx`

### Week 3: Advanced Features
1. Implement Track Changes
2. Add Comments with threading
3. Build Find & Replace with regex
4. Create Table of Contents generator

### Week 4: Polish & Performance
1. Optimize large document rendering
2. Add virtual scrolling
3. Implement caching strategies
4. Comprehensive testing and bug fixes

---

## Conclusion

The current `ky_docs` implementation has a solid foundation but requires significant work to achieve MS Word/Google Docs parity. The most critical gaps are:

1. **File menu not connected to services** - Users cannot actually import/export/save
2. **No Rust FFI integration** - Missing high-fidelity DOCX parsing/writing
3. **No document lifecycle management** - No auto-save, dirty tracking, or recovery
4. **Limited editing features** - Missing track changes, advanced formatting, collaboration

Priority should be given to P0 features to enable basic document workflows with the sample files, followed by Rust FFI integration for production-quality import/export.
