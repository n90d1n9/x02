import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/services/document_controller_factory.dart';

void main() {
  group('DocumentControllerFactory', () {
    const factory = DocumentControllerFactory();

    test('creates blank and plain text controllers', () {
      final blank = factory.createBlank();
      final fromText = factory.createFromPlainText('Hello world');

      addTearDown(blank.dispose);
      addTearDown(fromText.dispose);

      expect(blank.document.toPlainText().trim(), isEmpty);
      expect(fromText.document.toPlainText(), startsWith('Hello world'));
    });

    test('serializes and restores controller delta json', () {
      final source = factory.createFromPlainText('First line\nSecond line');
      addTearDown(source.dispose);

      final encoded = factory.encodeDelta(source);
      final restored = factory.createFromDeltaJson(encoded);
      addTearDown(restored.dispose);

      expect(jsonDecode(encoded), isA<List<dynamic>>());
      expect(restored.document.toPlainText(), source.document.toPlainText());
      expect(restored.selection.baseOffset, 0);
    });

    test('creates controllers from Waraq docs_engine JSON', () {
      final controller = factory.createFromWaraqDocsEngineJson(
        jsonEncode({
          'title': 'Imported',
          'blocks': [
            {
              'id': 'block-0',
              'block_type': {'Heading': 1},
              'spans': [
                {
                  'text': 'Imported heading',
                  'style': {'bold': true},
                },
              ],
            },
          ],
        }),
      );
      addTearDown(controller.dispose);

      final operations = controller.document.toDelta().toJson();
      final textOperation = operations.first;
      final lineBreak = operations.last;

      expect(controller.document.toPlainText(), 'Imported heading\n');
      expect(textOperation['attributes']['bold'], isTrue);
      expect(lineBreak['attributes']['header'], 1);
      expect(controller.selection.baseOffset, 0);
    });
  });
}
