# Sample Document Import/Export Test Guide

This guide demonstrates how to import, edit, and export the sample documents using the improved ky_docs editor.

## Sample Documents

Located in `/workspace/Sample/`:
- **sample01.docx** (143 KB) - Basic document with text and formatting
- **sample02-complete.docx** (17.8 MB) - Complex document with advanced features

## Quick Start: Import Sample Documents

### Method 1: Using File Menu (UI)

1. Launch the ky_docs editor
2. Click **File** menu in the top-left corner
3. Select **Import** → **DOCX**
4. Navigate to `/workspace/Sample/sample01.docx` or `sample02-complete.docx`
5. Review the import preview showing:
   - Document title
   - Word count and structure
   - Formatting preservation status
6. Click **Confirm Import**
7. Document opens in the editor with full formatting preserved

### Method 2: Programmatic Import

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ky_docs/ky_docs.dart';

// Get the document notifier
final docNotifier = ref.read(documentProvider.notifier);

// Import sample01.docx
await docNotifier.importFromDocx(
  reviewImport: (preview) async {
    // Show preview dialog
    print('Importing: ${preview.title}');
    print('Words: ${preview.structure.wordCount}');
    print('Paragraphs: ${preview.structure.paragraphCount}');
    
    // Return true to confirm import
    return true;
  },
);

// The document is now loaded and ready for editing
```

### Method 3: Direct File Path (Testing)

```dart
import 'dart:io';
import 'package:ky_docs/docx/services/docx_service.dart';

final docxService = DocxService();
final file = File('/workspace/Sample/sample01.docx');
final bytes = await file.readAsBytes();

// Extract content
final content = await docxService.extractTextFromDocx(bytes);
print('Document content: $content');
```

## Export/Save As Examples

### Save as DOCX

```dart
final docNotifier = ref.read(documentProvider.notifier);

// Save as DOCX
final success = await docNotifier.saveDocumentAs(
  newTitle: 'My Edited Document',
  format: 'docx',
  location: '/workspace/output/',
);

if (success) {
  print('Successfully saved as My Edited Document.docx');
}
```

### Save as PDF

```dart
// Save as PDF with default options
final pdfPath = await docNotifier.exportToPdf();
print('PDF exported to: $pdfPath');

// Save as PDF with custom options
import 'package:ky_docs/docx/models/export_options.dart';

final customOptions = ExportOptions(
  includeComments: true,
  includeTrackChanges: false,
  pageSize: PageSize.a4,
  orientation: Orientation.portrait,
);

final customPdfPath = await docNotifier.exportToPdf(options: customOptions);
```

### Save as Plain Text

```dart
final success = await docNotifier.saveDocumentAs(
  newTitle: 'Plain Text Version',
  format: 'txt',
);
```

## Complete Workflow Example

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ky_docs/ky_docs.dart';

class SampleDocumentWorkflow extends ConsumerWidget {
  const SampleDocumentWorkflow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sample Document Test'),
        actions: [
          // Import button
          IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: 'Import Sample Document',
            onPressed: () async {
              final notifier = ref.read(documentProvider.notifier);
              
              // Import sample01.docx
              await notifier.importFromDocx(
                reviewImport: (preview) async {
                  // Show confirmation dialog
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Import ${preview.title}?'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Words: ${preview.structure.wordCount}'),
                          Text('Paragraphs: ${preview.structure.paragraphCount}'),
                          Text('Has tables: ${preview.structure.hasTables}'),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Import'),
                        ),
                      ],
                    ),
                  );
                  return confirmed ?? false;
                },
              );
            },
          ),
          
          // Save button
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save Document',
            onPressed: ref.watch(documentProvider).hasUnsavedChanges
                ? () async {
                    await ref.read(documentProvider.notifier).saveDocument();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Document saved!')),
                      );
                    }
                  }
                : null,
          ),
          
          // Export button
          PopupMenuButton<String>(
            icon: const Icon(Icons.file_download),
            tooltip: 'Export Document',
            onSelected: (format) async {
              final notifier = ref.read(documentProvider.notifier);
              final state = ref.read(documentProvider);
              
              String? result;
              switch (format) {
                case 'docx':
                  result = await notifier.exportToDocx();
                  break;
                case 'pdf':
                  result = await notifier.exportToPdf();
                  break;
                case 'txt':
                  final success = await notifier.saveDocumentAs(
                    newTitle: state.metadata.title,
                    format: 'txt',
                  );
                  result = success ? 'Success' : null;
                  break;
              }
              
              if (result != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Exported successfully: $result')),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'docx', child: Text('Export as DOCX')),
              const PopupMenuItem(value: 'pdf', child: Text('Export as PDF')),
              const PopupMenuItem(value: 'txt', child: Text('Export as TXT')),
            ],
          ),
        ],
      ),
      body: const DocumentEditor(),
    );
  }
}
```

