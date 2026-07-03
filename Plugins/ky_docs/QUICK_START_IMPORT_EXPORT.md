# Quick Start: Enable Import/Export/Save for Sample Documents

This guide shows how to connect the File menu to actual services so you can import `Sample/sample01.docx` and `Sample/sample02-complete.docx`, edit them, and save/export.

## Problem Statement

Currently the File menu exists but:
- ❌ Clicking "Open" does nothing (no file picker)
- ❌ Clicking "Save" does nothing (no save logic)
- ❌ Clicking "Import → DOCX" does nothing (no service integration)
- ❌ Clicking "Export → DOCX" does nothing (no export logic)

## Solution Overview

We need to:
1. Connect File menu callbacks to Riverpod providers
2. Implement document lifecycle service with save/load logic
3. Add dirty state tracking and auto-save
4. Create Save As dialog
5. Test with sample documents

## Step 1: Update Document Editor App Bar

**File:** `lib/docx/widgets/document_editor_app_bar.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'editor_app_bar/file_menu.dart';
// ... other imports

class DocumentEditorAppBar extends ConsumerWidget {
  const DocumentEditorAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get services from Riverpod
    final lifecycleService = ref.read(documentLifecycleOrchestrationServiceProvider);
    final importService = ref.read(documentImportServiceProvider);
    final exportService = ref.read(documentExportServiceProvider);
    final notifier = ref.read(documentNotifierProvider.notifier);
    
    return AppBar(
      title: const DocumentEditorTitle(),
      leading: DocumentFileMenu(
        onNew: () => _handleNewDocument(context, lifecycleService),
        onOpen: () => _handleOpenDocument(context, importService, lifecycleService),
        onSave: () => _handleSave(context, lifecycleService, notifier),
        onSaveAs: () => _handleSaveAs(context, lifecycleService, notifier),
        onImport: (format) => _handleImport(context, format, importService, lifecycleService),
        onExport: (format) => _handleExport(context, format, exportService, notifier),
        onPrint: () => _handlePrint(context),
        onShare: () => _handleShare(context),
        onClose: () => _handleClose(context, lifecycleService, notifier),
      ),
      // ... rest of app bar
    );
  }

  void _handleNewDocument(BuildContext context, lifecycleService) {
    // TODO: Implement new document creation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('New document - Coming soon')),
    );
  }

  Future<void> _handleOpenDocument(
    BuildContext context,
    importService,
    lifecycleService,
  ) async {
    try {
      // For demo: directly load sample files
      final samplePath = await _pickSampleFile(context);
      if (samplePath == null) return;
      
      final bytes = await File(samplePath).readAsBytes();
      final fileName = samplePath.split('/').last;
      
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      
      // Import the document
      final imported = await importService.importFromBytes(
        bytes: bytes,
        fileName: fileName,
        format: fileName.endsWith('.pdf') ? DocumentImportFormat.pdf : DocumentImportFormat.docx,
      );
      
      Navigator.pop(context); // Close loading dialog
      
      if (imported != null) {
        await lifecycleService.loadDocument(imported);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opened: $fileName')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening file: $e')),
      );
    }
  }

  Future<String?> _pickSampleFile(BuildContext context) async {
    // Show dialog to choose between sample files
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Open Document'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('sample01.docx'),
              subtitle: const Text('Basic document (~143 KB)'),
              onTap: () => Navigator.pop(context, '/workspace/Sample/sample01.docx'),
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('sample02-complete.docx'),
              subtitle: const Text('Complex document (~18 MB)'),
              onTap: () => Navigator.pop(context, '/workspace/Sample/sample02-complete.docx'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSave(BuildContext context, lifecycleService, notifier) async {
    try {
      await lifecycleService.saveCurrentDocument();
      notifier.markClean();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document saved')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving: $e')),
      );
    }
  }

  Future<void> _handleSaveAs(BuildContext context, lifecycleService, notifier) async {
    // Show Save As dialog
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => SaveAsDialog(
        defaultFileName: lifecycleService.currentDocumentTitle ?? 'Untitled',
      ),
    );
    
    if (result != null) {
      try {
        await lifecycleService.saveDocumentAs(
          fileName: result['fileName'] as String,
          format: result['format'] as String,
        );
        notifier.markClean();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved as ${result['fileName']}')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    }
  }

  Future<void> _handleImport(
    BuildContext context,
    String format,
    importService,
    lifecycleService,
  ) async {
    try {
      // For demo: use sample files based on format
      String? samplePath;
      if (format == 'docx') {
        samplePath = await _pickSampleFile(context);
      }
      
      if (samplePath == null) return;
      
      final bytes = await File(samplePath).readAsBytes();
      final fileName = samplePath.split('/').last;
      
      final imported = await importService.importFromBytes(
        bytes: bytes,
        fileName: fileName,
        format: DocumentImportFormat.docx,
      );
      
      if (imported != null) {
        await lifecycleService.loadDocument(imported);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported: $fileName')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error importing: $e')),
      );
    }
  }

  Future<void> _handleExport(
    BuildContext context,
    String format,
    exportService,
    notifier,
  ) async {
    try {
      final state = ref.read(documentNotifierProvider);
      final metadata = state.metadata;
      final text = state.documentText;
      
      String outputPath;
      if (format == 'docx') {
        outputPath = await exportService.exportDocx(
          text: text,
          metadata: metadata,
        );
      } else if (format == 'pdf') {
        outputPath = await exportService.exportPdf(
          text: text,
          metadata: metadata,
        );
      } else {
        outputPath = await exportService.exportTxt(
          text: text,
          metadata: metadata,
        );
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exported to: $outputPath')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting: $e')),
      );
    }
  }

  void _handlePrint(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Print - Coming soon')),
    );
  }

  void _handleShare(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share - Coming soon')),
    );
  }

  Future<void> _handleClose(
    BuildContext context,
    lifecycleService,
    notifier,
  ) async {
    // Check if document has unsaved changes
    if (notifier.isDirty) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unsaved Changes'),
          content: const Text('You have unsaved changes. Do you want to save before closing?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Discard'),
            ),
            TextButton(
              onPressed: () async {
                await lifecycleService.saveCurrentDocument();
                Navigator.pop(context, true);
              },
              child: const Text('Save'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
      
      if (confirmed != true && confirmed != false) return; // Cancelled
      if (confirmed == true) {
        await lifecycleService.saveCurrentDocument();
      }
    }
    
    // Close document
    await lifecycleService.closeDocument();
    Navigator.pop(context); // Return to document list
  }
}
```

