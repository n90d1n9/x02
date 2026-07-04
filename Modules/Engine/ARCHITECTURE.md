# Ky Office Engine Architecture

## Overview

This document describes the consolidated architecture of the Ky Office Engine modules, designed for reusability across `ky_docs`, `ky_sheet`, and `ky_slide` applications. The architecture follows best practices with clear separation of concerns, modular design, and native implementation without third-party editor dependencies.

## Architecture Principles

### 1. Separation of Concerns
- **Low-level engines**: Pure parsing/rendering logic (Rust + Dart)
- **Shared primitives**: Common types, geometry, colors
- **Application layer**: UI components, state management, user interaction

### 2. Reusability
- Core engine modules shared across all Ky Office applications
- Consistent data models and APIs
- Plugin-based architecture for extensibility

### 3. Native Implementation
- Zero dependencies on `flutter_quill` or similar third-party editors
- Full control over rendering pipeline
- Optimized performance through Rust FFI

### 4. MS Word Parity
- Complete feature set matching professional word processors
- Support for complex documents, tables, images, charts
- Advanced formatting, styles, and layout

## Module Hierarchy

```
┌─────────────────────────────────────────────────────────┐
│                  Application Layer                       │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      │
│  │  ky_docs    │  │  ky_sheet   │  │  ky_slide   │      │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘      │
└─────────┼────────────────┼────────────────┼─────────────┘
          │                │                │
          └────────────────┼────────────────┘
                           │
          ┌────────────────▼────────────────┐
          │         Shared Components        │
          │  ┌─────────────┐ ┌────────────┐ │
          │  │ky_office_core│ │  ky_print  │ │
          │  └─────────────┘ └────────────┘ │
          └────────────────┬────────────────┘
                           │
          ┌────────────────▼────────────────┐
          │       File Format Readers        │
          │  ┌──────────┐ ┌──────────────┐  │
          │  │docx_reader│ │ pptx_reader  │  │
          │  └────┬─────┘ └──────┬───────┘  │
          │  ┌──────────┐ ┌──────────────┐  │
          │  │pdf_reader │ │ xlsx_reader  │  │
          │  └────┬─────┘ └──────┬───────┘  │
          └───────┼──────────────┼──────────┘
                  │              │
          ┌───────▼──────────────▼──────────┐
          │      Core Engine Modules         │
          │  ┌──────────┐ ┌──────────────┐  │
          │  │office_core│ │office_common │  │
          │  └────┬─────┘ └──────┬───────┘  │
          │  ┌──────────┐ ┌──────────────┐  │
          │  │office_   │ │office_chart  │  │
          │  │multimedia│ └──────┬───────┘  │
          │  └────┬─────┘ ┌──────────────┐  │
          │  ┌──────────┐ │office_       │  │
          │  │office_   │ │animation     │  │
          │  │animation │ └──────────────┘  │
          │  └──────────┘                   │
          └─────────────────────────────────┘
                           │
          ┌────────────────▼────────────────┐
          │          Rust FFI Layer          │
          │  ┌────────────────────────────┐ │
          │  │     docx_reader_ffi        │ │
          │  │  (Rust high-performance)   │ │
          │  └────────────────────────────┘ │
          └─────────────────────────────────┘
```

## Module Descriptions

### Core Foundation Modules

#### `office_common` (v1.0.0)
**Purpose**: Common primitives, geometry, color utilities, and shared types
**Dependencies**: None (foundation module)
**Used by**: All other engine modules

**Key Components**:
- `Color` - RGBA color with conversion utilities
- `Point`, `Rect`, `Size` - Geometry primitives
- `FontMetrics` - Font measurement utilities
- `UnitConverter` - DPI, pixels, points conversion
- `MathUtils` - Common mathematical operations

**Example**:
```dart
import 'package:office_common/office_common.dart';

final color = Color.fromHex('#FF5733');
final rect = Rect.fromLTWH(10, 20, 100, 50);
final fontSize = UnitConverter.pointsToPixels(12, dpi: 96);
```

---

#### `office_core` (v1.0.0)
**Purpose**: Core document models (Document, Block, Run, Style, Table)
**Dependencies**: `office_common`
**Used by**: `docx_reader`, `pptx_reader`, `pdf_reader`, `xlsx_reader`, `ky_docs`

**Key Models**:
- `Document` - Root document container
- `Block` - Base class for paragraphs, headings, lists, tables
- `Run` - Text segment with formatting
- `Style` - Named style definitions
- `Table`, `TableRow`, `TableCell` - Table structures
- `Image`, `Chart`, `Shape` - Embedded objects

