import 'document_import_extractor.dart';
import 'document_import_service.dart';
import 'docx_service.dart';
import 'pdf_service.dart';
import 'waraq_document_bridge.dart';
import 'waraq_pdf_import_extractor.dart';

class WaraqDocumentImportServiceFactory {
  final WaraqPdfImportConfiguration pdfImportConfiguration;

  const WaraqDocumentImportServiceFactory({
    this.pdfImportConfiguration = const WaraqPdfImportConfiguration.resilient(),
  });

  DocumentImportService createPdfPreferred({
    required DocxService docxService,
    required PdfService pdfService,
    WaraqDocumentBridge waraqBridge = const WaraqDocumentBridge(),
    DocumentFilePicker filePicker = pickDocumentFile,
  }) {
    final fallbackExtractor = DartDocumentImportExtractor(
      docxService: docxService,
      pdfService: pdfService,
    );

    return DocumentImportService(
      docxService: docxService,
      pdfService: pdfService,
      extractor: pdfImportConfiguration.createExtractor(
        fallbackExtractor: fallbackExtractor,
      ),
      waraqBridge: waraqBridge,
      filePicker: filePicker,
    );
  }
}
