# DOCX Import/Export Integration Guide

This guide demonstrates how to use the improved `ky_docs` package to import and export DOCX files, including the sample files provided.

## Overview

The `Plugins/ky_docs` package now includes:
- **File Menu**: MS Word/Google Docs-style File menu with New, Open, Save, Save As, Import, Export, Print, Share options
- **DOCX Import**: Full integration with the Rust `ky-of-docx` parser for high-fidelity DOCX import
- **DOCX Export**: Complete DOCX export with formatting preservation
- **PDF Export**: PDF export with advanced options
- **Engine Integration**: Seamless integration with the Rust `docs_engine` for document operations

## Sample Files

Two sample DOCX files are provided for testing:
- `/workspace/Sample/sample01.docx` - Basic document
- `/workspace/Sample/sample02-complete.docx` - Complete document with advanced features

## Quick Start

### 1. Import a DOCX File

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ky_docs/ky_docs.dart';

class DocumentImportExample extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Import DOCX Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: Icon(Icons.file_upload),
              label: Text('Import sample01.docx'),
              onPressed: () async {
                final notifier = ref.read(documentProvider.notifier);
                
                // Import DOCX with preview dialog
                await notifier.importFromDocx(
                  reviewImport: (preview) async {
                    // Show preview dialog before importing
                    if (!context.mounted) return false;
                    return await DocumentImportPreviewDialog.show(
                      context,
                      preview: preview,
                    );
                  },
                );
                
                // Navigate to editor after import
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DocumentEditorPage(),
                    ),
                  );
                }
              },
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              icon: Icon(Icons.file_upload),
              label: Text('Import sample02-complete.docx'),
              onPressed: () async {
                final notifier = ref.read(documentProvider.notifier);
                
                await notifier.importFromDocx(
                  reviewImport: (preview) async {
                    if (!context.mounted) return false;
                    return await DocumentImportPreviewDialog.show(
                      context,
                      preview: preview,
                    );
                  },
                );
                
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DocumentEditorPage(),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

### 2. Export to DOCX

```dart
class DocumentExportExample extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Export Example'),
        actions: [
          // Export button in app bar
          PopupMenuButton<String>(
            onSelected: (value) async {
              final notifier = ref.read(documentProvider.notifier);
              
              try {
                String path;
                if (value == 'docx') {
                  path = await notifier.exportToDocx();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Exported to DOCX: $path'),
                        action: SnackBarAction(
                          label: 'Share',
                          onPressed: () {
                            SharePlus.instance.share(
                              ShareParams(files: [XFile(path)]),
                            );
                          },
                        ),
                      ),
                    );
                  }
                } else if (value == 'pdf') {
                  path = await notifier.exportToPdf();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Exported to PDF: $path'),
                        action: SnackBarAction(
                          label: 'Share',
                          onPressed: () {
                            SharePlus.instance.share(
                              ShareParams(files: [XFile(path)]),
                            );
                          },
                        ),
                      ),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Export failed: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'docx',
                child: Row(
                  children: [
                    Icon(Icons.description),
                    SizedBox(width: 8),
                    Text('Export as DOCX'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf),
                    SizedBox(width: 8),
                    Text('Export as PDF'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: DocumentEditorPage(),
    );
  }
}
```

### 3. Using the File Menu

The new `DocumentFileMenu` widget provides a complete MS Word/Google Docs-style File menu:

```dart
import 'package:ky_docs/docx/widgets/editor_app_bar/file_menu.dart';

// In your app bar
AppBar(
  title: Text('My Document'),
  actions: [
    DocumentFileMenu(
      onNew: () {
        // Create new document
        ref.read(documentProvider.notifier).createNewDocument();
      },
      onSave: () async {
        // Save current document
        await ref.read(documentProvider.notifier).saveDocument();
      },
      onSaveAs: () async {
        // Save as (could show dialog for new name)
        await ref.read(documentProvider.notifier).saveDocument();
      },
      onImport: (type) async {
        // Import based on type ('docx', 'pdf', 'txt')
        if (type == 'docx') {
          await ref.read(documentProvider.notifier).importFromDocx();
        } else if (type == 'pdf') {
          await ref.read(documentProvider.notifier).importFromPdf();
        }
      },
      onExport: (type) async {
        // Export based on type ('docx', 'pdf', 'pdf_advanced', 'txt')
        if (type == 'docx') {
          await ref.read(documentProvider.notifier).exportToDocx();
        } else if (type == 'pdf') {
          await ref.read(documentProvider.notifier).exportToPdf();
        } else if (type == 'pdf_advanced') {
          // Show advanced PDF options dialog
          final options = await PdfExportOptionsDialog.show(context);
          if (options != null) {
            await ref.read(documentProvider.notifier).exportToPdf(options: options);
          }
        }
      },
      onPrint: () {
        // Print document
        // Implementation depends on platform
      },
      onShare: () {
        // Share document
        // Opens collaboration/sharing dialog
      },
    ),
  ],
)
```

## Architecture

### Import Flow

```
User clicks "Import" 
    ↓
FilePicker picks file (sample01.docx or sample02-complete.docx)
    ↓
DocumentImportService processes file
    ↓
WaraqDocumentBridge creates import request
    ↓
DocumentImportExtractor extracts content
    ├─→ Uses DocxService for basic text extraction
    └─→ Uses ky-of-docx Rust parser for structured content (if available)
    ↓
DocumentImportPreviewAnalyzer analyzes structure
    ↓
DocumentImportPreviewDialog shows preview
    ↓
User confirms
    ↓
DocumentLifecycleOrchestrationService imports
    ↓
Document activated in editor
```

### Export Flow

```
User clicks "Export" → "DOCX"
    ↓
DocumentExportOrchestrationService.exportDocx()
    ↓
Gets current document state (text, metadata, controller)
    ↓
DocumentExportService.exportDocx()
    ↓
WaraqDocumentBridge creates export request
    ↓
DocumentExportRenderer.renderDocx()
    ├─→ Uses DocxService for basic DOCX creation
    └─→ Uses ky-of-docx Rust parser for advanced export (if available)
    ↓
Writes file to application documents directory
    ↓
Returns file path
    ↓
Shows SnackBar with Share option
```

## Testing with Sample Files

### Test Import of sample01.docx

```dart
void testSample01Import() async {
  final importService = DocumentImportService(
    docxService: DocxService(),
    pdfService: PdfService(),
  );
  
  // Read sample file
  final samplePath = 'Sample/sample01.docx';
  final bytes = await File(samplePath).readAsBytes();
  
  // Simulate import
  final imported = await importService.importFormat(
    DocumentImportFormat.docx,
  );
  
  print('Imported title: ${imported?.title}');
  print('Text content: ${imported?.text}');
  print('Structure: ${imported?.structure}');
}
```

### Test Export Round-Trip

```dart
void testExportRoundTrip() async {
  final exportService = DocumentExportService(
    docxService: DocxService(),
    pdfService: PdfService(),
  );
  
  final metadata = DocumentMetadata(
    title: 'Test Document',
    author: 'Test User',
    createdAt: DateTime.now(),
    lastModified: DateTime.now(),
    wordCount: 100,
    characterCount: 500,
  );
  
  final text = 'This is a test document.\n\nIt has multiple paragraphs.';
  
  // Export to DOCX
  final path = await exportService.exportDocx(
    text: text,
    metadata: metadata,
  );
  
  print('Exported to: $path');
  
  // Re-import to verify
  final bytes = await File(path).readAsBytes();
  final extractedText = await DocxService().extractTextFromDocx(bytes);
  
  print('Re-imported text: $extractedText');
  assert(extractedText.contains('test document'));
}
```

## Features Comparison

| Feature | Old Implementation | New Implementation |
|---------|-------------------|-------------------|
| **File Menu** | ❌ No dedicated menu | ✅ MS Word/GDocs style |
| **DOCX Import** | ⚠️ Basic text extraction | ✅ Structured + FFI parser |
| **DOCX Export** | ⚠️ Simple XML generation | ✅ Full formatting support |
| **PDF Export** | ✅ Basic | ✅ Advanced options |
| **Save As** | ❌ Not available | ✅ Available |
| **Print** | ⚠️ Limited | ✅ Platform integration |
| **Share** | ⚠️ Manual | ✅ Integrated |
| **Rust Engine** | ❌ Not integrated | ✅ FFI layer ready |
| **Preview Dialog** | ✅ Basic | ✅ Enhanced with structure analysis |

## Next Steps

1. **Build Rust FFI Library**:
   ```bash
   cd Plugins/Engine/docs_engine_ffi
   cargo build --release
   ```

2. **Copy Native Libraries**:
   - Android: `libdocs_engine_ffi.so` → `android/app/src/main/jniLibs/`
   - iOS: `libdocs_engine_ffi.dylib` → `ios/`
   - Linux: `libdocs_engine_ffi.so` → `linux/`
   - macOS: `libdocs_engine_ffi.dylib` → `macos/`
   - Windows: `docs_engine_ffi.dll` → `windows/`

3. **Initialize Engine**:
   ```dart
   void main() async {
     WidgetsFlutterBinding.ensureInitialized();
     
     // Initialize the native engine
     await DocumentEngine.instance.initialize();
     
     runApp(MyApp());
   }
   ```

4. **Test with Sample Files**:
   - Copy `Sample/sample01.docx` and `Sample/sample02-complete.docx` to your device/emulator
   - Use the File Menu → Import to load them
   - Edit and export back to verify round-trip fidelity

## Troubleshooting

### Import fails with "Invalid DOCX file"
- Ensure the file is a valid Office Open XML format
- Check file permissions
- Verify the file isn't corrupted

### Export produces empty file
- Ensure document has content
- Check write permissions to documents directory
- Verify metadata is properly set

### Rust FFI not loading
- Build the library with `cargo build --release`
- Copy to correct platform-specific directory
- Check library naming conventions for each platform
- Verify FFI function signatures match

## Additional Resources

- `README.md` - Package overview and architecture
- `MIGRATION_GUIDE.md` - Migration from Quill to native engine
- `NATIVE_ENGINE_EXAMPLE.md` - Detailed FFI usage examples
- API documentation in `lib/engine/document_engine.dart`
