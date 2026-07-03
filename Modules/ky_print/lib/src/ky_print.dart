import 'package:flutter/material.dart';
import 'print_service.dart';
import 'print_settings.dart';
import 'models/print_job.dart';
import 'models/print_page.dart';

/// Main entry point for Ky Print functionality
/// 
/// Provides a simple API for printing documents from ky_docs, ky_sheet, and ky_slide.
class KyPrint {
  /// The print service instance
  final PrintService _printService = PrintService.instance;

  /// Show print dialog with settings and preview
  Future<PrintResult> printDocument({
    required BuildContext context,
    required String documentTitle,
    required List<Widget> pages,
    PrintOrientation orientation = PrintOrientation.portrait,
    PaperSize paperSize = PaperSize.a4,
    int copies = 1,
    double scale = 1.0,
    bool grayscale = false,
    bool duplex = false,
  }) async {
    // Create print pages
    final printPages = pages.asMap().entries.map((entry) {
      return PrintPage(
        pageNumber: entry.key + 1,
        content: entry.value,
      );
    }).toList();

    // Create print job
    final job = PrintJob(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      documentTitle: documentTitle,
      pages: printPages,
      orientation: orientation,
      paperSize: paperSize,
      copies: copies,
      scale: scale,
      grayscale: grayscale,
      duplex: duplex,
    );

    // Show settings dialog
    final settings = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => PrintSettingsDialog(
        documentTitle: documentTitle,
        totalPages: pages.length,
        initialOrientation: orientation,
        initialPaperSize: paperSize,
        initialCopies: copies,
        initialScale: scale,
        initialGrayscale: grayscale,
        initialDuplex: duplex,
      ),
    );

    if (settings == null) {
      return PrintResult.cancelled();
    }

    // Update job with user settings
    final updatedJob = job.copyWith(
      orientation: settings['orientation'] as PrintOrientation,
      paperSize: settings['paperSize'] as PaperSize,
      copies: settings['copies'] as int,
      scale: settings['scale'] as double,
      grayscale: settings['grayscale'] as bool,
      duplex: settings['duplex'] as bool,
      pageRange: settings['pageRange'] as Range?,
    );

    // Print the document
    return await _printService.print(updatedJob, context: context);
  }

  /// Quick print without settings dialog
  Future<PrintResult> quickPrint({
    required String documentTitle,
    required List<Widget> pages,
  }) async {
    final printPages = pages.asMap().entries.map((entry) {
      return PrintPage(
        pageNumber: entry.key + 1,
        content: entry.value,
      );
    }).toList();

    final job = PrintJob(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      documentTitle: documentTitle,
      pages: printPages,
    );

    return await _printService.printDirect(job);
  }

  /// Show print preview only
  Future<PrintResult> preview({
    required BuildContext context,
    required String documentTitle,
    required List<Widget> pages,
  }) async {
    final printPages = pages.asMap().entries.map((entry) {
      return PrintPage(
        pageNumber: entry.key + 1,
        content: entry.value,
      );
    }).toList();

    final job = PrintJob(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      documentTitle: documentTitle,
      pages: printPages,
    );

    return await _printService.preview(job, context: context);
  }

  /// Save document as PDF file
  Future<PrintResult> saveAsPdf({
    required String documentTitle,
    required List<Widget> pages,
    String? fileName,
  }) async {
    final printPages = pages.asMap().entries.map((entry) {
      return PrintPage(
        pageNumber: entry.key + 1,
        content: entry.value,
      );
    }).toList();

    final job = PrintJob(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      documentTitle: documentTitle,
      pages: printPages,
    );

    return await _printService.saveToPdf(job, fileName: fileName);
  }

  /// Check if printing is available on this platform
  Future<bool> isPrintingAvailable() async {
    return await Printing.isAvailable();
  }

  /// Get list of available printers
  Future<List<String>> getAvailablePrinters() async {
    final printer = await Printing.selectPrinter();
    return printer != null ? [printer.name] : [];
  }

  /// Cancel current print operation
  void cancelPrint() {
    _printService.cancel();
  }

  /// Whether a print operation is in progress
  bool get isPrinting => _printService.isPrinting;

  /// Stream of print progress updates
  Stream<double> get progressStream => _printService.progressStream;

  /// Dispose resources
  void dispose() {
    _printService.dispose();
  }
}

/// Global instance for convenience
final kyPrint = KyPrint();
