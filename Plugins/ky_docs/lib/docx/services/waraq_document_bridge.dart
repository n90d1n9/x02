import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_quill/flutter_quill.dart' as quill;

import '../models/document_metadata.dart';
import 'waraq_quill_document_mapper.dart';

enum WaraqDocumentFormat { docx, pdf }

class WaraqLibraryPaths {
  final String docsEngine;
  final String docxCore;
  final String pdfCore;

  const WaraqLibraryPaths({
    required this.docsEngine,
    required this.docxCore,
    required this.pdfCore,
  });

  static const workspace = WaraqLibraryPaths(
    docsEngine:
        '/Users/bhangun/Workspace/workkayys/Products/Libraries/Productivity/Waraq/docs_engine',
    docxCore:
        '/Users/bhangun/Workspace/workkayys/Products/Libraries/Productivity/Waraq/docx-core',
    pdfCore:
        '/Users/bhangun/Workspace/workkayys/Products/Libraries/Productivity/Waraq/pdf-core',
  );

  Map<String, Object?> toJson() {
    return {
      'docs_engine': docsEngine,
      'docx_core': docxCore,
      'pdf_core': pdfCore,
    };
  }
}

class WaraqExportRequest {
  final String plainText;
  final DocumentMetadata metadata;
  final String docsEngineJson;
  final WaraqLibraryPaths libraryPaths;

  const WaraqExportRequest({
    required this.plainText,
    required this.metadata,
    required this.docsEngineJson,
    required this.libraryPaths,
  });
}

class WaraqImportRequest {
  final WaraqDocumentFormat format;
  final String fileName;
  final Uint8List bytes;
  final WaraqLibraryPaths libraryPaths;

  const WaraqImportRequest({
    required this.format,
    required this.fileName,
    required this.bytes,
    required this.libraryPaths,
  });
}

class WaraqDocumentBridge {
  final WaraqLibraryPaths libraryPaths;
  final WaraqQuillDocumentMapper documentMapper;

  const WaraqDocumentBridge({
    this.libraryPaths = WaraqLibraryPaths.workspace,
    this.documentMapper = const WaraqQuillDocumentMapper(),
  });

  WaraqExportRequest createExportRequest({
    required String text,
    required DocumentMetadata metadata,
    quill.Document? document,
  }) {
    return WaraqExportRequest(
      plainText: text,
      metadata: metadata,
      docsEngineJson: document == null
          ? toDocsEngineJson(text: text, metadata: metadata)
          : documentMapper.toDocsEngineJson(
              document: document,
              metadata: metadata,
            ),
      libraryPaths: libraryPaths,
    );
  }

  WaraqImportRequest createImportRequest({
    required WaraqDocumentFormat format,
    required String fileName,
    required Uint8List bytes,
  }) {
    return WaraqImportRequest(
      format: format,
      fileName: fileName,
      bytes: bytes,
      libraryPaths: libraryPaths,
    );
  }

  String toDocsEngineJson({
    required String text,
    required DocumentMetadata metadata,
  }) {
    return jsonEncode({'title': metadata.title, 'blocks': _blocksFor(text)});
  }

  List<Map<String, Object?>> _blocksFor(String text) {
    final normalized = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final documentText = normalized.endsWith('\n')
        ? normalized.substring(0, normalized.length - 1)
        : normalized;
    final lines = documentText.isEmpty ? const [''] : documentText.split('\n');

    return [
      for (var index = 0; index < lines.length; index++)
        {
          'id': 'block-$index',
          'block_type': 'Paragraph',
          'spans': [
            {'text': lines[index], 'style': _defaultInlineStyle()},
          ],
        },
    ];
  }

  Map<String, Object?> _defaultInlineStyle() {
    return {
      'bold': false,
      'italic': false,
      'underline': false,
      'strikethrough': false,
      'font_family': null,
      'font_size': null,
      'color': null,
    };
  }
}