## Step 2: Create Save As Dialog

**File:** `lib/docx/widgets/editor_app_bar/save_as_dialog.dart`

```dart
import 'package:flutter/material.dart';

class SaveAsDialog extends StatefulWidget {
  final String defaultFileName;
  final List<String> availableFormats;

  const SaveAsDialog({
    super.key,
    this.defaultFileName = 'Untitled',
    this.availableFormats = const ['docx', 'pdf', 'txt'],
  });

  @override
  State<SaveAsDialog> createState() => _SaveAsDialogState();
}

class _SaveAsDialogState extends State<SaveAsDialog> {
  late TextEditingController _fileNameController;
  String _selectedFormat = 'docx';

  @override
  void initState() {
    super.initState();
    _fileNameController = TextEditingController(text: widget.defaultFileName);
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Save As'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _fileNameController,
            decoration: const InputDecoration(
              labelText: 'File name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.description),
            ),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedFormat,
            decoration: const InputDecoration(
              labelText: 'Format',
              border: OutlineInputBorder(),
            ),
            items: widget.availableFormats.map((format) {
              IconData icon;
              String label;
              switch (format) {
                case 'docx':
                  icon = Icons.description;
                  label = 'Word Document (.docx)';
                  break;
                case 'pdf':
                  icon = Icons.picture_as_pdf;
                  label = 'PDF Document (.pdf)';
                  break;
                case 'txt':
                  icon = Icons.text_fields;
                  label = 'Plain Text (.txt)';
                  break;
                default:
                  icon = Icons.description;
                  label = format;
              }
              return DropdownMenuItem(value: format, child: Row(
                children: [Icon(icon, size: 18), const SizedBox(width: 8), Text(label)],
              ));
            }).toList(),
            onChanged: (value) => setState(() => _selectedFormat = value!),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final fileName = _fileNameController.text.trim();
            if (fileName.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter a file name')),
              );
              return;
            }
            Navigator.pop(context, {
              'fileName': fileName,
              'format': _selectedFormat,
            });
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
```

## Step 3: Add Dirty State Tracking to Document Notifier

**File:** `lib/docx/states/document_notifier.dart`

Add these methods:

```dart
class DocumentNotifier extends StateNotifier<DocumentState> {
  bool _isDirty = false;
  Timer? _autoSaveTimer;

  bool get isDirty => _isDirty;

  void markDirty() {
    if (!_isDirty) {
      _isDirty = true;
      _startAutoSaveTimer();
    }
  }

  void markClean() {
    _isDirty = false;
    _autoSaveTimer?.cancel();
  }

  void _startAutoSaveTimer() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 30), () {
      // Auto-save logic here
      _autoSave();
    });
  }

  Future<void> _autoSave() async {
    if (_isDirty) {
      // Call save service
      // This would need access to lifecycle service
      print('Auto-saving...');
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }
}
```

## Step 4: Test with Sample Documents

### Test Workflow:

1. **Launch the app**
2. **Click File → Open**
   - Select `sample01.docx`
   - Verify document loads with content
3. **Edit the document**
   - Add some text
   - Change formatting
4. **Click File → Save**
   - Verify save succeeds
5. **Click File → Save As**
   - Enter new filename: `sample01_test`
   - Select format: DOCX
   - Click Save
6. **Click File → Export → PDF**
   - Verify PDF export succeeds
7. **Test with large file:**
   - Click File → Open
   - Select `sample02-complete.docx`
   - Monitor performance (should not freeze)
   - Scroll through document
   - Try search function

## Expected Results

✅ File menu opens with all options
✅ Open dialog shows sample files
✅ sample01.docx imports correctly with formatting
✅ Edits can be saved
✅ Save As creates new file with chosen name/format
✅ Export generates DOCX/PDF/TXT files
✅ Unsaved changes warning appears when closing edited document
✅ sample02-complete.docx loads without crashing (may take a few seconds)

## Troubleshooting

### Issue: File menu doesn't appear
**Solution:** Check that `document_editor_app_bar.dart` imports and uses `DocumentFileMenu`

### Issue: Import fails with error
**Solution:** Verify sample file paths are correct and files exist

### Issue: Export creates empty file
**Solution:** Check that document state has content before exporting

### Issue: Large document crashes app
**Solution:** Need to implement virtual scrolling and lazy loading (see IMPROVEMENT_PLAN.md)

## Next Steps After This Fix

Once basic import/export/save works:

1. **Integrate Rust FFI parser** for high-fidelity DOCX handling
2. **Add real file picker** instead of hardcoded sample paths
3. **Implement cloud storage** sync (Google Drive, OneDrive)
4. **Add recent documents list** in File menu
5. **Build Track Changes** and Comments features
6. **Optimize performance** for large documents

---

This quick start gets you from "File menu does nothing" to fully functional import/export/save workflow with the sample documents.
