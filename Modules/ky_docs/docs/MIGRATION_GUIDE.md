# Migration Guide: Quill to Native Engine

This guide explains how to migrate from `flutter_quill` to the native Rust-backed document engine.

## Overview

The `ky_docs` package now supports two modes of operation:

1. **Quill Mode** (Legacy): Uses `flutter_quill` for rich text editing
2. **Native Engine Mode**: Uses the Rust `docx_reader` via FFI for block-based editing (MS Word/GDocs-like)

## Architecture Comparison

### Before (Quill-based)
```
Flutter UI → QuillController → Delta Document → JSON Storage
```

### After (Native Engine)
```
Flutter UI → DocumentEngine (FFI) → Rust docx_reader → JSON/DOCX
                              ↓
                       parser-docx Parser
```

## Step-by-Step Migration

### 1. Update Dependencies

Ensure your `pubspec.yaml` includes:

```yaml
dependencies:
  ffi: ^2.1.0
  flutter_riverpod: ^3.0.3
  
# Optional: Keep flutter_quill during transition
# flutter_quill: ^11.5.1
```

### 2. Initialize the Engine

```dart
import 'package:ky_docs/ky_docs.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize the native engine
  final engine = DocumentEngine.instance;
  await engine.initialize();
  
  runApp(MyApp());
}
```

### 3. Replace Editor Widget

**Old (Quill):**
```dart
import 'package:flutter_quill/flutter_quill.dart';

QuillEditor(
  controller: _controller,
  scrollController: _scrollController,
  config: const QuillEditorConfig(),
)
```

**New (Native Engine):**
```dart
import 'package:ky_docs/ky_docs.dart';

NativeDocumentCanvas(
  layout: PageLayout.print,
  onDocumentLoaded: () => print('Document ready'),
  onDocumentChanged: (text) => print('Changed: $text'),
)
```

### 4. Update State Management

**Old (Quill with Riverpod):**
```dart
final documentControllerProvider =
    StateNotifierProvider<DocumentNotifier, DocumentState>((ref) {
  return DocumentNotifier();
});

class DocumentNotifier extends StateNotifier<DocumentState> {
  DocumentNotifier() : super(DocumentState(controller: QuillController.basic()));
}
```

**New (Native Engine):**
```dart
final nativeDocumentProvider = StateNotifierProvider.family<
    NativeDocumentNotifier, NativeDocumentState, DocumentEngine>((ref, engine) {
  return NativeDocumentNotifier(engine, ref.read(docxParserProvider));
});

// Usage in widget:
final state = ref.watch(nativeDocumentProvider(ref.read(documentEngineProvider)));
```

### 5. Document Operations

#### Creating a Document

```dart
final engine = DocumentEngine.instance;
final handle = await engine.createDocument('My Document');
```

#### Adding Content

```dart
// Add paragraph
await engine.addParagraph(handle, 'Hello World');

// Add heading
await engine.addHeading(handle, 'Chapter 1', level: 1);

// Add list item
await engine.addListItem(handle, 'Item 1', ordered: false);

// Add code block
await engine.addCodeBlock(handle, 'print("Hello")', language: 'dart');
```

#### Editing Text

```dart
// Insert text at position
await engine.insertText(handle, blockIndex: 0, spanIndex: 0, offset: 5, text: 'Beautiful ');

// Split block (for Enter key)
await engine.splitBlock(handle, blockIndex: 0, spanIndex: 0, offset: 10);
```

#### Getting Document State

```dart
final blocks = await handle.getBlocks();
final count = await handle.getBlockCount();
final title = await handle.getTitle();
final json = await handle.serialize();
```

### 6. DOCX Import/Export

```dart
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:ky_docs/ky_docs.dart';

// Import DOCX
final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['docx']);
if (result != null) {
  final bytes = result.files.first.bytes!;
  final parser = DocxParserService();
  final content = await parser.parseDocx(bytes);
  
  // Create document from parsed content
  final engine = DocumentEngine.instance;
  final handle = await engine.createDocument(content.title);
  // ... add blocks from content
}

// Export to DOCX
final engine = DocumentEngine.instance;
final handle = await engine.createDocument('Export Me');
// ... add content
final docxBytes = await DocxParserService().generateDocx(await handle.getDocument());
```

