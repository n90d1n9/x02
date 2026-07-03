# Ky Print Integration Guide

This guide explains how to integrate the `ky_print` plugin into `ky_docs`, `ky_sheet`, and `ky_slide`.

## Overview

The `ky_print` plugin provides a reusable, cross-platform printing service for the entire Ky Office suite. It supports:

- ✅ Print preview with PDF generation
- ✅ Page layout configuration (orientation, paper size, margins)
- ✅ Print settings (copies, page range, grayscale, duplex)
- ✅ Native platform integration (iOS, Android, Web, Desktop)
- ✅ Progress tracking and error handling

## Installation

### 1. Add Dependency

In your package's `pubspec.yaml`:

```yaml
dependencies:
  ky_print:
    path: ../Plugins/ky_print
```

### 2. Run Flutter Pub Get

```bash
cd Plugins/ky_docs
flutter pub get
```

## Integration with ky_docs

### Basic Integration

The print functionality is already integrated into `DocumentEditorAppBar`. When users click **File → Print**, the print dialog will appear.

```dart
// Already implemented in document_editor_app_bar.dart
onPrint: () async {
  final pages = await _buildPrintablePages(documentState);
  
  final result = await kyPrint.printDocument(
    context: context,
    documentTitle: documentState.metadata.title,
    pages: pages,
  );
  
  // Handle result
}
```

### Customizing Print Pages

To properly render document content for printing, implement the `_buildPrintablePages` method:

```dart
Future<List<Widget>> _buildPrintablePages(DocumentState documentState) async {
  final pages = <Widget>[];
  
  // Convert document blocks to printable widgets
  final document = documentState.document;
  
  for (var i = 0; i < document.pages.length; i++) {
    final page = document.pages[i];
    
    pages.add(
      Container(
        width: 595,  // A4 width at 72 DPI
        height: 842, // A4 height at 72 DPI
        padding: const EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            if (page.header != null) page.header!,
            
            // Content
            Expanded(child: page.content),
            
            // Footer
            if (page.footer != null) page.footer!,
            
            // Page number
            Align(
              alignment: Alignment.bottomCenter,
              child: Text('Page ${i + 1}'),
            ),
          ],
        ),
      ),
    );
  }
  
  return pages;
}
```

### Advanced Usage

#### Quick Print (No Dialog)

```dart
import 'package:ky_print/ky_print.dart';

await kyPrint.quickPrint(
  documentTitle: 'My Document',
  pages: [/* page widgets */],
);
```

#### Print Preview Only

```dart
await kyPrint.preview(
  context: context,
  documentTitle: 'My Document',
  pages: [/* page widgets */],
);
```

#### Save as PDF

```dart
final result = await kyPrint.saveAsPdf(
  documentTitle: 'My Document',
  pages: [/* page widgets */],
  fileName: 'document.pdf',
);

if (result.isSuccess) {
  print('Saved to: ${result.pdfPath}');
}
```

#### Custom Print Job

```dart
final job = PrintJob(
  id: DateTime.now().millisecondsSinceEpoch.toString(),
  documentTitle: 'Report',
  pages: [
    PrintPage(
      pageNumber: 1,
      content: MyPageWidget(),
      width: 595,
      height: 842,
      margins: EdgeInsets.all(50),
    ),
  ],
  orientation: PrintOrientation.landscape,
  paperSize: PaperSize.a4,
  copies: 2,
  scale: 0.9,
  grayscale: true,
  duplex: true,
  pageRange: Range(1, 3),
);

final result = await PrintService.instance.print(job, context: context);
```

## Integration with ky_sheet

For spreadsheet printing:

```dart
class SheetPrintService {
  Future<void> printSheet(SheetDocument sheet) async {
    final pages = await _convertSheetToPages(sheet);
    
    await kyPrint.printDocument(
      context: context,
      documentTitle: sheet.name,
      pages: pages,
      orientation: sheet.isWide ? PrintOrientation.landscape : PrintOrientation.portrait,
    );
  }
  
  Future<List<Widget>> _convertSheetToPages(SheetDocument sheet) async {
    // Convert spreadsheet cells to printable pages
    // Handle pagination, grid lines, headers, etc.
    return [];
  }
}
```

## Integration with ky_slide

For presentation printing:

```dart
class SlidePrintService {
  Future<void> printPresentation(Presentation pres) async {
    final pages = pres.slides.map((slide) {
      return PrintPage(
        pageNumber: slide.index + 1,
        content: SlidePrintWidget(slide: slide),
        width: 960,  // 16:9 aspect ratio
        height: 540,
      );
    }).toList();
    
    final job = PrintJob(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      documentTitle: pres.title,
      pages: pages,
      orientation: PrintOrientation.landscape,
      paperSize: PaperSize.a4,
    );
    
    await PrintService.instance.print(job, context: context);
  }
}
```

## Monitoring Print Progress

```dart
// Subscribe to progress updates
kyPrint.progressStream.listen((progress) {
  print('Print progress: ${(progress * 100).round()}%');
});

// Start printing
await kyPrint.printDocument(/* ... */);
```

## Error Handling

```dart
try {
  final result = await kyPrint.printDocument(/* ... */);
  
  if (result.isSuccess) {
    // Success
  } else if (result.isError) {
    // Show error message
    showError(result.errorMessage);
  } else if (result.isCancelled) {
    // User cancelled
  }
} catch (e) {
  // Handle unexpected errors
  showError('Print failed: $e');
}
```

## Platform-Specific Considerations

### iOS
- Requires iOS 10+
- Uses AirPrint for wireless printing
- Ensure `UIBackgroundModes` includes `printing` if needed

### Android
- Requires Android 5.0+
- Uses Android Print Framework
- Add printer service permissions if needed

### Web
- Opens browser print dialog
- May have limited customization options
- Ensure proper CSS print styles

### Desktop (Windows/macOS/Linux)
- Uses native printer dialogs
- Full feature support
- CUPS on Linux

## Testing

### Unit Tests

```dart
test('PrintJob calculates effective page size', () {
  final job = PrintJob(
    id: 'test',
    documentTitle: 'Test',
    pages: [],
    paperSize: PaperSize.a4,
    orientation: PrintOrientation.landscape,
  );
  
  final size = job.getEffectivePageSize();
  expect(size.width, greaterThan(size.height));
});
```

### Integration Tests

```dart
testWidgets('Print preview shows pages', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: PrintPreviewWidget(
        pages: [Container()],
        documentTitle: 'Test',
      ),
    ),
  );
  
  expect(find.text('Test'), findsOneWidget);
});
```

## Troubleshooting

### Issue: Printing not available

**Solution:** Check platform support
```dart
final available = await kyPrint.isPrintingAvailable();
if (!available) {
  showSnackBar('Printing not available on this device');
}
```

### Issue: PDF generation fails

**Solution:** Verify widget content
- Ensure widgets have defined sizes
- Check memory constraints
- Use vector graphics when possible

### Issue: Print quality poor

**Solution:** Adjust settings
- Increase DPI/scale factor
- Use high-resolution images
- Configure proper paper size

## Future Enhancements

- [ ] Advanced PDF rendering from Flutter widgets
- [ ] Watermark support
- [ ] Header/footer customization
- [ ] Booklet printing mode
- [ ] N-up printing
- [ ] Cloud printer integration

## API Reference

See `README.md` for complete API documentation.

## License

MIT License
