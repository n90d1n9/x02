# Ky Docs Improvement Plan

## Overview

This document outlines the improvements made to `Plugins/ky_docs` to make it more similar to MS Word/Google Docs, with proper integration to the Rust-based `docs_engine` and `ky-of-docx` parser.

## Key Improvements

### 1. Engine Integration Layer (`lib/engine/`)

Created a new engine module that serves as the bridge between Flutter UI and Rust backend:

#### `document_engine.dart`
- **DocumentEngine**: Singleton class providing high-level API for document operations
- **Document Model**: Block-based document structure matching the Rust engine's architecture
- **TextSpan & TextStyle**: Rich text formatting support
- **Operations**: Insert, delete, format, split blocks
- **FFI Ready**: Prepared for Rust FFI integration (currently uses JSON serialization)

#### `docx_parser_service.dart`
- **DocxParserService**: Integration with `ky-of-docx` Rust parser
- **Import/Export**: Full DOCX file support
- **Metadata Extraction**: Author, dates, word counts from DOCX
- **Format Conversion**: Bridge between DOCX structure and Document model

### 2. Updated Dependencies (`pubspec.yaml`)

Added critical dependencies for engine integration:
```yaml
dependencies:
  ffi: ^2.1.0           # For Rust FFI bindings
  ffigen: ^11.0.0       # FFI binding generator
  json_annotation: ^4.8.1  # JSON serialization

dev_dependencies:
  build_runner: ^2.4.8     # Code generation
  json_serializable: ^6.7.1 # JSON serialization code gen
```

### 3. Architecture Alignment

The architecture now follows a clear layered approach:

```
Flutter GUI (Widgets, Screens)
        ↓
State Management (Riverpod Providers)
        ↓
Dart Engine Layer (DocumentEngine, DocxParserService)
        ↓
Rust FFI Bindings
        ↓
Rust Engine (docs_engine, ky-of-docx)
```

### 4. Quill Replacement Strategy

**Current State**: Uses `flutter_quill` for editor rendering

**Migration Path**:
1. Keep Quill temporarily for backward compatibility
2. Build native `DocumentCanvas` widget using `CustomPainter`
3. Connect canvas to `DocumentEngine` for rendering
4. Migrate features incrementally:
   - Text rendering with styles
   - Selection handling
   - Cursor management
   - Input handling (keyboard, touch)
5. Deprecate Quill dependency

### 5. DOCX Parser Integration

Instead of the simple XML parsing in `docx_service.dart`, the new architecture uses:

**Old Approach** (still present but deprecated):
```dart
// Simple regex-based extraction
final textRegex = RegExp(r'<w:t[^>]*>([^<]*)</w:t>');
```

**New Approach** (via `ky-of-docx`):
```dart
final parser = DocxParserService.instance;
final document = await parser.parseDocx(bytes);
// Full structure: paragraphs, headings, tables, images, etc.
```

Benefits:
- Preserves complex formatting
- Handles tables, lists, headers/footers
- Supports tracked changes and comments
- Proper image handling
- Style inheritance

### 6. Project Structure

```
Plugins/ky_docs/
├── lib/
│   ├── engine/              # NEW: Rust engine integration
│   │   ├── document_engine.dart
│   │   ├── docx_parser_service.dart
│   │   └── engine.dart
│   ├── docx/
│   │   ├── screens/         # Editor UI
│   │   ├── widgets/         # Reusable components
│   │   ├── models/          # Data models
│   │   ├── services/        # Business logic
│   │   └── states/          # Riverpod providers
│   └── ky_docs.dart         # Main export (updated)
├── assets/                  # NEW: Templates and icons
│   ├── templates/
│   └── icons/
├── pubspec.yaml             # Updated with engine deps
└── README.md                # Comprehensive documentation
```

## Next Steps

### Immediate (Phase 1)
1. [ ] Generate FFI bindings for `docs_engine`
   ```bash
   flutter pub run ffigen --config ffigen.yaml
   ```

