import 'package:flutter/material.dart';
import 'print_page.dart';

/// Orientation for print jobs
enum PrintOrientation { portrait, landscape }

/// Paper size presets
enum PaperSize {
  letter, // 8.5 x 11 inches
  legal, // 8.5 x 14 inches
  a4, // 210 x 297 mm
  a3, // 297 x 420 mm
  b5, // 176 x 250 mm
  custom,
}

/// Configuration for a print job
class PrintJob {
  /// Unique identifier for the print job
  final String id;

  /// Title of the document to print
  final String documentTitle;

  /// List of pages to print
  final List<PrintPage> pages;

  /// Number of copies to print
  final int copies;

  /// Page orientation
  final PrintOrientation orientation;

  /// Paper size
  final PaperSize paperSize;

  /// Custom paper dimensions (if paperSize is custom)
  final Size? customSize;

  /// Scale factor for content (0.0 - 1.0)
  final double scale;

  /// Whether to print in grayscale
  final bool grayscale;

  /// Page range to print (null = all pages)
  final Range? pageRange;

  /// Whether to enable duplex (double-sided) printing
  final bool duplex;

  /// Creates a print job configuration
  const PrintJob({
    required this.id,
    required this.documentTitle,
    required this.pages,
    this.copies = 1,
    this.orientation = PrintOrientation.portrait,
    this.paperSize = PaperSize.a4,
    this.customSize,
    this.scale = 1.0,
    this.grayscale = false,
    this.pageRange,
    this.duplex = false,
  })  : assert(scale > 0.0 && scale <= 1.0),
        assert(copies > 0);

  /// Get effective page size based on orientation and paper size
  Size getEffectivePageSize() {
    if (paperSize == PaperSize.custom && customSize != null) {
      return orientation == PrintOrientation.landscape
          ? Size(customSize!.height, customSize!.width)
          : customSize!;
    }

    switch (paperSize) {
      case PaperSize.letter:
        final size = const Size(612.0, 792.0); // 8.5x11 at 72 DPI
        return orientation == PrintOrientation.landscape
            ? Size(size.height, size.width)
            : size;
      case PaperSize.legal:
        final size = const Size(612.0, 1008.0); // 8.5x14 at 72 DPI
        return orientation == PrintOrientation.landscape
            ? Size(size.height, size.width)
            : size;
      case PaperSize.a4:
        final size = const Size(595.0, 842.0); // A4 at 72 DPI
        return orientation == PrintOrientation.landscape
            ? Size(size.height, size.width)
            : size;
      case PaperSize.a3:
        final size = const Size(842.0, 1190.0); // A3 at 72 DPI
        return orientation == PrintOrientation.landscape
            ? Size(size.height, size.width)
            : size;
      case PaperSize.b5:
        final size = const Size(499.0, 709.0); // B5 at 72 DPI
        return orientation == PrintOrientation.landscape
            ? Size(size.height, size.width)
            : size;
      case PaperSize.custom:
        return const Size(595.0, 842.0); // Default to A4
    }
  }

  /// Get filtered pages based on page range
  List<PrintPage> getFilteredPages() {
    if (pageRange == null) return pages;

    final start = pageRange!.start.clamp(1, pages.length);
    final end = pageRange!.end.clamp(1, pages.length);

    return pages
        .where((p) => p.pageNumber >= start && p.pageNumber <= end)
        .toList();
  }

  /// Total number of pages to print
  int get totalPages => getFilteredPages().length;

  /// Creates a copy with updated fields
  PrintJob copyWith({
    String? id,
    String? documentTitle,
    List<PrintPage>? pages,
    int? copies,
    PrintOrientation? orientation,
    PaperSize? paperSize,
    Size? customSize,
    double? scale,
    bool? grayscale,
    Range? pageRange,
    bool? duplex,
  }) {
    return PrintJob(
      id: id ?? this.id,
      documentTitle: documentTitle ?? this.documentTitle,
      pages: pages ?? this.pages,
      copies: copies ?? this.copies,
      orientation: orientation ?? this.orientation,
      paperSize: paperSize ?? this.paperSize,
      customSize: customSize ?? this.customSize,
      scale: scale ?? this.scale,
      grayscale: grayscale ?? this.grayscale,
      pageRange: pageRange ?? this.pageRange,
      duplex: duplex ?? this.duplex,
    );
  }

  @override
  String toString() {
    return 'PrintJob(id: $id, title: $documentTitle, pages: $totalPages, copies: $copies)';
  }
}
