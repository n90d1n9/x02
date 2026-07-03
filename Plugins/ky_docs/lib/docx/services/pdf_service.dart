import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/document_metadata.dart';
import '../models/export_options.dart';

class PdfService {
  Future<String> extractTextFromPdf(Uint8List bytes) async {
    // Note: For real PDF text extraction, you can use:
    // 1. pdf_text package (basic extraction)
    // 2. Native platform channels with PDFKit (iOS) or PdfDocument (Android)
    // For now, return a helpful message
    return '''PDF text extraction requires additional setup.

For production use, consider:
1. pdf_text package for basic extraction
2. Native platform channels for better accuracy
3. Server-side extraction via API

This is a placeholder implementation.''';
  }

  Future<Uint8List> createAdvancedPdf(
    String plainText,
    DocumentMetadata metadata,
    ExportOptions options,
  ) async {
    final pdf = pw.Document();

    // Load a font that supports more characters
    final font = await PdfGoogleFonts.robotoRegular();

    final lines = plainText.split('\n');

    // Calculate lines per page
    final pageHeight = options.pageFormat.height;
    final contentHeight =
        pageHeight - options.margins.top - options.margins.bottom;
    final lineHeight = options.fontSize * options.lineSpacing;
    var linesPerPage = (contentHeight / lineHeight).floor();

    if (options.includeHeader) linesPerPage -= 3;
    if (options.includeFooter || options.includePageNumbers) linesPerPage -= 3;

    var pageNumber = 1;
    final totalPages = (lines.length / linesPerPage).ceil();

    for (var i = 0; i < lines.length; i += linesPerPage) {
      final pageLines = lines.skip(i).take(linesPerPage).toList();

      pdf.addPage(
        pw.Page(
          pageFormat: options.pageFormat,
          margin: pw.EdgeInsets.all(options.margins.top),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (options.includeHeader && options.headerText != null) ...[
                  pw.Text(
                    options.headerText!,
                    style: pw.TextStyle(
                      font: font,
                      fontSize: options.fontSize - 2,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.Divider(color: PdfColors.grey400),
                  pw.SizedBox(height: 10),
                ],
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: pageLines.map((line) {
                      return pw.Padding(
                        padding: pw.EdgeInsets.only(
                          bottom: lineHeight - options.fontSize,
                        ),
                        child: pw.Text(
                          line.isEmpty ? ' ' : line,
                          style: pw.TextStyle(
                            font: font,
                            fontSize: options.fontSize,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                if (options.includeFooter || options.includePageNumbers) ...[
                  pw.SizedBox(height: 10),
                  pw.Divider(color: PdfColors.grey400),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      if (options.includeFooter && options.footerText != null)
                        pw.Text(
                          options.footerText!,
                          style: pw.TextStyle(
                            font: font,
                            fontSize: options.fontSize - 2,
                            color: PdfColors.grey700,
                          ),
                        )
                      else
                        pw.SizedBox(),
                      if (options.includePageNumbers)
                        pw.Text(
                          'Page $pageNumber of $totalPages',
                          style: pw.TextStyle(
                            font: font,
                            fontSize: options.fontSize - 2,
                            color: PdfColors.grey700,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      );
      pageNumber++;
    }

    // Add metadata
    if (options.includeMetadata) {
      /*  pdf.pdfPageList.pages.forEach((page) {
        final doc = page.document;
        if (doc != null) {
          doc.info.title = metadata.title;
          doc.info.author = metadata.author;
          doc.info.creator = 'Flutter DOCX Editor';
          doc.info.producer = 'Flutter PDF Package';
          doc.info.creationDate = metadata.createdAt;
          doc.info.modificationDate = metadata.modifiedAt;
        }
      }); */
    }

    return Uint8List.fromList(await pdf.save());
  }
}
