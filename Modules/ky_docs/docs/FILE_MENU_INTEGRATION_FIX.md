# File Menu Integration Fix - Import/Export/Save Implementation Guide

## Problem Statement

The `Plugins/ky_docs` package has **two separate app bar implementations**:

1. **`lib/docx/widgets/document_editor_app_bar.dart`** - Complete implementation with File menu, but NOT used in the editor screen
2. **`lib/docx/screens/document_editor_screen.dart`** - Uses a simpler `_DocumentAppBar` WITHOUT File menu

**Result**: Users cannot import/export/save documents through the UI despite having all the backend services ready.

## Sample Documents Ready for Testing

- `/workspace/Sample/sample01.docx` (143 KB) - Basic document
- `/workspace/Sample/sample02-complete.docx` (18 MB) - Complex document with full features

## Solution Overview

### Option A: Replace _DocumentAppBar with DocumentEditorAppBar (Recommended)

Replace the simple app bar in `document_editor_screen.dart` with the full-featured `DocumentEditorAppBar`.

### Option B: Add File Menu to Existing _DocumentAppBar

Add the File menu widget to the existing app bar implementation.

## Implementation Steps

### Step 1: Update document_editor_screen.dart

Replace the `_DocumentAppBar` usage with `DocumentEditorAppBar`:

```dart
// In lib/docx/screens/document_editor_screen.dart

// REMOVE this old implementation:
// appBar: layoutMode != LayoutMode.focus ? const _DocumentAppBar() : null,

// ADD this new implementation:
appBar: layoutMode != LayoutMode.focus
    ? DocumentEditorAppBar(
        documentState: ref.watch(documentProvider),
        showStatistics: ref.watch(showStatisticsProvider),
        showFindReplace: ref.watch(showFindReplaceProvider),
        showAIAssistant: ref.watch(showAIAssistantProvider),
        showInsertMenu: ref.watch(showInsertMenuProvider),
        showOutline: ref.watch(showOutlineProvider),
        showPageNavigator: ref.watch(showPageNavigatorProvider),
        activeSidePanel: ref.watch(activeSidePanelProvider),
        editingMode: ref.watch(editingModeProvider),
        onEditTitle: () {
          // Edit title logic
        },
        onToggleFavorite: () {
          ref.read(documentProvider.notifier).toggleFavorite();
        },
        onToggleStatistics: () {
          ref.read(showStatisticsProvider.notifier).state =
            !ref.read(showStatisticsProvider);
        },
        onToggleFindReplace: () {
          ref.read(showFindReplaceProvider.notifier).state =
            !ref.read(showFindReplaceProvider);
        },
        onToggleAIAssistant: () {
          ref.read(showAIAssistantProvider.notifier).state =
            !ref.read(showAIAssistantProvider);
        },
        onToggleInsertMenu: () {
          ref.read(showInsertMenuProvider.notifier).state =
            !ref.read(showInsertMenuProvider);
        },
        onToggleOutline: () {
          ref.read(showOutlineProvider.notifier).state =
            !ref.read(showOutlineProvider);
        },
        onTogglePageNavigator: () {
          ref.read(showPageNavigatorProvider.notifier).state =
            !ref.read(showPageNavigatorProvider);
        },
        onToggleSidePanel: (panel) {
          ref.read(activeSidePanelProvider.notifier).state =
            ref.read(activeSidePanelProvider) == panel ? null : panel;
        },
        onEditingModeChanged: (mode) {
          ref.read(editingModeProvider.notifier).state = mode;
        },
        onToggleSpellCheck: () {
          ref.read(documentProvider.notifier).toggleSpellCheck();
        },
        onSave: () async {
          await ref.read(documentProvider.notifier).saveDocument();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Document saved')),
            );
          }
        },
        onImport: (format) async {
          await _handleImport(context, ref, format);
        },
        onExport: (format) async {
          await _handleExport(context, ref, format);
        },
        onSetPageLayout: (layout) {
          ref.read(layoutProvider.notifier).state = layout;
        },
        onOpenCommandPalette: () {
          ref.read(commandPaletteProvider.notifier).state = true;
        },
        onOpenCollaboration: () {
          _showSharingPanel(context);
        },
        onMoreOptions: () {
          _showMoreOptions(context);
        },
      )
    : null,
```

