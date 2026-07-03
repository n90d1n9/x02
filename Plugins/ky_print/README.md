# Ky Print

A reusable print service plugin for the Ky Office suite (ky_docs, ky_sheet, ky_slide). Provides cross-platform printing functionality with preview, page layout configuration, and print settings.

## Features

- ✅ **Cross-Platform Printing**: iOS, Android, Web, Windows, macOS, Linux
- ✅ **Print Preview**: Visual preview before printing
- ✅ **Page Layout**: Orientation, paper size, margins, scaling
- ✅ **Print Settings**: Copies, page range, grayscale, duplex
- ✅ **PDF Generation**: Generate PDF from Flutter widgets
- ✅ **Native Integration**: Uses platform-native printing APIs
- ✅ **Progress Tracking**: Real-time progress updates
- ✅ **Error Handling**: Comprehensive error reporting

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  ky_print:
    path: ../Plugins/ky_print  # or use published version
```

Then run:
```bash
flutter pub get
```

## Usage

### Basic Printing

```dart
import 'package:ky_print/ky_print.dart';

// Simple print with default settings
await kyPrint.quickPrint(
  documentTitle: 'My Document',
  pages: [
    Container(
      width: 595,
      height: 842,
      child: Text('Hello, World!'),
    ),
  ],
);
```

### Print with Settings Dialog

```dart
// Show print dialog with full settings
final result = await kyPrint.printDocument(
  context: context,
  documentTitle: 'My Document',
  pages: [
    // Your page widgets here
    PageWidget1(),
    PageWidget2(),
  ],
  orientation: PrintOrientation.portrait,
  paperSize: PaperSize.a4,
);

if (result.isSuccess) {
  print('Printed ${result.pagesPrinted} pages');
}
```

### Print Preview Only

```dart
// Show preview without printing
await kyPrint.preview(
  context: context,
  documentTitle: 'My Document',
  pages: [/* page widgets */],
);
```

### Save as PDF

```dart
// Save document as PDF file
final result = await kyPrint.saveAsPdf(
  documentTitle: 'My Document',
  pages: [/* page widgets */],
  fileName: 'my_document.pdf',
);

if (result.isSuccess) {
  print('Saved to: ${result.pdfPath}');
}
```

### Advanced Usage

```dart
// Create custom print job
final job = PrintJob(
  id: 'unique-id',
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
  pageRange: Range(1, 3), // Print pages 1-3 only
);

// Generate PDF bytes
final pdfBytes = await PrintService.instance.generatePdf(job);

// Print with custom job
final result = await PrintService.instance.print(job, context: context);
```

### Progress Monitoring

```dart
// Listen to print progress
kyPrint.progressStream.listen((progress) {
  print('Print progress: ${(progress * 100).round()}%');
});

// Start printing
await kyPrint.printDocument(/* ... */);
```

### Check Printing Availability

```dart
// Check if printing is available on this platform
final available = await kyPrint.isPrintingAvailable();
if (!available) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Printing not available on this device')),
  );
}
```

## Architecture

```
┌─────────────────────────────────────┐
│         Application Layer           │
│   (ky_docs, ky_sheet, ky_slide)     │
└──────────────┬──────────────────────┘
               │
               ↓
┌─────────────────────────────────────┐
│          KyPrint API                │
│   - printDocument()                 │
│   - quickPrint()                    │
│   - preview()                       │
│   - saveAsPdf()                     │
└──────────────┬──────────────────────┘
               │
               ↓
┌─────────────────────────────────────┐
│        PrintService                 │
│   - generatePdf()                   │
│   - print()                         │
│   - preview()                       │
│   - saveToPdf()                     │
└──────────────┬──────────────────────┘
               │
               ↓
┌─────────────────────────────────────┐
│      Platform Integration           │
│   - printing package                │
│   - pdf package                     │
│   - Native printer APIs             │
└─────────────────────────────────────┘
```

## Models

### PrintJob
Configuration for a print operation:
- `id`: Unique identifier
- `documentTitle`: Document name
- `pages`: List of PrintPage objects
- `orientation`: Portrait/Landscape
- `paperSize`: A4, Letter, Legal, etc.
- `copies`: Number of copies
- `scale`: Content scaling (0.5-1.0)
- `grayscale`: Black & white printing
- `duplex`: Double-sided printing
- `pageRange`: Specific pages to print

### PrintPage
Represents a single page:
- `pageNumber`: Page number
- `content`: Widget to render
- `width`: Page width in points
- `height`: Page height in points
- `margins`: Page margins

### PrintResult
Result of a print operation:
- `status`: Success/Cancelled/Error
- `errorMessage`: Error details (if failed)
- `pdfPath`: Path to generated PDF
- `pagesPrinted`: Number of pages printed

## Integration with ky_docs

```dart
// In your DocumentEditorScreen
import 'package:ky_print/ky_print.dart';

class _DocumentEditorScreenState extends State<DocumentEditorScreen> {
  Future<void> _handlePrint() async {
    final pages = await _buildPrintablePages();
    
    final result = await kyPrint.printDocument(
      context: context,
      documentTitle: widget.document.title,
      pages: pages,
    );
    
    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Document printed successfully')),
      );
    } else if (result.isError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Print failed: ${result.errorMessage}')),
      );
    }
  }
  
  Future<List<Widget>> _buildPrintablePages() async {
    // Convert document content to printable pages
    // This will be implemented based on document structure
    return [];
  }
}
```

## Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| iOS      | ✅     | Requires iOS 10+ |
| Android  | ✅     | Requires Android 5.0+ |
| Web      | ✅     | Browser print dialog |
| Windows  | ✅     | Native Windows printing |
| macOS    | ✅     | Native macOS printing |
| Linux    | ✅     | CUPS printing system |

## Dependencies

- `printing: ^5.12.0` - Cross-platform printing
- `pdf: ^3.10.7` - PDF generation
- `path_provider: ^2.1.1` - File system access
- `path: ^1.8.3` - Path manipulation

## Troubleshooting

### Printing not available
- Ensure you're running on a supported platform
- Check that printers are configured on the device
- On web, ensure browser supports printing

### PDF generation fails
- Verify widget content is renderable
- Check memory constraints for large documents
- Ensure proper widget sizing

### Print quality issues
- Adjust scale factor for better fit
- Configure appropriate DPI settings
- Use vector graphics when possible

## Future Enhancements

- [ ] Advanced PDF rendering from Flutter widgets
- [ ] Watermark support
- [ ] Header/footer customization
- [ ] Booklet printing mode
- [ ] N-up printing (multiple pages per sheet)
- [ ] Print queue management
- [ ] Cloud printer integration

## License

MIT License - See LICENSE file for details

## Contributing

Contributions welcome! Please read CONTRIBUTING.md first.