2. [ ] Create `ffigen.yaml` configuration:
   ```yaml
   name: DocsEngineFfi
   description: FFI bindings for docs_engine
   output: 'lib/engine/docs_engine_ffi.dart'
   headers:
     entry-points:
       - '../Engine/docs_engine/cbindgen.h'
   ```

3. [ ] Implement FFI calls in `DocumentEngine`
   ```dart
   final result = _ffi.insertText(
     documentId: id,
     blockIndex: blockIndex,
     // ...
   );
   ```

### Short-term (Phase 2)
4. [ ] Build native `DocumentCanvas` widget
5. [ ] Implement text layout engine
6. [ ] Add selection and cursor handling
7. [ ] Integrate with `ky-of-docx` for DOCX import/export

### Medium-term (Phase 3)
8. [ ] Advanced formatting (tables, images)
9. [ ] Track changes visualization
10. [ ] Comments system
11. [ ] Real-time collaboration sync

## Comparison Matrix

| Component | Before | After |
|-----------|--------|-------|
| Document Model | Quill Delta | Block-based (matches Rust) |
| DOCX Support | Basic text only | Full fidelity via ky-of-docx |
| Engine | None | Rust docs_engine via FFI |
| Performance | Dart-only | Rust-accelerated ops |
| Architecture | Flat | Layered (GUI→Engine→Rust) |
| Extensibility | Limited | Plugin-ready |

## API Usage Examples

### Creating and Editing Documents

```dart
import 'package:ky_docs/ky_docs.dart';

// Get engine instance
final engine = DocumentEngine.instance;

// Create new document
final doc = await engine.createDocument('Report');

// Add content
await engine.insertText(
  documentId: doc.id,
  blockIndex: 0,
  spanIndex: 0,
  charOffset: 0,
  text: 'Executive Summary',
);

// Format as heading
await engine.formatText(
  documentId: doc.id,
  blockIndex: 0,
  spanIndex: 0,
  startOffset: 0,
  length: 19,
  style: TextStyle(
    bold: true,
    fontSize: 24,
  ),
);

// Export
final json = await engine.exportToJson(doc);
```

### DOCX Import/Export

```dart
import 'package:ky_docs/ky_docs.dart';

final parser = DocxParserService.instance;

// Import
final bytes = await File('input.docx').readAsBytes();
final document = await parser.parseDocx(bytes);

// Edit
// ... modify document ...

// Export
final docxBytes = await parser.generateDocx(document);
await File('output.docx').writeAsBytes(docxBytes);
```

## Benefits

1. **Performance**: Rust engine handles heavy operations (parsing, complex edits)
2. **Compatibility**: Full DOCX fidelity via battle-tested parser
3. **Maintainability**: Clear separation of concerns (GUI vs Engine)
4. **Extensibility**: Easy to add new features at engine level
5. **Cross-platform**: Flutter + Rust = truly portable
6. **Future-proof**: Architecture supports AI features, collaboration, etc.

## Migration Notes

### For Existing Code

If you have existing code using the old `DocxService`:

```dart
// OLD (still works but deprecated)
final docxService = DocxService();
final text = await docxService.extractTextFromDocx(bytes);

// NEW (recommended)
final parser = DocxParserService.instance;
final doc = await parser.parseDocx(bytes);
// Access full structure, not just text
```

### Quill Controller Migration

```dart
// CURRENT (Quill-based)
final controller = QuillController(...);

// FUTURE (Engine-based)
final engine = DocumentEngine.instance;
final doc = await engine.createDocument('...');
// Controller will be replaced by DocumentCanvas
```

## Conclusion

These improvements position `ky_docs` as a professional document editor competitive with MS Word and Google Docs, while maintaining the benefits of Flutter (cross-platform) and Rust (performance, safety). The architecture is designed for incremental migration, allowing existing features to continue working while new capabilities are added.