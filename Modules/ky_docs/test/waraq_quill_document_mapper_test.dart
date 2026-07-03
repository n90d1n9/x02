import 'dart:convert';

import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill/quill_delta.dart' as d;
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/document_metadata.dart';
import 'package:ky_docs/docx/services/waraq_quill_document_mapper.dart';

void main() {
  group('WaraqQuillDocumentMapper', () {
    const mapper = WaraqQuillDocumentMapper();

    test('maps Quill headings and inline styles to docs_engine JSON', () {
      final document = _documentFromDelta(
        d.Delta()
          ..insert('Proposal', {'bold': true})
          ..insert('\n', {'header': 1})
          ..insert('A focused ')
          ..insert('launch', {
            'italic': true,
            'underline': true,
            'color': '#0f766e',
            'font': 'Inter',
            'size': 16,
          })
          ..insert('\n'),
      );

      final json = mapper.toDocsEngineJson(
        document: document,
        metadata: _metadata(title: 'Roadmap'),
      );
      final output = jsonDecode(json) as Map<String, dynamic>;
      final blocks = output['blocks'] as List<dynamic>;
      final heading = blocks.first as Map<String, dynamic>;
      final body = blocks.last as Map<String, dynamic>;
      final bodySpans = body['spans'] as List<dynamic>;
      final styledSpan = bodySpans.last as Map<String, dynamic>;
      final style = styledSpan['style'] as Map<String, dynamic>;

      expect(output['title'], 'Roadmap');
      expect(heading['block_type'], {'Heading': 1});
      expect(heading['spans'].single['style']['bold'], isTrue);
      expect(body['block_type'], 'Paragraph');
      expect(styledSpan['text'], 'launch');
      expect(style['italic'], isTrue);
      expect(style['underline'], isTrue);
      expect(style['color'], '#0f766e');
      expect(style['font_family'], 'Inter');
      expect(style['font_size'], 16);
    });

    test('maps lists, quotes, and code blocks to Waraq block types', () {
      final document = _documentFromDelta(
        d.Delta()
          ..insert('Nested item')
          ..insert('\n', {'list': 'bullet', 'indent': 2})
          ..insert('Quoted line')
          ..insert('\n', {'blockquote': true})
          ..insert('print("ok");')
          ..insert('\n', {'code-block': 'dart'}),
      );

      final blocks = mapper.blocksFor(document);
      final codeSpans = blocks[2]['spans'] as List<Map<String, Object?>>;

      expect(blocks[0]['block_type'], {'ListItem': 2});
      expect(blocks[1]['block_type'], 'Quote');
      expect(blocks[2]['block_type'], {'CodeBlock': 'dart'});
      expect(codeSpans.single['text'], 'print("ok");');
    });

    test('keeps an empty paragraph for blank documents', () {
      final blocks = mapper.blocksFor(quill.Document());
      final spans = blocks.single['spans'] as List<Map<String, Object?>>;

      expect(blocks, hasLength(1));
      expect(blocks.single['block_type'], 'Paragraph');
      expect(spans.single['text'], '');
    });

    test('restores docs_engine JSON into Quill delta attributes', () {
      final document = mapper.fromDocsEngineJson(
        jsonEncode({
          'title': 'Imported',
          'blocks': [
            {
              'id': 'block-0',
              'block_type': {'Heading': 2},
              'spans': [
                {
                  'text': 'Launch Plan',
                  'style': {
                    'bold': true,
                    'italic': false,
                    'underline': false,
                    'strikethrough': false,
                    'font_family': null,
                    'font_size': null,
                    'color': null,
                  },
                },
              ],
            },
            {
              'id': 'block-1',
              'block_type': 'Quote',
              'spans': [
                {
                  'text': 'Stay focused',
                  'style': {
                    'bold': false,
                    'italic': true,
                    'underline': true,
                    'strikethrough': true,
                    'font_family': 'Inter',
                    'font_size': 15,
                    'color': '#111827',
                  },
                },
              ],
            },
            {
              'id': 'block-2',
              'block_type': {'ListItem': 2},
              'spans': [
                {'text': 'Nested item', 'style': {}},
              ],
            },
            {
              'id': 'block-3',
              'block_type': {'CodeBlock': 'dart'},
              'spans': [
                {'text': 'print("ok");', 'style': {}},
              ],
            },
          ],
        }),
      );

      final operations = document.toDelta().toJson();
      final headingText = operations[0];
      final headingBreak = operations[1];
      final quoteText = operations[2];
      final quoteBreak = operations[3];
      final listBreak = operations[5];
      final codeBreak = operations[7];

      expect(
        document.toPlainText(),
        'Launch Plan\nStay focused\nNested item\nprint("ok");\n',
      );
      expect(headingText['attributes']['bold'], isTrue);
      expect(headingBreak['attributes']['header'], 2);
      expect(quoteText['attributes']['italic'], isTrue);
      expect(quoteText['attributes']['underline'], isTrue);
      expect(quoteText['attributes']['strike'], isTrue);
      expect(quoteText['attributes']['font'], 'Inter');
      expect(quoteText['attributes']['size'], 15);
      expect(quoteText['attributes']['color'], '#111827');
      expect(quoteBreak['attributes']['blockquote'], isTrue);
      expect(listBreak['attributes']['list'], 'bullet');
      expect(listBreak['attributes']['indent'], 2);
      expect(codeBreak['attributes']['code-block'], 'dart');
    });
  });
}

quill.Document _documentFromDelta(d.Delta delta) {
  return quill.Document.fromDelta(delta);
}

DocumentMetadata _metadata({String title = 'Document'}) {
  return DocumentMetadata(
    id: 'doc-1',
    title: title,
    createdAt: DateTime(2026),
    modifiedAt: DateTime(2026, 1, 2),
  );
}