### Step 2: Add Import/Export Handler Methods

Add these methods to `_DocumentEditorScreenState`:

```dart
Future<void> _handleImport(
  BuildContext context,
  WidgetRef ref,
  String format
) async {
  try {
    // Show file picker
    final result = await FilePicker.platform.pickFiles(
      type: format == 'docx'
          ? FileType.custom
          : format == 'pdf'
              ? FileType.custom
              : FileType.any,
      allowedExtensions: format == 'docx'
          ? ['docx']
          : format == 'pdf'
              ? ['pdf']
              : null,
    );

    if (result != null && result.files.single.path != null) {
      final filePath = result.files.single.path!;

      // Show preview dialog
      final shouldImport = await showDialog<bool>(
        context: context,
        builder: (_) => DocumentImportPreviewDialog(filePath: filePath),
      );

      if (shouldImport == true) {
        // Import the document
        await ref.read(documentProvider.notifier).importFromDocx();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Imported $filePath')),
          );
        }
      }
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $e')),
      );
    }
  }
}

Future<void> _handleExport(
  BuildContext context,
  WidgetRef ref,
  String format
) async {
  try {
    // Get save path
    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Export document',
      fileName: '${ref.read(documentProvider).metadata.title}.$format',
      type: format == 'docx'
          ? FileType.custom
          : format == 'pdf'
              ? FileType.custom
              : FileType.any,
      allowedExtensions: ['docx', 'pdf', 'txt'],
    );

    if (savePath != null) {
      // Export the document
      final exportedPath = await ref.read(documentProvider.notifier).exportDocument(
        format: format,
        outputPath: savePath,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported to $exportedPath')),
        );
      }
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }
}
```

### Step 3: Verify Required Providers Exist

Ensure these providers are available in your state management:

```dart
// Check lib/docx/states/provider.dart or similar
final showStatisticsProvider = StateProvider<bool>((ref) => false);
final showFindReplaceProvider = StateProvider<bool>((ref) => false);
final showAIAssistantProvider = StateProvider<bool>((ref) => false);
final showInsertMenuProvider = StateProvider<bool>((ref) => false);
final showOutlineProvider = StateProvider<bool>((ref) => false);
final showPageNavigatorProvider = StateProvider<bool>((ref) => false);
final activeSidePanelProvider = StateProvider<DocumentSidePanel?>((ref) => null);
final editingModeProvider = StateProvider<DocumentEditingMode>((ref) => DocumentEditingMode.edit);
```

### Step 4: Test with Sample Documents

Create a test script to verify import/export:

```dart
// test_import_export.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/ky_docs.dart';

void main() {
  test('Import sample01.docx', () async {
    final docxService = DocxService();
    final result = await docxService.importDocx('/workspace/Sample/sample01.docx');
    expect(result.isSuccess, true);
    expect(result.document, isNotNull);
  });

  test('Import sample02-complete.docx', () async {
    final docxService = DocxService();
    final result = await docxService.importDocx('/workspace/Sample/sample02-complete.docx');
    expect(result.isSuccess, true);
    expect(result.document, isNotNull);
    // Verify complex features
    expect(result.document.tables.length, greaterThan(0));
  });

  test('Export to DOCX', () async {
    final exportService = DocumentExportService(
      docxService: DocxService(),
      pdfService: PdfService(),
    );
    final document = createTestDocument();
    final result = await exportService.exportToDocx(
      document: document,
      outputPath: '/tmp/test_export.docx',
    );
    expect(result.isSuccess, true);
    expect(File(result.path!).existsSync(), true);
  });
}
```

## Architecture Flow

