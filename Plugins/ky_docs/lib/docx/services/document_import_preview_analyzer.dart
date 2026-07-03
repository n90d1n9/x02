import 'dart:convert';
import 'dart:math' as math;

import '../models/document_import_status.dart';
import '../models/document_import_structure.dart';

class DocumentImportPreviewAnalyzer {
  const DocumentImportPreviewAnalyzer();

  DocumentImportPreview buildPreview({
    required DocumentImportKind kind,
    required String title,
    required String sourceFileName,
    required String text,
    required DocumentImportMethod method,
    required bool hasStructuredContent,
    String? docsEngineJson,
    String? warningMessage,
  }) {
    return DocumentImportPreview.fromText(
      kind: kind,
      title: title,
      sourceFileName: sourceFileName,
      text: text,
      method: method,
      hasStructuredContent: hasStructuredContent,
      structure: analyzeStructure(
        text: text,
        docsEngineJson: docsEngineJson,
        hasStructuredContent: hasStructuredContent,
        method: method,
      ),
      warningMessage: warningMessage,
    );
  }

  DocumentImportStructureSummary analyzeStructure({
    required String text,
    required bool hasStructuredContent,
    required DocumentImportMethod method,
    String? docsEngineJson,
  }) {
    var metadataWasInvalid = false;
    final structured = _structuredSummary(text: text, json: docsEngineJson);
    if (structured == _StructuredSummaryResult.invalid) {
      metadataWasInvalid = true;
    } else if (structured != null) {
      return structured.summary.copyWithQuality(
        _qualitySignals(
          text: text,
          method: method,
          hasStructuredContent: hasStructuredContent,
          metadataWasInvalid: false,
        ),
      );
    }

    final plainTextSummary = _plainTextSummary(text);
    return plainTextSummary.copyWithQuality(
      _qualitySignals(
        text: text,
        method: method,
        hasStructuredContent: hasStructuredContent,
        metadataWasInvalid: metadataWasInvalid,
      ),
    );
  }

  _StructuredSummaryResult? _structuredSummary({
    required String text,
    required String? json,
  }) {
    if (json == null || json.trim().isEmpty) return null;

    Object? decoded;
    try {
      decoded = jsonDecode(json);
    } catch (_) {
      return _StructuredSummaryResult.invalid;
    }

    if (decoded is! Map) return _StructuredSummaryResult.invalid;

    final blocks = decoded['blocks'];
    if (blocks is! List) return _StructuredSummaryResult.invalid;

    var paragraphCount = 0;
    var headingCount = 0;
    var listItemCount = 0;
    var tableCount = 0;
    var pageBreakCount = 0;
    final headings = <String>[];

    for (final block in blocks) {
      if (block is! Map) continue;

      final blockType = block['block_type'];
      final blockText = _blockText(block);
      if (_isHeading(blockType)) {
        headingCount++;
        if (blockText.isNotEmpty && headings.length < 5) {
          headings.add(blockText);
        }
      } else if (_isListItem(blockType)) {
        listItemCount++;
      } else if (_isTable(blockType)) {
        tableCount++;
      } else if (_isPageBreak(blockType)) {
        pageBreakCount++;
      } else if (blockText.isNotEmpty) {
        paragraphCount++;
      }
    }

    final explicitPageCount = _pageCountFrom(decoded);
    final pageCount = math.max(
      1,
      explicitPageCount ?? math.max(pageBreakCount + 1, _estimatedPages(text)),
    );

    return _StructuredSummaryResult(
      DocumentImportStructureSummary(
        pageCount: pageCount,
        paragraphCount: paragraphCount,
        headingCount: headingCount,
        listItemCount: listItemCount,
        tableCount: tableCount,
        headings: List.unmodifiable(headings),
        qualitySignals: const [],
        likelyScanned: text.trim().isEmpty,
      ),
    );
  }

  DocumentImportStructureSummary _plainTextSummary(String text) {
    final normalized = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final lines = normalized
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    final headings = <String>[];
    var listItemCount = 0;

    for (final line in lines) {
      if (_isListLine(line)) {
        listItemCount++;
        continue;
      }

      final heading = _plainTextHeading(line);
      if (heading != null && headings.length < 5) {
        headings.add(heading);
      }
    }

    return DocumentImportStructureSummary(
      pageCount: _estimatedPages(text),
      paragraphCount: _paragraphCount(normalized),
      headingCount: headings.length,
      listItemCount: listItemCount,
      tableCount: 0,
      headings: List.unmodifiable(headings),
      qualitySignals: const [],
      likelyScanned: text.trim().isEmpty,
    );
  }

