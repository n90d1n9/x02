import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../models/document_metadata.dart';

class DocxService {
  Future<String> extractTextFromDocx(Uint8List bytes) async {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final documentXml = archive.findFile('word/document.xml');

      if (documentXml == null) {
        throw Exception('Invalid DOCX file: document.xml not found');
      }

      final content = utf8.decode(documentXml.content as List<int>);

      // Extract text from XML tags
      final textRegex = RegExp(r'<w:t[^>]*>([^<]*)</w:t>');
      final matches = textRegex.allMatches(content);

      final buffer = StringBuffer();
      String? lastMatch;

      for (final match in matches) {
        final text = match.group(1) ?? '';
        if (text.isNotEmpty) {
          // Add space between words if needed
          if (lastMatch != null &&
              !lastMatch.endsWith(' ') &&
              !text.startsWith(' ')) {
            buffer.write(' ');
          }
          buffer.write(text);
          lastMatch = text;
        }
      }

      // Extract paragraphs for better formatting
      final paraRegex = RegExp(r'<w:p[^>]*>.*?</w:p>', dotAll: true);
      final paraMatches = paraRegex.allMatches(content);

      if (paraMatches.length > 1) {
        final formattedBuffer = StringBuffer();
        for (final para in paraMatches) {
          final paraContent = para.group(0) ?? '';
          final textInPara = textRegex.allMatches(paraContent);
          final paraText = textInPara.map((m) => m.group(1) ?? '').join('');
          if (paraText.isNotEmpty) {
            formattedBuffer.writeln(paraText);
          }
        }
        return formattedBuffer.toString().trim();
      }

      return buffer.toString().trim();
    } catch (e) {
      throw Exception('Failed to extract text from DOCX: $e');
    }
  }

  Future<Uint8List> createDocx(
    String plainText,
    DocumentMetadata metadata,
  ) async {
    try {
      final archive = Archive();

      // Create [Content_Types].xml
      final contentTypes =
          '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
  <Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
</Types>''';
      archive.addFile(
        ArchiveFile(
          '[Content_Types].xml',
          contentTypes.length,
          contentTypes.codeUnits,
        ),
      );

      // Create _rels/.rels
      final rels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
</Relationships>''';
      archive.addFile(ArchiveFile('_rels/.rels', rels.length, rels.codeUnits));

      // Create word/_rels/document.xml.rels
      final docRels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
</Relationships>''';
      archive.addFile(
        ArchiveFile(
          'word/_rels/document.xml.rels',
          docRels.length,
          docRels.codeUnits,
        ),
      );

      // Create word/document.xml with paragraphs
      final paragraphs = plainText
          .split('\n')
          .map((line) {
            final escaped = _escapeXml(line.isEmpty ? ' ' : line);
            return '<w:p><w:r><w:t xml:space="preserve">$escaped</w:t></w:r></w:p>';
          })
          .join('\n');

      final document =
          '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <w:body>
$paragraphs
  </w:body>
</w:document>''';
      archive.addFile(
        ArchiveFile('word/document.xml', document.length, document.codeUnits),
      );

      // Create docProps/core.xml with metadata
      final coreProps =
          '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <dc:title>${_escapeXml(metadata.title)}</dc:title>
  <dc:creator>${_escapeXml(metadata.author)}</dc:creator>
  <dcterms:created xsi:type="dcterms:W3CDTF">${metadata.createdAt.toIso8601String()}</dcterms:created>
  <dcterms:modified xsi:type="dcterms:W3CDTF">${metadata.lastModified.toIso8601String()}</dcterms:modified>
</cp:coreProperties>''';
      archive.addFile(
        ArchiveFile('docProps/core.xml', coreProps.length, coreProps.codeUnits),
      );

      // Create docProps/app.xml
      final appProps =
          '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties">
  <Application>Flutter DOCX Editor</Application>
  <Words>${metadata.wordCount}</Words>
  <Characters>${metadata.characterCount}</Characters>
</Properties>''';
      archive.addFile(
        ArchiveFile('docProps/app.xml', appProps.length, appProps.codeUnits),
      );

      final zipData = ZipEncoder().encode(archive) ?? Uint8List(0);
      return Uint8List.fromList(zipData);
    } catch (e) {
      throw Exception('Failed to create DOCX: $e');
    }
  }

  String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}
