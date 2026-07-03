# Ky Docs - Professional Document Editor

A Flutter-based document editor inspired by MS Word and Google Docs, featuring:

- **Modern UI/UX**: Clean, intuitive interface similar to leading word processors
- **Rust-Powered Engine**: High-performance document operations via FFI integration with `docs_engine`
- **DOCX Compatibility**: Full import/export support using the `ky-of-docx` parser
- **Real-time Collaboration**: Multi-user editing with presence indicators
- **Rich Formatting**: Support for paragraphs, headings, lists, tables, and more
- **Page Layout**: Print layout view with rulers, margins, and page settings
- **Cloud Sync**: Automatic saving and synchronization

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter GUI Layer                        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │
│  │   Toolbar   │  └─────────────┘  │  Document Canvas    │ │
│  └─────────────┘                   └─────────────────────┘ │
│  ┌─────────────────────────────────────────────────────────┐│
│  │              State Management (Riverpod)                ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
                            ↕
┌─────────────────────────────────────────────────────────────┐
│                  Dart Engine Layer                          │
│  ┌──────────────────┐  ┌──────────────────────────────────┐ │
│  │ DocumentEngine   │  │ DocxParserService                │ │
│  │ - Block ops      │  │ - DOCX import/export             │ │
│  │ - Text formatting│  │ - Metadata extraction            │ │
│  │ - Selection      │  │ - Format conversion              │ │
│  └──────────────────┘  └──────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                            ↕ FFI
┌─────────────────────────────────────────────────────────────┐
│                   Rust Engine Layer                         │
│  ┌──────────────────┐  ┌──────────────────────────────────┐ │
│  │  docs_engine     │  │  ky-of-docx (Parser)             │ │
│  │  - Document DOM  │  │  - DOCX parsing                  │ │
│  │  - Operations    │  │  - DOCX generation               │ │
│  │  - Serialization │  │  - Format validation             │ │
│  └──────────────────┘  └──────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## Integration with Engine

### Using the Document Engine

```dart
import 'package:ky_docs/engine/engine.dart';

final engine = DocumentEngine.instance;

// Create a new document
final doc = await engine.createDocument('My Document');

// Insert text
await engine.insertText(
  documentId: doc.id,
  blockIndex: 0,
  spanIndex: 0,
  charOffset: 0,
  text: 'Hello, World!',
);

// Apply formatting
await engine.formatText(
  documentId: doc.id,
  blockIndex: 0,
  spanIndex: 0,
  startOffset: 0,
  length: 5,
  style: TextStyle(bold: true),
);

// Export to JSON
final json = await engine.exportToJson(doc);
```

### Using the DOCX Parser

```dart
import 'package:ky_docs/engine/engine.dart';

final parser = DocxParserService.instance;

// Import from DOCX
final bytes = await File('document.docx').readAsBytes();
final document = await parser.parseDocx(bytes);

// Export to DOCX
final docxBytes = await parser.generateDocx(document);
await File('output.docx').writeAsBytes(docxBytes);
```

## Replacing Quill with Native Engine

Currently, ky_docs uses `flutter_quill` for the editor component. The architecture supports migrating to a native rendering engine:

### Current State (Quill-based)
```dart
// In editor_with_ruler.dart
child: quill.QuillEditor.basic(
  controller: widget.controller,
  // ...
)
```

### Future State (Native Engine)
```dart
// Custom renderer using DocumentEngine
child: DocumentCanvas(
  document: document,
  engine: DocumentEngine.instance,
  // ...
)
```

## Features Comparison

| Feature | MS Word | Google Docs | Ky Docs |
|---------|---------|-------------|---------|
| Rich Text Editing | ✓ | ✓ | ✓ |
| DOCX Support | ✓ | ✓ | ✓ |
| Real-time Collaboration | ✓ | ✓ | ✓ |
| Offline Mode | ✓ | Limited | ✓ |
| Cross-platform | Limited | Web | ✓ (Flutter) |
| Open Source | ✗ | ✗ | ✓ |
| Rust Performance | ✗ | ✗ | ✓ |

## Project Structure

```
Plugins/ky_docs/
├── lib/
│   ├── engine/           # Rust engine integration
│   │   ├── document_engine.dart
│   │   └── docx_parser_service.dart
│   ├── docx/
│   │   ├── screens/      # Editor screens
│   │   ├── widgets/      # UI components
│   │   ├── models/       # Data models
│   │   ├── services/     # Business logic
│   │   └── states/       # Riverpod providers
│   └── ky_docs.dart      # Main export
├── assets/
│   ├── templates/        # Document templates
│   └── icons/           # Custom icons
└── test/                # Unit tests
```

## Roadmap

- [ ] Complete FFI bindings for Rust engine
- [ ] Native document canvas renderer (replace Quill)
- [ ] Advanced table editing
- [ ] Track changes with visual diff
- [ ] Comments and suggestions mode
- [ ] AI-powered writing assistant
- [ ] Plugin system for extensions

## License

MIT License