## Feature Parity Matrix

| Feature | Quill | Native Engine | Notes |
|---------|-------|---------------|-------|
| Paragraphs | ✅ | ✅ | Block-based in native |
| Headings (H1-H3) | ✅ | ✅ | Native supports H1-H6 |
| Bold/Italic/Underline | ✅ | ✅ | Via TextStyle |
| Lists (ordered/unordered) | ✅ | ✅ | Block types |
| Code blocks | ✅ | ✅ | With syntax highlighting |
| Quotes | ✅ | ✅ | Blockquote style |
| Images | ✅ | 🔄 | Coming soon |
| Tables | ❌ | ✅ | Native only |
| Headers/Footers | ❌ | ✅ | Native only |
| Page layout | ❌ | ✅ | Print/Web/Outline modes |
| Rulers | ❌ | ✅ | Horizontal & vertical |
| DOCX import | ⚠️ Limited | ✅ Full | Via parser-docx |
| DOCX export | ❌ | ✅ | Via parser-docx |
| Real-time collaboration | ❌ | 🔄 CRDT-ready | Edit operations |
| Track changes | ❌ | 🔄 Planned | |
| Comments | ✅ | 🔄 Planned | |
| Spell check | ✅ | 🔄 Planned | |
| Word count | ✅ | ✅ | Via stats |

## Migration Checklist

- [ ] Add FFI dependencies to pubspec.yaml
- [ ] Initialize DocumentEngine at app startup
- [ ] Replace QuillEditor with NativeDocumentCanvas
- [ ] Update state providers to use NativeDocumentNotifier
- [ ] Migrate document creation logic
- [ ] Update save/load operations
- [ ] Test DOCX import/export
- [ ] Verify formatting toolbar actions
- [ ] Test keyboard shortcuts
- [ ] Validate on all target platforms (Android, iOS, Linux, macOS, Windows)

## Rollback Plan

If you need to rollback to Quill:

1. Keep both widgets in your codebase
2. Use a feature flag to switch between them:

```dart
Widget build(BuildContext context) {
  final useNativeEngine = ref.watch(useNativeEngineProvider);
  
  return useNativeEngine
      ? NativeDocumentCanvas(...)
      : QuillEditor(...);
}
```

3. Gradually migrate features one at a time

## Performance Benefits

The native engine provides:

- **Faster rendering**: Direct block rendering vs. rich text composition
- **Lower memory usage**: Efficient Rust data structures
- **Better large document handling**: Optimized for 100+ page documents
- **Native DOCX support**: Full-fidelity import/export
- **CRDT foundation**: Ready for real-time collaboration

## Troubleshooting

### Engine not loading

```
Warning: Failed to load native library
```

**Solution:** Ensure the Rust FFI library is built and copied to the correct location:
- Android: `android/app/src/main/jniLibs/<abi>/libdocx_reader_ffi.so`
- iOS: Included in framework bundle
- Linux: `libdocx_reader_ffi.so` in library path
- macOS: `libdocx_reader_ffi.dylib` in Frameworks
- Windows: `docx_reader_ffi.dll` alongside executable

### Blocks not rendering

Check that:
1. Engine is initialized before creating documents
2. You're using the correct block type strings
3. Text spans are properly formatted

### DOCX parsing fails

Verify:
1. File is a valid .docx (not .doc)
2. File is not corrupted
3. Sufficient memory available for large files

## Next Steps

After migration:

1. **Enable advanced features**: Tables, headers/footers, footnotes
2. **Add collaboration**: Integrate with WebSocket backend for real-time editing
3. **Improve performance**: Profile and optimize rendering for very large documents
4. **Add AI features**: Leverage the structured block model for AI assistance

## Support

For issues or questions:
- Check the API documentation in `lib/engine/document_engine.dart`
- Review example usage in test files
- Open an issue on the repository
