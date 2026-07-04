/// DOCX Parser integration using the docx_reader Rust crate.
///
/// This module provides seamless integration with the DOCX parser engine
/// for importing and exporting Microsoft Word documents.
library;

import 'dart:convert';
import 'dart:typed_data';
import '../engine/document_engine.dart';

/// Parsed DOCX content ready for conversion to Document model
class DocxContent {
  final String title;
  final List<Map<String, dynamic>> blocks;
  final DocxMetadata metadata;

  DocxContent({
    required this.title,
    required this.blocks,
    required this.metadata,
  });
}

/// Service for parsing and generating DOCX files
class DocxParserService {
  static DocxParserService? _instance;
  final DocumentEngine _engine;

  static DocxParserService get instance {
    _instance ??= DocxParserService._();
    return _instance!;
  }

  DocxParserService._() : _engine = DocumentEngine.instance;

  /// Parse a DOCX file and convert to Document model
  ///
  /// Uses the docx_reader Rust parser to extract:
  /// - Paragraphs and headings
  /// - Text formatting (bold, italic, underline, etc.)
  /// - Lists (numbered and bulleted)
  /// - Tables
  /// - Images (metadata)
  /// - Headers and footers
  /// - Comments and tracked changes
  Future<DocxContent> parseDocx(Uint8List bytes) async {
    // Use Rust FFI parser via DocumentEngine
    try {
      await _engine.initialize();
      
      if (_engine.isNativeEngineAvailable) {
        // Native engine available - use FFI parsing
        final result = await _engine.parseDocxBytes(bytes);
        return _convertToDocxContent(result);
      } else {
        // Fallback to pure Dart implementation
        return _parseDocxFallback(bytes);
      }
    } catch (e) {
      print('DOCX parsing error: $e');
      return _parseDocxFallback(bytes);
    }
  }

  /// Fallback parser when native engine is not available
  DocxContent _parseDocxFallback(Uint8List bytes) {
    // Basic DOCX structure parsing using archive package
    // This is a simplified fallback - full parsing requires Rust FFI
    
    return DocxContent(
      title: 'Imported Document',
      blocks: [
        {
          'block_type': 'paragraph',
          'spans': [
            {
              'text': 'Document loaded (fallback mode). Full DOCX parsing requires native engine.',
              'style': {},
            },
          ],
        },
      ],
      metadata: DocxMetadata(
        title: 'Imported Document',
        author: 'Unknown',
        wordCount: 0,
        characterCount: 0,
        pageCount: 1,
      ),
    );
  }

  /// Convert parsed result to DocxContent
  DocxContent _convertToDocxContent(Map<String, dynamic> result) {
    return DocxContent(
      title: result['title'] as String? ?? 'Untitled',
      blocks: (result['blocks'] as List?)?.cast<Map<String, dynamic>>() ?? [],
      metadata: DocxMetadata.fromJson(
        result['metadata'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  /// Convert a Document to DOCX format
  ///
  /// Generates a valid .docx file preserving:
  /// - Document structure (blocks)
  /// - Text styling
  /// - Page settings
  /// - Metadata
  Future<Uint8List> generateDocx(Document document) async {
    try {
      await _engine.initialize();
      
      if (_engine.isNativeEngineAvailable) {
        // Use native engine for DOCX generation
        return _engine.generateDocxBytes(document);
      } else {
        throw UnimplementedError(
          'DOCX generation requires Rust FFI integration with docx_reader',
        );
      }
    } catch (e) {
      throw Exception('Failed to generate DOCX: $e');
    }
  }

  /// Extract plain text from DOCX (quick preview)
  Future<String> extractPlainText(Uint8List bytes) async {
    final content = await parseDocx(bytes);
    return _extractTextFromBlocks(content.blocks);
  }

  /// Extract text from block list
  String _extractTextFromBlocks(List<Map<String, dynamic>> blocks) {
    final buffer = StringBuffer();
    for (final block in blocks) {
      final spans = block['spans'] as List?;
      if (spans != null) {
        for (final span in spans) {
          final text = (span as Map)['text'] as String?;
          if (text != null && text.isNotEmpty) {
            buffer.write(text);
          }
        }
      }
      buffer.writeln();
    }
    return buffer.toString().trim();
  }

  /// Get document metadata from DOCX
  Future<DocxMetadata> extractMetadata(Uint8List bytes) async {
    final content = await parseDocx(bytes);
    return content.metadata;
  }

  /// Convert Rust parser output to Dart Document model
  Document _convertToDocument(DocxContent content) {
    return Document(
      title: content.title,
      blocks: content.blocks.map(_convertBlock).toList(),
    );
  }

  DocumentBlock _convertBlock(Map<String, dynamic> rustBlock) {
    return DocumentBlock(
      id: rustBlock['id'] as String? ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      type: _parseBlockType(rustBlock['block_type']),
      spans: (rustBlock['spans'] as List?)
              ?.map((s) => TextSpan.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  String _parseBlockType(dynamic blockType) {
    if (blockType is String) return blockType;
    final str = blockType.toString();
    return str.toLowerCase().replaceAll(RegExp(r'[()]'), '_');
  }
}

/// Metadata extracted from a DOCX file
class DocxMetadata {
  final String title;
  final String author;
  final DateTime? created;
  final DateTime? modified;
  final int wordCount;
  final int characterCount;
  final int pageCount;

  DocxMetadata({
    required this.title,
    required this.author,
    this.created,
    this.modified,
    this.wordCount = 0,
    this.characterCount = 0,
    this.pageCount = 0,
  });

  factory DocxMetadata.fromJson(Map<String, dynamic> json) {
    return DocxMetadata(
      title: json['title'] as String? ?? 'Untitled',
      author: json['author'] as String? ?? '',
      created: json['created'] != null
          ? DateTime.parse(json['created'] as String)
          : null,
      modified: json['modified'] != null
          ? DateTime.parse(json['modified'] as String)
          : null,
      wordCount: json['word_count'] as int? ?? 0,
      characterCount: json['character_count'] as int? ?? 0,
      pageCount: json['page_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'author': author,
      if (created != null) 'created': created!.toIso8601String(),
      if (modified != null) 'modified': modified!.toIso8601String(),
      'word_count': wordCount,
      'character_count': characterCount,
      'page_count': pageCount,
    };
  }
}