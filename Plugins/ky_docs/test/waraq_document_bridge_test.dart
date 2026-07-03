import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/document_metadata.dart';
import 'package:ky_docs/docx/services/waraq_document_bridge.dart';

void main() {
  group('WaraqDocumentBridge', () {
    test('builds docs_engine compatible JSON blocks from plain text', () {
      const bridge = WaraqDocumentBridge();
      final json = bridge.toDocsEngineJson(
        text: 'Heading\nBody line\n',
        metadata: _metadata(title: 'Proposal'),
      );

      final document = jsonDecode(json) as Map<String, dynamic>;
      final blocks = document['blocks'] as List<dynamic>;

      expect(document['title'], 'Proposal');
      expect(blocks, hasLength(2));
      expect(blocks.first['id'], 'block-0');
      expect(blocks.first['block_type'], 'Paragraph');
      expect(blocks.first['spans'].single['text'], 'Heading');
      expect(blocks.last['spans'].single['text'], 'Body line');
      expect(blocks.first['spans'].single['style']['bold'], isFalse);
    });

    test('carries Waraq docs_engine, docx-core, and pdf-core paths', () {
      const bridge = WaraqDocumentBridge(
        libraryPaths: WaraqLibraryPaths(
          docsEngine: '/docs_engine',
          docxCore: '/docx-core',
          pdfCore: '/pdf-core',
        ),
      );

      final request = bridge.createExportRequest(
        text: 'Body',
        metadata: _metadata(),
      );

      expect(request.plainText, 'Body');
      expect(request.libraryPaths.toJson(), {
        'docs_engine': '/docs_engine',
        'docx_core': '/docx-core',
        'pdf_core': '/pdf-core',
      });
    });

    test('builds Waraq import requests for core extractors', () {
      const bridge = WaraqDocumentBridge(
        libraryPaths: WaraqLibraryPaths(
          docsEngine: '/docs_engine',
          docxCore: '/docx-core',
          pdfCore: '/pdf-core',
        ),
      );

      final request = bridge.createImportRequest(
        format: WaraqDocumentFormat.docx,
        fileName: 'Draft.docx',
        bytes: Uint8List.fromList([1, 2, 3]),
      );

      expect(request.format, WaraqDocumentFormat.docx);
      expect(request.fileName, 'Draft.docx');
      expect(request.bytes, [1, 2, 3]);
      expect(request.libraryPaths.docxCore, '/docx-core');
    });
  });
}

DocumentMetadata _metadata({String title = 'Document'}) {
  return DocumentMetadata(
    id: 'doc-1',
    title: title,
    createdAt: DateTime(2026),
    modifiedAt: DateTime(2026, 1, 2),
  );
}
