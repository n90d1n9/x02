import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:path_provider/path_provider.dart';

import '../models/document_metadata.dart';
import '../models/export_options.dart';
import 'document_export_renderer.dart';
import 'docx_service.dart';
import 'pdf_service.dart';
import 'waraq_document_bridge.dart';

typedef ExportDirectoryProvider = Future<Directory> Function();

enum DocumentExportFormat { docx, pdf, txt }

class MultiExportResult {
  final Map<DocumentExportFormat, String> pathsByFormat;
  final List<String> errors;

  const MultiExportResult({required this.pathsByFormat, required this.errors});

  List<String> get paths => pathsByFormat.values.toList(growable: false);
  bool get hasErrors => errors.isNotEmpty;

  String? get errorMessage {
    return hasErrors ? 'Some exports failed: ${errors.join(", ")}' : null;
  }

  bool exported(DocumentExportFormat format) {
    return pathsByFormat.containsKey(format);
  }
}

class DocumentExportService {
  final DocxService docxService;
  final PdfService pdfService;
  final DocumentExportRenderer renderer;
  final WaraqDocumentBridge waraqBridge;
  final ExportDirectoryProvider directoryProvider;

  DocumentExportService({
    required this.docxService,
    required this.pdfService,
    DocumentExportRenderer? renderer,
    this.waraqBridge = const WaraqDocumentBridge(),
    this.directoryProvider = getApplicationDocumentsDirectory,
  }) : renderer =
           renderer ??
           DartDocumentExportRenderer(
             docxService: docxService,
             pdfService: pdfService,
           );

  Future<String> exportDocx({
    required String text,
    required DocumentMetadata metadata,
    quill.Document? document,
  }) async {
    final request = waraqBridge.createExportRequest(
      text: text,
      metadata: metadata,
      document: document,
    );
    final bytes = await renderer.renderDocx(request);
    return _writeBytes(metadata: metadata, extension: 'docx', bytes: bytes);
  }

  Future<String> exportPdf({
    required String text,
    required DocumentMetadata metadata,
    quill.Document? document,
    ExportOptions options = const ExportOptions(),
  }) async {
    final request = waraqBridge.createExportRequest(
      text: text,
      metadata: metadata,
      document: document,
    );
    final bytes = await renderer.renderPdf(request, options);
    return _writeBytes(metadata: metadata, extension: 'pdf', bytes: bytes);
  }

  Future<String> exportTxt({
    required String text,
    required DocumentMetadata metadata,
  }) {
    return _writeText(metadata: metadata, extension: 'txt', text: text);
  }

  Future<MultiExportResult> exportMultiple({
    required String text,
    required DocumentMetadata metadata,
    quill.Document? document,
  }) async {
    final pathsByFormat = <DocumentExportFormat, String>{};
    final errors = <String>[];

    await _tryExport(
      format: DocumentExportFormat.docx,
      label: 'DOCX',
      pathsByFormat: pathsByFormat,
      errors: errors,
      export: () =>
          exportDocx(text: text, metadata: metadata, document: document),
    );
    await _tryExport(
      format: DocumentExportFormat.pdf,
      label: 'PDF',
      pathsByFormat: pathsByFormat,
      errors: errors,
      export: () =>
          exportPdf(text: text, metadata: metadata, document: document),
    );
    await _tryExport(
      format: DocumentExportFormat.txt,
      label: 'TXT',
      pathsByFormat: pathsByFormat,
      errors: errors,
      export: () => exportTxt(text: text, metadata: metadata),
    );

    return MultiExportResult(pathsByFormat: pathsByFormat, errors: errors);
  }

  String fileNameFor(DocumentMetadata metadata, String extension) {
    return '${sanitizeBaseName(metadata.title)}.$extension';
  }

  String sanitizeBaseName(String title) {
    final sanitized = title.replaceAll(RegExp(r'[^\w\s-]'), '_').trim();
    return sanitized.isEmpty ? 'Untitled Document' : sanitized;
  }

  Future<void> _tryExport({
    required DocumentExportFormat format,
    required String label,
    required Map<DocumentExportFormat, String> pathsByFormat,
    required List<String> errors,
    required Future<String> Function() export,
  }) async {
    try {
      pathsByFormat[format] = await export();
    } catch (error) {
      errors.add('$label: $error');
    }
  }

  Future<String> _writeBytes({
    required DocumentMetadata metadata,
    required String extension,
    required Uint8List bytes,
  }) async {
    final directory = await directoryProvider();
    final file = File(_filePath(directory, fileNameFor(metadata, extension)));
    await file.writeAsBytes(bytes);
    return file.path;
  }

  Future<String> _writeText({
    required DocumentMetadata metadata,
    required String extension,
    required String text,
  }) async {
    final directory = await directoryProvider();
    final file = File(_filePath(directory, fileNameFor(metadata, extension)));
    await file.writeAsString(text);
    return file.path;
  }

  String _filePath(Directory directory, String fileName) {
    return '${directory.path}${Platform.pathSeparator}$fileName';
  }
}