**Block Types**:
```dart
enum BlockType {
  paragraph,
  heading1, heading2, heading3, heading4, heading5, heading6,
  listBulleted, listNumbered,
  table,
  image,
  chart,
  pageBreak,
  header,
  footer,
}
```

**Example**:
```dart
import 'package:office_core/office_core.dart';

final doc = Document(title: 'My Document');
final paragraph = ParagraphBlock(
  runs: [
    Run(text: 'Hello ', bold: true),
    Run(text: 'World', italic: true),
  ],
  styleId: 'Normal',
);
doc.addBlock(paragraph);
```

---

### Multimedia & Visualization Modules

#### `office_multimedia` (v1.0.0)
**Purpose**: Multimedia handling (images, audio, video, embedded objects)
**Dependencies**: `office_common`, `office_core`
**Used by**: `docx_reader`, `pptx_reader`, `ky_docs`, `ky_slide`

**Key Features**:
- Image loading from files, URLs, base64
- Image caching and optimization
- Audio/video embedding
- EXIF metadata extraction
- Image transformations (resize, crop, rotate)

**Example**:
```dart
import 'package:office_multimedia/office_multimedia.dart';

final image = await ImageLoader.fromFile('path/to/image.jpg');
final thumbnail = image.resize(width: 200, height: 150);
final embedded = EmbeddedObject(image: thumbnail, altText: 'Description');
```

---

#### `office_chart` (v1.0.0)
**Purpose**: Chart rendering engine (bar, line, pie, area, radar, scatter)
**Dependencies**: `office_common`, `office_core`
**Used by**: `docx_reader`, `xlsx_reader`, `ky_docs`, `ky_sheet`

**Chart Types**:
- BarChart (vertical/horizontal)
- LineChart (with markers)
- PieChart (with explosion)
- AreaChart (stacked/percent)
- RadarChart (spider web)
- ScatterPlot (with trend lines)

**Example**:
```dart
import 'package:office_chart/office_chart.dart';

final chart = Chart.bar(
  title: 'Sales Report',
   [
    ChartSeries(name: '2023', values: [100, 150, 200]),
    ChartSeries(name: '2024', values: [120, 180, 220]),
  ],
  labels: ['Q1', 'Q2', 'Q3'],
);
```

---

#### `office_animation` (v1.0.0)
**Purpose**: Animation system for transitions, effects, and dynamic content
**Dependencies**: `office_common`
**Used by**: `ky_docs`, `ky_slide`, `pptx_reader`

**Animation Types**:
- FadeIn, FadeOut
- SlideIn (from all directions)
- ZoomIn, ZoomOut
- Bounce, Elastic
- Custom tween animations

**Example**:
```dart
import 'package:office_animation/office_animation.dart';

final animation = Animation.fadeIn(
  duration: Duration(milliseconds: 500),
  curve: Curves.easeInOut,
);
await animation.play(widget);
```

---

### File Format Readers

#### `docx_reader` (v1.0.0)
**Purpose**: DOCX/DOC file parser and reader engine
**Dependencies**: `office_common`, `office_core`, `office_multimedia`
**Used by**: `ky_docs`

**Features**:
- Office Open XML (.docx) parsing
- Legacy .doc support (via conversion)
- Styles and themes extraction
- Images and embedded objects
- Tables, lists, headers/footers
- Track changes and comments (read-only initially)

**Usage**:
```dart
import 'package:docx_reader/docx_reader.dart';

final reader = DocxReader();
final document = await reader.load('sample.docx');
print('Title: ${document.title}');
print('Blocks: ${document.blocks.length}');
```

---

#### `docx_reader_ffi` (v1.0.0)
**Purpose**: Rust FFI bindings for high-performance DOCX/DOC parsing
**Dependencies**: None (Dart FFI wrapper)
**Used by**: `docx_reader` (optional acceleration)

**FFI Functions**:
- `docx_create_document()` - Create new document
- `docx_load_file(path)` - Load from file path
- `docx_save_file(handle, path)` - Save to file
- `docx_add_paragraph(handle, text, styleId)` - Add content
- `docx_serialize_json(handle)` - Export to JSON
- `docx_deserialize_json(json)` - Import from JSON

**Usage**:
```dart
import 'package:docx_reader_ffi/docx_reader_ffi.dart';

final ffi = DocxReaderFFI();
await ffi.initialize();
final handle = ffi.loadFile('sample.docx');
final title = ffi.getTitle(handle);
ffi.freeDocument(handle);
```

---

### Future Readers (Planned)

#### `pptx_reader` (v1.0.0 - Planned)
**Purpose**: PPTX/PPT presentation parser
**Dependencies**: `office_common`, `office_core`, `office_multimedia`, `office_animation`
**Used by**: `ky_slide`