### Import Flow
```
File Menu → Import → DOCX
    ↓
FilePicker (select file)
    ↓
DocumentImportPreviewDialog (show preview)
    ↓
DocumentNotifier.importFromDocx()
    ↓
DocumentLifecycleOrchestrationService
    ↓
DocumentImportService
    ↓
DocxService (or ky-of-docx Rust FFI)
    ↓
Update DocumentState
    ↓
UI Refresh
```

### Export Flow
```
File Menu → Export → DOCX/PDF/TXT
    ↓
FilePicker (save dialog)
    ↓
DocumentNotifier.exportDocument()
    ↓
DocumentExportOrchestrationService
    ↓
DocumentExportService
    ↓
DocxService / PdfService (or Rust FFI)
    ↓
Write to disk
    ↓
Show success message
```

### Save Flow
```
File Menu → Save (Ctrl+S)
    ↓
Check if document has path
    ├─ Yes → DocumentPersistenceService.save()
    └─ No → Show Save As dialog
    ↓
Update metadata
    ↓
Clear dirty flag
    ↓
Show save indicator
```

## Missing Features Checklist

After implementing the above, verify these features:

### P0 - Critical (Must Have)
- [ ] File menu visible and clickable
- [ ] Import DOCX opens file picker
- [ ] Export DOCX saves to disk
- [ ] Save updates document
- [ ] Save As creates new file with new name
- [ ] Dirty state tracking (unsaved changes badge)
- [ ] Auto-save after N seconds/minutes

### P1 - High Priority
- [ ] Import preview dialog shows document structure
- [ ] Export progress indicator for large documents
- [ ] Unsaved changes warning on close
- [ ] Recent documents list
- [ ] Document properties editor

### P2 - Medium Priority
- [ ] Print functionality
- [ ] Share/collaboration invite
- [ ] Keyboard shortcuts (Ctrl+O, Ctrl+S, Ctrl+Shift+S)
- [ ] Drag & drop file import
- [ ] Cloud sync status indicator

### P3 - Nice to Have
- [ ] Templates gallery
- [ ] Advanced search in document
- [ ] Comments panel
- [ ] Real-time collaboration cursors
- [ ] AI writing assistant
- [ ] Spell check with suggestions

## Troubleshooting

### Issue: File menu not appearing
**Solution**: Check that `DocumentEditorAppBar` is imported and used instead of `_DocumentAppBar`

### Issue: Import fails silently
**Solution**: Add error logging in `_handleImport` method and check permissions

### Issue: Export creates empty file
**Solution**: Verify `DocumentExportService` is properly initialized with DocxService

### Issue: Save doesn't update file
**Solution**: Check that `DocumentPersistenceService` has write permissions to the target directory

### Issue: Rust FFI parser not working
**Solution**:
1. Build the Rust library: `cd Plugins/Engine/docs_engine_ffi && cargo build --release`
2. Copy the `.so`/`.dylib`/`.dll` to the Flutter project
3. Initialize FFI in app startup: `DocumentEngine.instance.initialize()`

## Next Steps

1. **Immediate**: Implement Option A (replace app bar) in `document_editor_screen.dart`
2. **Short-term**: Add auto-save and dirty state tracking
3. **Medium-term**: Integrate Rust FFI parser for better DOCX fidelity
4. **Long-term**: Add real-time collaboration and AI features

## Files Modified/Created

- ✅ `lib/docx/widgets/editor_app_bar/file_menu.dart` - Already exists
- ✅ `lib/docx/widgets/editor_app_bar/save_as_dialog.dart` - Already exists
- ✅ `lib/docx/widgets/document_editor_app_bar.dart` - Already exists
- ⚠️ `lib/docx/screens/document_editor_screen.dart` - NEEDS UPDATE
- ⚠️ `lib/docx/states/doc_notifier.dart` - May need import/export methods exposed
- 📝 This guide - Created for implementation reference

## Conclusion

The infrastructure for import/export/save is **90% complete**. The missing piece is wiring the UI (File menu) to the backend services. Follow the steps above to complete the integration and enable full document lifecycle management similar to MS Word/Google Docs.