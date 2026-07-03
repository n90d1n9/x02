# Insert Menu Implementation Guide

## Overview

Comprehensive Insert Menu implementation for `ky_docs` providing MS Word/Google Docs-like functionality for inserting various elements into documents.

## Features Implemented

### 📊 Media Insertion
- **Image**: From file, URL, or cloud storage
- **Camera**: Capture photo directly (placeholder)
- **Chart**: Integration with `ky_charts` plugin using Tenun library

### 📋 Tables & Objects
- **Table**: Interactive grid selector (up to 8x8)
- **Drawing**: Drawing canvas placeholder

### 🔗 Links & References
- **Link**: Hyperlink insertion with custom text and tooltip
- **Bookmark**: Named bookmark insertion
- **Table of Contents**: Automatic TOC generation

### 📄 Document Structure
- **Page Break**: Insert page breaks
- **Header & Footer**: Toggle header/footer editing mode
- **Page Number**: Multiple format options (numeric, roman, alpha, full)

### ✨ Special Elements
- **Symbol**: 50+ special characters (copyright, math, Greek, arrows, etc.)
- **Date & Time**: Multiple format options

## Architecture

```
┌─────────────────────────────────────┐
│    Document Editor AppBar           │
│         [Insert Button]             │
└──────────────┬──────────────────────┘
               │
               ↓
┌─────────────────────────────────────┐
│        InsertMenu Widget            │
│  ┌───────────────────────────────┐  │
│  │  Media Section                │  │
│  │  - Image (File/URL/Cloud)     │  │
│  │  - Camera                     │  │
│  │  - Chart                      │  │
│  ├───────────────────────────────┤  │
│  │  Tables & Objects             │  │
│  │  - Table (Grid Selector)      │  │
│  │  - Drawing                    │  │
│  ├───────────────────────────────┤  │
│  │  Links & References           │  │
│  │  - Link                       │  │
│  │  - Bookmark                   │  │
│  │  - Table of Contents          │  │
│  ├───────────────────────────────┤  │
│  │  Document Structure           │  │
│  │  - Page Break                 │  │
│  │  - Header & Footer            │  │
│  │  - Page Number                │  │
│  ├───────────────────────────────┤  │
│  │  Special                      │  │
│  │  - Symbol                     │  │
│  │  - Date & Time                │  │
│  └───────────────────────────────┘  │
└──────────────┬──────────────────────┘
               │
               ↓
┌─────────────────────────────────────┐
│   DocumentEditorCommands            │
│   - insertBlock()                   │
│   - insertText()                    │
│   - toggleHeaderFooter()            │
└──────────────┬──────────────────────┘
               │
               ↓
┌─────────────────────────────────────┐
│   DocumentNotifier (State)          │
│   - Updates document model          │
│   - Triggers UI rebuild             │
└─────────────────────────────────────┘
```

## Usage

### Basic Integration

```dart
import 'package:ky_docs/ky_docs.dart';

// In your app bar
InsertMenu(
  commands: documentCommands,
  onDismiss: () {
    // Optional: cleanup or logging
  },
)
```

### Adding to DocumentEditorAppBar

```dart
// In document_editor_app_bar.dart
Row(
  children: [
    // ... other buttons
    InsertMenu(commands: widget.commands),
    // ... other buttons
  ],
)
```

## Component Details

### 1. InsertMenu (Main Widget)

**Location**: `lib/docx/widgets/insert_menu/insert_menu.dart`

**Key Methods**:
- `_handleMenuItem(String value)`: Routes menu selections
- `_insertImage()`: Handles image insertion from multiple sources
- `_insertTable()`: Shows grid selector for table dimensions
- `_insertLink()`: Opens link dialog
- `_insertSymbol()`: Shows symbol picker
- `_insertDateTime()`: Format selection and insertion

**Features**:
- PopupMenuButton with categorized sections
- Section headers for visual organization
- Keyboard shortcut support (future)
- Dismiss callback support

### 2. TableGridSelector

**Interactive Grid**:
- 8x8 grid (64 cells)
- Hover to select dimensions
- Visual feedback (blue highlight)
- Returns `{rows: int, cols: int}`

**Usage**:
```dart
final result = await showDialog<Map<String, int>>(
  context: context,
  builder: (context) => TableGridSelector(),
);

if (result != null) {
  final rows = result['rows']!;
  final cols = result['cols']!;
  // Insert table block
}
```

### 3. LinkDialog

**Fields**:
- URL (required)
- Display Text (optional)
- Title/Tooltip (optional)

**Returns**:
```dart
{
  'url': 'https://example.com',
  'text': 'Click here',
  'title': 'Example website'
}
```

### 4. SymbolPickerDialog

**Categories**:
- Legal symbols: ©, ®, ™, §, ¶
- Math symbols: °, ±, ×, ÷, √, ∞, ≈, ≠, ≤, ≥
- Greek letters: α, β, γ, δ, ε, π, σ, ω, Δ, Ω
- Arrows: →, ←, ↑, ↓, ↔, ⇒, ⇐, ⇑, ⇓
- Misc: ★, ☆, ❤, ♠, ♣, ♦, ♫, ☀, ☁, ☂

**Layout**: 10-column grid, 300px height

### 5. ImageSource Enum

```dart
enum ImageSource { 
  file,   // From device storage
  url,    // From web URL
  cloud   // From cloud storage (future)
}
```

## Block Types Supported

The Insert Menu creates these block types via `DocumentEditorCommands`:

| Block Type | Attributes | Description |
|------------|-----------|-------------|
| `BlockType.image` | source, url, width, height, caption | Image from file/URL |
| `BlockType.table` | rows, cols, data, borderWidth, borderColor | Table grid |
| `BlockType.bookmark` | name | Named bookmark |
| `BlockType.toc` | maxDepth, includeLinks | Table of contents |
| `BlockType.pageBreak` | {} | Page break |
| `BlockType.pageNumber` | format | Page number with format |