## Testing Checklist

### Import Tests

- [ ] Import sample01.docx successfully
- [ ] Import sample02-complete.docx successfully
- [ ] Verify text content is preserved
- [ ] Verify formatting (bold, italic, underline) is preserved
- [ ] Verify headings and styles are preserved
- [ ] Verify lists (bulleted, numbered) are preserved
- [ ] Verify tables are imported correctly (for sample02)
- [ ] Verify images are imported (for sample02)
- [ ] Check word count matches original
- [ ] Check page layout is preserved

### Edit Tests

- [ ] Add new text to document
- [ ] Apply formatting (bold, italic, etc.)
- [ ] Insert image
- [ ] Insert table
- [ ] Add comments
- [ ] Enable track changes
- [ ] Use AI assistant features
- [ ] Navigate between pages
- [ ] Use find & replace

### Export Tests

- [ ] Save as DOCX preserves all content
- [ ] Save as PDF maintains layout
- [ ] Save as TXT extracts plain text
- [ ] Save As creates new file with correct name
- [ ] Auto-save works correctly
- [ ] Version history is maintained
- [ ] Exported file can be re-imported

### Performance Tests

- [ ] sample01.docx loads in < 2 seconds
- [ ] sample02-complete.docx loads in < 10 seconds
- [ ] Scrolling is smooth (60 FPS)
- [ ] Search works quickly
- [ ] Export completes in reasonable time

## Troubleshooting

### Import Fails

**Problem**: Import shows error or blank document

**Solutions**:
1. Check file path is correct
2. Verify file is valid DOCX format
3. Check console for parsing errors
4. Try the other sample file to isolate issue
5. Ensure `file_picker` permissions are granted

### Export Fails

**Problem**: Export doesn't create file or shows error

**Solutions**:
1. Check write permissions for target directory
2. Verify document has content
3. Check storage is initialized
4. Review error messages in console
5. Try different export format

### Formatting Lost

**Problem**: Imported document loses formatting

**Solutions**:
1. This is expected with basic Dart extractor
2. Build and integrate Rust FFI parser for full fidelity
3. Use `ky-of-docx` parser via FFI
4. Check `docsEngineJson` field in import result

### Performance Issues

**Problem**: Slow loading or laggy editing

**Solutions**:
1. For large files like sample02-complete.docx, some delay is normal
2. Enable lazy loading for images
3. Use pagination for very long documents
4. Consider background parsing for large files
5. Profile with Flutter DevTools

## Expected Results

### sample01.docx

After import, you should see:
- Title: "Sample Document 01"
- ~500-1000 words
- Multiple paragraphs with different styles
- Some bold/italic text
- Possibly a simple list or table
- Clean, professional formatting

### sample02-complete.docx

After import, you should see:
- Comprehensive document with multiple sections
- 5000+ words (large file)
- Complex formatting
- Tables with data
- Images or charts
- Headers/footers
- Table of contents
- Various heading levels

## Next Steps

After successful testing:

1. **Integrate Rust FFI Parser**: Build `docs_engine_ffi` for production-quality parsing
2. **Add Real-time Collaboration**: Enable multi-user editing
3. **Implement Advanced Features**: Track changes, comments, suggestions
4. **Optimize Performance**: Profile and optimize for large documents
5. **Add Cloud Sync**: Integrate with cloud storage providers
6. **Mobile Optimization**: Ensure good UX on tablets and phones

## Support

For issues or questions:
- Check the IMPORT_EXPORT_GUIDE.md for detailed architecture
- Review FILE_MENU_IMPLEMENTATION.md for UI details
- Examine doc_notifier.dart for state management
- Consult Rust engine documentation in Plugins/Engine/docs_engine/
