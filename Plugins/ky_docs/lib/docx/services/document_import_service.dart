import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../models/document_import_status.dart';
import '../models/document_import_structure.dart';
import 'document_import_extractor.dart';
import 'document_import_preview_analyzer.dart';
import 'docx_service.dart';
import 'pdf_service.dart';
import 'waraq_document_bridge.dart';

typedef DocumentFilePicker =
    Future<PickedDocumentFile?> Function(DocumentImportFormat format);

enum DocumentImportFormat { docx, pdf }

class PickedDocumentFile {
  final String name;
  final Uint8List bytes;

  const PickedDocumentFile({required this.name, required this.bytes});
}

class ImportedDocument {
  final String title;
  final String text;
  final String? docsEngineJson;
  final String sourceFileName;
  final DocumentImportKind? kind;
  final DocumentImportMethod method;
  final DocumentImportStructureSummary structure;
  final String? warningMessage;

  const ImportedDocument({
    required this.title,
    required this.text,
    this.docsEngineJson,
    this.sourceFileName = '',
    this.kind,
    this.method = DocumentImportMethod.customExtractor,
    this.structure = const DocumentImportStructureSummary.empty(),
    this.warningMessage,
  });

  DocumentImportPreview preview({required DocumentImportKind fallbackKind}) {
    return DocumentImportPreview.fromText(
      kind: kind ?? fallbackKind,
      title: title,
      sourceFileName: sourceFileName.isEmpty ? title : sourceFileName,
      text: text,
      method: method,
      hasStructuredContent: docsEngineJson != null,
      structure: structure,
      warningMessage: warningMessage,
    );
  }
}

class DocumentImportService {
  final DocxService docxService;
  final PdfService pdfService;
  final DocumentImportExtractor extractor;
  final DocumentImportPreviewAnalyzer previewAnalyzer;
  final WaraqDocumentBridge waraqBridge;
  final DocumentFilePicker filePicker;

  DocumentImportService({
    required this.docxService,
    required this.pdfService,
    DocumentImportExtractor? extractor,
    this.previewAnalyzer = const DocumentImportPreviewAnalyzer(),
    this.waraqBridge = const WaraqDocumentBridge(),
    this.filePicker = pickDocumentFile,
  }) : extractor =
           extractor ??
           DartDocumentImportExtractor(
             docxService: docxService,
             pdfService: pdfService,
           );

  Future<ImportedDocument?> importDocx() {
    return importFormat(DocumentImportFormat.docx);
  }

  Future<ImportedDocument?> importPdf() {
    return importFormat(DocumentImportFormat.pdf);
  }

  Future<ImportedDocument?> importFormat(DocumentImportFormat format) async {
    final pickedFile = await filePicker(format);
    if (pickedFile == null) return null;

    final content = await _extractContent(format, pickedFile);
    final hasStructuredContent = content.docsEngineJson != null;
    return ImportedDocument(
      title: titleFromFileName(pickedFile.name),
      text: content.text,
      docsEngineJson: content.docsEngineJson,
      sourceFileName: pickedFile.name,
      kind: _importKind(format),
      method: content.method,
      structure: previewAnalyzer.analyzeStructure(
        text: content.text,
        docsEngineJson: content.docsEngineJson,
        hasStructuredContent: hasStructuredContent,
        method: content.method,
      ),
      warningMessage: content.warningMessage,
    );
  }

  String titleFromFileName(String fileName) {
    final title = fileName.replaceAll(RegExp(r'\.[^.]+$'), '').trim();
    return title.isEmpty ? 'Untitled Document' : title;
  }

  Future<DocumentImportContent> _extractContent(
    DocumentImportFormat format,
    PickedDocumentFile pickedFile,
  ) async {
    final request = waraqBridge.createImportRequest(
      format: _waraqFormat(format),
      fileName: pickedFile.name,
      bytes: pickedFile.bytes,
    );

    final structuredExtractor = extractor;
    if (structuredExtractor is DocumentStructuredImportExtractor) {
      return structuredExtractor.extractContent(request);
    }

    return DocumentImportContent.plainText(
      await extractor.extractText(request),
    );
  }

  WaraqDocumentFormat _waraqFormat(DocumentImportFormat format) {
    switch (format) {
      case DocumentImportFormat.docx:
        return WaraqDocumentFormat.docx;
      case DocumentImportFormat.pdf:
        return WaraqDocumentFormat.pdf;
    }
  }

  DocumentImportKind _importKind(DocumentImportFormat format) {
    switch (format) {
      case DocumentImportFormat.docx:
        return DocumentImportKind.docx;
      case DocumentImportFormat.pdf:
        return DocumentImportKind.pdf;
    }
  }
}

Future<PickedDocumentFile?> pickDocumentFile(
  DocumentImportFormat format,
) async {
  final result = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: _allowedExtensions(format),
    allowMultiple: false,
  );

  final file = result?.files.single;
  final path = file?.path;
  if (file == null || path == null) return null;

  return PickedDocumentFile(
    name: file.name,
    bytes: await File(path).readAsBytes(),
  );
}

List<String> _allowedExtensions(DocumentImportFormat format) {
  switch (format) {
    case DocumentImportFormat.docx:
      return ['docx', 'doc'];
    case DocumentImportFormat.pdf:
      return ['pdf'];
  }
}
