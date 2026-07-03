import 'dart:convert';

import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill/quill_delta.dart' as d;

import '../models/document_metadata.dart';

class WaraqQuillDocumentMapper {
  const WaraqQuillDocumentMapper();

  String toDocsEngineJson({
    required quill.Document document,
    required DocumentMetadata metadata,
  }) {
    return jsonEncode({'title': metadata.title, 'blocks': blocksFor(document)});
  }

  List<Map<String, Object?>> blocksFor(quill.Document document) {
    return blocksForDeltaJson(document.toDelta().toJson());
  }

  quill.Document fromDocsEngineJson(String json) {
    final decoded = jsonDecode(json);
    final document = decoded is Map<String, dynamic>
        ? decoded
        : const <String, dynamic>{};
    final blocks = document['blocks'];

    return quill.Document.fromDelta(
      deltaForBlocks(blocks is List ? blocks : const []),
    );
  }

  d.Delta deltaForBlocks(List<dynamic> blocks) {
    final delta = d.Delta();

    if (blocks.isEmpty) {
      delta.insert('\n');
      return delta;
    }

    for (final block in blocks) {
      if (block is! Map) continue;

      final spans = block['spans'];
      if (spans is List && spans.isNotEmpty) {
        for (final span in spans) {
          if (span is! Map) continue;

          final text = span['text'];
          if (text is! String || text.isEmpty) continue;

          delta.insert(text, _quillInlineAttributes(span['style']));
        }
      }

      delta.insert('\n', _quillBlockAttributes(block['block_type']));
    }

    if (delta.isEmpty) {
      delta.insert('\n');
    }

    return delta;
  }

  List<Map<String, Object?>> blocksForDeltaJson(List<dynamic> operations) {
    final blocks = <Map<String, Object?>>[];
    var spans = <Map<String, Object?>>[];

    for (final operation in operations) {
      if (operation is! Map) continue;

      final insert = operation['insert'];
      if (insert is! String) continue;

      final attributes = _attributesFrom(operation['attributes']);
      final segments = insert.split('\n');

      for (var index = 0; index < segments.length; index++) {
        final segment = segments[index];
        if (segment.isNotEmpty) {
          spans.add(_spanFor(segment, attributes));
        }

        if (index < segments.length - 1) {
          blocks.add(_blockFor(blocks.length, spans, attributes));
          spans = [];
        }
      }
    }

    if (spans.isNotEmpty || blocks.isEmpty) {
      blocks.add(_blockFor(blocks.length, spans, const {}));
    }

    return blocks;
  }

  Map<String, Object?> _blockFor(
    int index,
    List<Map<String, Object?>> spans,
    Map<String, Object?> attributes,
  ) {
    return {
      'id': 'block-$index',
      'block_type': _blockTypeFor(attributes),
      'spans': spans.isEmpty
          ? [_spanFor('', const {})]
          : List<Map<String, Object?>>.unmodifiable(spans),
    };
  }

  Object _blockTypeFor(Map<String, Object?> attributes) {
    final headerLevel = _intAttribute(attributes['header']);
    if (headerLevel != null) {
      return {'Heading': headerLevel.clamp(1, 6).toInt()};
    }

    if (attributes.containsKey('code-block')) {
      final language = attributes['code-block'];
      return {'CodeBlock': language is String ? language : ''};
    }

    if (_isTruthy(attributes['blockquote'])) {
      return 'Quote';
    }

    if (attributes.containsKey('list')) {
      return {'ListItem': _intAttribute(attributes['indent']) ?? 0};
    }

    return 'Paragraph';
  }

  Map<String, Object?> _spanFor(String text, Map<String, Object?> attributes) {
    return {'text': text, 'style': _styleFor(attributes)};
  }

  Map<String, Object?> _styleFor(Map<String, Object?> attributes) {
    return {
      'bold': _isTruthy(attributes['bold']),
      'italic': _isTruthy(attributes['italic']),
      'underline': _isTruthy(attributes['underline']),
      'strikethrough':
          _isTruthy(attributes['strike']) ||
          _isTruthy(attributes['strikethrough']),
      'font_family': _stringAttribute(attributes['font']),
      'font_size': _doubleAttribute(attributes['size']),
      'color': _stringAttribute(attributes['color']),
    };
  }

  Map<String, Object?> _attributesFrom(Object? value) {
    if (value is! Map) return const {};

    return {
      for (final entry in value.entries) entry.key.toString(): entry.value,
    };
  }

  bool _isTruthy(Object? value) {
    return value == true || value == 'true';
  }

  int? _intAttribute(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  double? _doubleAttribute(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  String? _stringAttribute(Object? value) {
    return value is String && value.isNotEmpty ? value : null;
  }

  Map<String, Object?>? _quillInlineAttributes(Object? style) {
    if (style is! Map) return null;

    final attributes = <String, Object?>{};

    if (_isTruthy(style['bold'])) attributes['bold'] = true;
    if (_isTruthy(style['italic'])) attributes['italic'] = true;
    if (_isTruthy(style['underline'])) attributes['underline'] = true;
    if (_isTruthy(style['strikethrough'])) attributes['strike'] = true;

    final fontFamily = _stringAttribute(style['font_family']);
    if (fontFamily != null) attributes['font'] = fontFamily;

    final fontSize = style['font_size'];
    if (fontSize is num || fontSize is String) {
      attributes['size'] = fontSize;
    }

    final color = _stringAttribute(style['color']);
    if (color != null) attributes['color'] = color;

    return attributes.isEmpty ? null : attributes;
  }

  Map<String, Object?>? _quillBlockAttributes(Object? blockType) {
    final attributes = <String, Object?>{};

    if (blockType == 'Quote') {
      attributes['blockquote'] = true;
    } else if (blockType is Map) {
      if (blockType.containsKey('Heading')) {
        final level = _intAttribute(blockType['Heading']);
        if (level != null) attributes['header'] = level.clamp(1, 6).toInt();
      } else if (blockType.containsKey('ListItem')) {
        final indent = _intAttribute(blockType['ListItem']) ?? 0;
        attributes['list'] = 'bullet';
        if (indent > 0) attributes['indent'] = indent;
      } else if (blockType.containsKey('CodeBlock')) {
        final language = blockType['CodeBlock'];
        attributes['code-block'] = language is String && language.isNotEmpty
            ? language
            : true;
      }
    }

    return attributes.isEmpty ? null : attributes;
  }
}
