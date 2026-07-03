import 'dart:typed_data';

import '../models/export_options.dart';
import 'docx_service.dart';
import 'pdf_service.dart';
import 'waraq_document_bridge.dart';

abstract class DocumentExportRenderer {
  Future<Uint8List> renderDocx(WaraqExportRequest request);

  Future<Uint8List> renderPdf(
    WaraqExportRequest request,
    ExportOptions options,
  );
}

class DartDocumentExportRenderer implements DocumentExportRenderer {
  final DocxService docxService;
  final PdfService pdfService;

  const DartDocumentExportRenderer({
    required this.docxService,
    required this.pdfService,
  });

  @override
  Future<Uint8List> renderDocx(WaraqExportRequest request) {
    return docxService.createDocx(request.plainText, request.metadata);
  }

  @override
  Future<Uint8List> renderPdf(
    WaraqExportRequest request,
    ExportOptions options,
  ) {
    return pdfService.createAdvancedPdf(
      request.plainText,
      request.metadata,
      options,
    );
  }
}