#### `xlsx_reader` (v1.0.0 - Planned)
**Purpose**: XLSX/XLS spreadsheet parser
**Dependencies**: `office_common`, `office_core`, `office_chart`
**Used by**: `ky_sheet`

#### `pdf_reader` (v1.0.0 - Planned)
**Purpose**: PDF document parser
**Dependencies**: `office_common`, `office_core`, `office_multimedia`
**Used by**: All applications (import/export)

---

## Data Flow

### Import Flow (DOCX → ky_docs)

```
┌──────────────┐
│  sample.docx │
└──────┬───────┘
       │
       ▼
┌──────────────────┐
│   docx_reader    │  (Dart parser)
│   or             │
│ docx_reader_ffi  │  (Rust FFI - optional)
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│  office_core     │  (Document model)
│  - Document      │
│  - Blocks        │
│  - Styles        │
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│  DocumentNotifier│  (State management)
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ DocumentCanvas   │  (Native rendering)
│  - BlockRenderer │
│  - LayoutEngine  │
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│   Flutter UI     │
│   (ky_docs)      │
└──────────────────┘
```

### Export Flow (ky_docs → DOCX/PDF)

```
┌──────────────────┐
│   Flutter UI     │
│   (ky_docs)      │
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ DocumentNotifier│
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│  office_core     │  (Document model)
└──────┬───────────┘
       │
       ├──────────────┐
       │              │
       ▼              ▼
┌─────────────┐ ┌─────────────┐
│ DOCX Writer │ │ PDF Writer  │
│ (in plan)   │ │ (in plan)   │
└──────┬──────┘ └──────┬──────┘
       │               │
       ▼               ▼
┌─────────────┐ ┌─────────────┐
│ sample.docx │ │ sample.pdf  │
└─────────────┘ └─────────────┘
```

---

## Best Practices

### 1. Module Dependencies
- Always depend on specific version ranges
- Use relative paths for local modules during development
- Avoid circular dependencies (enforced by architecture)

### 2. Error Handling
```dart
try {
  final doc = await DocxReader().load('file.docx');
} on ParserException catch (e) {
  print('Parse error: ${e.message}');
} on IOException catch (e) {
  print('IO error: ${e.message}');
}
```

### 3. Performance Optimization
- Use Rust FFI for large documents (>100 pages)
- Implement lazy loading for images
- Cache rendered blocks
- Use isolates for heavy parsing

### 4. Testing Strategy
```dart
// Unit tests for each module
test('DocxReader parses simple document', () {
  final doc = DocxReader().loadSync('test.docx');
  expect(doc.blocks.length, greaterThan(0));
});

// Integration tests
test('Import-edit-export roundtrip', () async {
  final doc1 = await DocxReader().load('original.docx');
  final bytes = await DocxWriter().write(doc1);
  final doc2 = await DocxReader().loadBytes(bytes);
  expect(doc2.title, equals(doc1.title));
});
```

---

## Migration from Quill

| Quill Component | Ky Office Replacement |
|-----------------|----------------------|
| `QuillEditor` | `DocumentCanvas` |
| `QuillController` | `DocumentNotifier` |
| `Delta` operations | `Block` operations |
| `Attribute` | `Style` + `Run` properties |
| `Embed` | `Image`, `Chart`, `Table` blocks |

---

## Version Compatibility

| Module | Min SDK | Min Flutter | Status |
|--------|---------|-------------|--------|
| office_common | 3.0.0 | 3.10.0 | ✅ Ready |
| office_core | 3.0.0 | 3.10.0 | ✅ Ready |
| office_multimedia | 3.0.0 | 3.10.0 | ✅ Ready |
| office_chart | 3.0.0 | 3.10.0 | ✅ Ready |
| office_animation | 3.0.0 | 3.10.0 | ✅ Ready |
| docx_reader | 3.0.0 | 3.10.0 | ✅ Ready |
| docx_reader_ffi | 3.0.0 | N/A | ✅ Ready |

---

## Next Steps

1. **Implement remaining readers**: `pptx_reader`, `xlsx_reader`, `pdf_reader`
2. **Build Rust FFI library**: Compile `docx_reader_ffi` for all platforms
3. **Create writers**: DOCX writer, PDF exporter
4. **Add advanced features**: Track changes, comments, collaboration
5. **Performance tuning**: Benchmark and optimize critical paths

---

## Conclusion

The Ky Office Engine architecture provides a solid foundation for building professional-grade office applications with full control over the rendering pipeline, optimal performance through Rust FFI, and maximum code reuse across the entire suite. The modular design ensures maintainability and extensibility for future enhancements.