  List<String> _qualitySignals({
    required String text,
    required DocumentImportMethod method,
    required bool hasStructuredContent,
    required bool metadataWasInvalid,
  }) {
    final signals = <String>[];
    final wordCount = _wordCount(text);

    if (method.usedFallback) {
      signals.add('Fallback extraction used');
    }
    if (text.trim().isEmpty) {
      signals.add('No readable text detected');
      signals.add('May be scanned or image-only');
    } else if (wordCount < 8) {
      signals.add('Very little readable text detected');
    }
    if (!hasStructuredContent) {
      signals.add('Plain text only; formatting may be limited');
    }
    if (metadataWasInvalid) {
      signals.add('Structured metadata could not be analyzed');
    }

    return List.unmodifiable(signals);
  }

  String _blockText(Map<dynamic, dynamic> block) {
    final spans = block['spans'];
    if (spans is! List) return '';

    return spans
        .whereType<Map>()
        .map((span) => span['text'])
        .whereType<String>()
        .join()
        .trim();
  }

  bool _isHeading(Object? blockType) {
    return blockType is Map && blockType.containsKey('Heading');
  }

  bool _isListItem(Object? blockType) {
    return blockType is Map && blockType.containsKey('ListItem');
  }

  bool _isTable(Object? blockType) {
    return blockType == 'Table' ||
        (blockType is Map && blockType.containsKey('Table'));
  }

  bool _isPageBreak(Object? blockType) {
    return blockType == 'PageBreak' ||
        (blockType is Map && blockType.containsKey('PageBreak'));
  }

  int? _pageCountFrom(Map<dynamic, dynamic> document) {
    final pageCount = _intValue(document['page_count']);
    if (pageCount != null) return pageCount;

    final pages = document['pages'];
    if (pages is List && pages.isNotEmpty) return pages.length;

    final metadata = document['metadata'];
    if (metadata is Map) {
      return _intValue(metadata['page_count']) ??
          _intValue(metadata['source_page_count']);
    }

    return null;
  }

  int? _intValue(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  int _estimatedPages(String text) {
    final formFeedPages = '\f'.allMatches(text).length + 1;
    if (formFeedPages > 1) return formFeedPages;

    return math.max(1, (_wordCount(text) / 500).ceil());
  }

  int _paragraphCount(String text) {
    return text
        .split(RegExp(r'\n\s*\n'))
        .map((paragraph) => paragraph.trim())
        .where((paragraph) => paragraph.isNotEmpty)
        .length;
  }

  int _wordCount(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 0;
    return trimmed.split(RegExp(r'\s+')).length;
  }

  bool _isListLine(String line) {
    return RegExp(r'^([-*]|\d+[.)])\s+').hasMatch(line);
  }

  String? _plainTextHeading(String line) {
    final markdownHeading = RegExp(r'^(#{1,6})\s+(.+)$').firstMatch(line);
    if (markdownHeading != null) return markdownHeading.group(2)!.trim();

    final words = line.split(RegExp(r'\s+'));
    final hasTerminalPunctuation = RegExp(r'[.!?,;:]$').hasMatch(line);
    final mostlyUppercase =
        line.length > 3 &&
        line == line.toUpperCase() &&
        RegExp(r'[A-Z]').hasMatch(line);

    if (!hasTerminalPunctuation && words.length <= 10 && line.length <= 80) {
      if (mostlyUppercase || words.length <= 5) return line;
    }

    return null;
  }
}

extension on DocumentImportStructureSummary {
  DocumentImportStructureSummary copyWithQuality(List<String> qualitySignals) {
    return DocumentImportStructureSummary(
      pageCount: pageCount,
      paragraphCount: paragraphCount,
      headingCount: headingCount,
      listItemCount: listItemCount,
      tableCount: tableCount,
      headings: headings,
      qualitySignals: qualitySignals,
      likelyScanned: likelyScanned,
    );
  }
}

class _StructuredSummaryResult {
  static final invalid = _StructuredSummaryResult(
    const DocumentImportStructureSummary.empty(),
  );

  final DocumentImportStructureSummary summary;

  _StructuredSummaryResult(this.summary);
}
