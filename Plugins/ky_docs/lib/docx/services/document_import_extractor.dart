import '../models/document_import_status.dart';
import 'docx_service.dart';
import 'pdf_service.dart';
import 'waraq_document_bridge.dart';

class DocumentImportContent {
  final String text;
  final String? docsEngineJson;
  final DocumentImportMethod method;
  final String? warningMessage;

  const DocumentImportContent({
    required this.text,
    this.docsEngineJson,
    this.method = DocumentImportMethod.customExtractor,
    this.warningMessage,
  });

  const DocumentImportContent.plainText(
    String text, {
    DocumentImportMethod method = DocumentImportMethod.dartExtractor,
    String? warningMessage,
  }) : this(text: text, method: method, warningMessage: warningMessage);

  const DocumentImportContent.structured({
    required String text,
    required String docsEngineJson,
    DocumentImportMethod method = DocumentImportMethod.customExtractor,
    String? warningMessage,
  }) : this(
         text: text,
         docsEngineJson: docsEngineJson,
         method: method,
         warningMessage: warningMessage,
       );

  DocumentImportContent copyWith({
    String? text,
    String? docsEngineJson,
    bool clearDocsEngineJson = false,
    DocumentImportMethod? method,
    String? warningMessage,
    bool clearWarning = false,
  }) {
    return DocumentImportContent(
      text: text ?? this.text,
      docsEngineJson: clearDocsEngineJson
          ? null
          : (docsEngineJson ?? this.docsEngineJson),
      method: method ?? this.method,
      warningMessage: clearWarning
          ? null
          : (warningMessage ?? this.warningMessage),
    );
  }
}

abstract class DocumentImportExtractor {
  Future<String> extractText(WaraqImportRequest request);
}

abstract class DocumentStructuredImportExtractor
    implements DocumentImportExtractor {
  Future<DocumentImportContent> extractContent(WaraqImportRequest request);
}

class DartDocumentImportExtractor implements DocumentImportExtractor {
  final DocxService docxService;
  final PdfService pdfService;

  const DartDocumentImportExtractor({
    required this.docxService,
    required this.pdfService,
  });

  @override
  Future<String> extractText(WaraqImportRequest request) {
    switch (request.format) {
      case WaraqDocumentFormat.docx:
        return docxService.extractTextFromDocx(request.bytes);
      case WaraqDocumentFormat.pdf:
        return pdfService.extractTextFromPdf(request.bytes);
    }
  }
}