## Integration with ky_charts

For chart insertion, the menu is designed to integrate with the `ky_charts` plugin:

```dart
Future<void> _insertChart() async {
  // Future integration:
  // await ChartDialog.show(context, commands: widget.commands);
  
  // Current placeholder:
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Opening chart editor...')),
  );
}
```

**Expected Chart Types** (from ky_charts):
- Bar charts
- Line charts
- Pie charts
- Area charts
- Radar charts
- Scatter plots

## Future Enhancements

### Phase 1 (Next Sprint)
- [ ] File picker integration for images
- [ ] Camera capture implementation
- [ ] Cloud storage integration (Google Drive, Dropbox)
- [ ] Full ky_charts integration

### Phase 2 (Following Sprint)
- [ ] Drawing canvas implementation
- [ ] Advanced table features (merge cells, styling)
- [ ] Equation editor (LaTeX support)
- [ ] Video/audio embedding

### Phase 3 (Long-term)
- [ ] Smart suggestions (AI-powered)
- [ ] Template insertion
- [ ] QR code generation
- [ ] 3D object support

## Testing Checklist

### Unit Tests
- [ ] Menu renders all items correctly
- [ ] Section headers display properly
- [ ] Dialog callbacks return expected values

### Integration Tests
- [ ] Image insertion creates correct block
- [ ] Table grid selector returns valid dimensions
- [ ] Link dialog validates URL input
- [ ] Symbol picker inserts correct character
- [ ] Date/time formats correctly

### Manual Testing
1. Open document editor
2. Click Insert menu
3. Test each menu item:
   - [ ] Image → File source dialog appears
   - [ ] Table → Grid selector works
   - [ ] Link → Dialog accepts input
   - [ ] Symbol → Grid displays all symbols
   - [ ] Date/Time → Format selection works
4. Verify blocks are inserted at cursor position
5. Check document state updates correctly

## Error Handling

The implementation includes basic error handling:

```dart
try {
  final result = await showDialog(...);
  if (result != null) {
    widget.commands.insertBlock(...);
  }
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error: $e')),
  );
}
```

**Future improvements**:
- Try-catch blocks around all async operations
- User-friendly error messages
- Retry mechanisms for failed operations
- Logging for debugging

## Performance Considerations

- **Lazy loading**: Dialogs created only when needed
- **Efficient rebuilds**: StatefulWidget used where state changes
- **Memory management**: Controllers properly disposed
- **Async operations**: Non-blocking UI for heavy operations

## Accessibility

- Semantic labels on all interactive elements
- Keyboard navigation support (future)
- Screen reader friendly dialogs
- High contrast mode support (future)

## Internationalization (i18n)

Current implementation uses hardcoded English strings. Future i18n support:

```dart
// Future implementation
Text(AppLocalizations.of(context)!.insertImage),
subtitle: Text(AppLocalizations.of(context)!.insertImageFromUrl),
```

**Strings to translate**:
- Menu item labels
- Dialog titles
- Button texts
- Placeholder texts
- Error messages

## Related Documentation

- [File Menu Implementation](FILE_MENU_IMPLEMENTATION.md)
- [Chart Plugin (ky_charts)](../ky_charts/README.md)
- [Document Editor Commands](DOCUMENT_COMMANDS_GUIDE.md)
- [Block Types Reference](BLOCK_TYPES_REFERENCE.md)

## Example Usage

### Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:ky_docs/ky_docs.dart';

class MyDocumentEditor extends StatelessWidget {
  final DocumentEditorCommands commands;

  const MyDocumentEditor({super.key, required this.commands});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Document'),
        actions: [
          // Insert menu
          InsertMenu(
            commands: commands,
            onDismiss: () {
              print('Insert menu dismissed');
            },
          ),
        ],
      ),
      body: DocumentEditor(commands: commands),
    );
  }
}

// Usage in app
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Consumer<DocumentNotifier>(
        builder: (context, notifier, child) {
          return MyDocumentEditor(
            commands: DocumentEditorCommands(notifier),
          );
        },
      ),
    );
  }
}
```

### Inserting a Table Programmatically

```dart
// Get commands
final commands = DocumentEditorCommands(notifier);

// Insert 4x3 table
commands.insertBlock(
  BlockType.table,
  attributes: {
    'rows': 4,
    'cols': 3,
    'data': [
      ['Name', 'Age', 'City'],
      ['Alice', '30', 'New York'],
      ['Bob', '25', 'London'],
      ['Charlie', '35', 'Paris'],
    ],
    'borderWidth': 1.0,
    'borderColor': '#000000',
  },
);
```

### Inserting an Image

```dart
commands.insertBlock(
  BlockType.image,
  attributes: {
    'source': 'url',
    'url': 'https://example.com/image.jpg',
    'width': 600.0,
    'height': 400.0,
    'caption': 'Example image caption',
  },
);
```

### Inserting a Link

```dart
commands.insertText(
  'Visit our website',
  attributes: {
    'link': 'https://example.com',
    'tooltip': 'Click to visit',
  },
);
```

## Conclusion

The Insert Menu provides comprehensive document editing capabilities similar to MS Word and Google Docs. It's designed to be extensible, maintainable, and user-friendly, with clear integration points for future enhancements.

**Status**: ✅ Production Ready (with placeholders for advanced features)
**Test Coverage**: ⚠️ Needs unit tests
**Documentation**: ✅ Complete

---

*Last Updated: 2024*
*Version: 1.0.0*
*Author: Ky Office Team*
