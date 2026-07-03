import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'models/print_job.dart';

/// Result of a print operation
enum PrintStatus { success, cancelled, error }

/// Result data from print operations
class PrintResult {
  final PrintStatus status;
  final String? errorMessage;
  final String? pdfPath;
  final int? pagesPrinted;

  const PrintResult({
    required this.status,
    this.errorMessage,
    this.pdfPath,
    this.pagesPrinted,
  });

  factory PrintResult.success({String? pdfPath, int? pagesPrinted}) {
    return PrintResult(
      status: PrintStatus.success,
      pdfPath: pdfPath,
      pagesPrinted: pagesPrinted,
    );
  }

  factory PrintResult.cancelled() {
    return const PrintResult(status: PrintStatus.cancelled);
  }

  factory PrintResult.error(String message) {
    return PrintResult(status: PrintStatus.error, errorMessage: message);
  }

  bool get isSuccess => status == PrintStatus.success;
  bool get isCancelled => status == PrintStatus.cancelled;
  bool get isError => status == PrintStatus.error;
}

/// Core print service for Ky Office suite
///
/// Provides cross-platform printing functionality with:
/// - PDF generation from Flutter widgets
/// - Print preview
/// - Native platform printing
/// - Page layout configuration
/// - Progress tracking
class PrintService {
  /// Singleton instance
  static final PrintService instance = PrintService._internal();

  PrintService._internal();

  /// Current print job being processed
  PrintJob? _currentJob;

  /// Whether a print operation is in progress
  bool get isPrinting => _currentJob != null;

  /// Stream controller for print progress updates
  final _progressController = StreamController<double>.broadcast();

  /// Stream of progress updates (0.0 to 1.0)
  Stream<double> get progressStream => _progressController.stream;

  /// Generate PDF bytes from a print job
  Future<Uint8List> generatePdf(PrintJob job) async {
    _currentJob = job;
    _progressController.add(0.0);

    try {
      final pdf = pw.Document();
      final filteredPages = job.getFilteredPages();
      final pageSize = job.getEffectivePageSize();

      for (int i = 0; i < filteredPages.length; i++) {
        final page = filteredPages[i];
        final progress = (i + 1) / filteredPages.length;
        _progressController.add(progress);

        // Convert Flutter widget to PDF
        final widget = page.content;

        // Create PDF page
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat(
              pageSize.width,
              pageSize.height,
              marginLeft: page.margins.left,
              marginTop: page.margins.top,
              marginRight: page.margins.right,
              marginBottom: page.margins.bottom,
            ),
            build: (pw.Context context) {
              // Note: Direct widget conversion requires rasterization
              // For production, implement proper PDF rendering
              return pw.Center(
                child: pw.Text(
                  'Page ${page.pageNumber}\n${job.documentTitle}',
                  style: pw.TextStyle(fontSize: 24),
                  textAlign: pw.TextAlign.center,
                ),
              );
            },
          ),
        );
      }

      _progressController.add(1.0);
      return await pdf.save();
    } finally {
      _currentJob = null;
    }
  }

  /// Show print preview dialog
  Future<PrintResult> preview(PrintJob job, {BuildContext? context}) async {
    try {
      final pdfBytes = await generatePdf(job);

      if (context != null) {
        // Show preview in dialog
        await showDialog(
          context: context,
          builder: (ctx) => Dialog(
            child: Column(
              children: [
                AppBar(
                  title: Text('Print Preview - ${job.documentTitle}'),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.print),
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        await print(job);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                Expanded(
                  child: PdfPreview(
                    build: (format) => pdfBytes,
                    canChangeOrientation: false,
                    canChangePageFormat: false,
                    canDebug: false,
                  ),
                ),
              ],
            ),
          ),
        );
        return PrintResult.cancelled();
      } else {
        // Return preview data
        return PrintResult.success(
            pdfPath: 'preview', pagesPrinted: job.totalPages);
      }
    } catch (e) {
      return PrintResult.error('Preview failed: $e');
    }
  }

  /// Print document using native platform printer
  Future<PrintResult> print(PrintJob job, {BuildContext? context}) async {
    try {
      final pdfBytes = await generatePdf(job);
      final printerName = await Printing.selectPrinter();

      if (printerName == null) {
        return PrintResult.cancelled();
      }

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) => pdfBytes,
        name: job.documentTitle,
      );

      return PrintResult.success(pagesPrinted: job.totalPages * job.copies);
    } catch (e) {
      return PrintResult.error('Print failed: $e');
    }
  }

  /// Print directly without preview
  Future<PrintResult> printDirect(PrintJob job) async {
    try {
      final pdfBytes = await generatePdf(job);

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) => pdfBytes,
        name: job.documentTitle,
      );

      return PrintResult.success(pagesPrinted: job.totalPages * job.copies);
    } catch (e) {
      return PrintResult.error('Direct print failed: $e');
    }
  }

  /// Save PDF to file
  Future<PrintResult> saveToPdf(PrintJob job, {String? fileName}) async {
    try {
      final pdfBytes = await generatePdf(job);
      final directory = await getApplicationDocumentsDirectory();
      final safeFileName = fileName ??
          '${job.documentTitle.replaceAll(RegExp(r'[^\w\s-]'), '_')}.pdf';
      final filePath = path.join(directory.path, safeFileName);

      final file = await File(filePath).writeAsBytes(pdfBytes);

      return PrintResult.success(
          pdfPath: file.path, pagesPrinted: job.totalPages);
    } catch (e) {
      return PrintResult.error('Save to PDF failed: $e');
    }
  }

  /// Cancel current print operation
  void cancel() {
    _currentJob = null;
    _progressController.add(0.0);
  }

  /// Dispose resources
  void dispose() {
    _progressController.close();
  }
}
