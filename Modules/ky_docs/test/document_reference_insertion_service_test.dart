import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:ky_docs/docx/services/document_reference_insertion_service.dart';

void main() {
  group('DocumentReferenceInsertionService', () {
    const service = DocumentReferenceInsertionService();

    quill.QuillController controllerWithText(String text) {
      final controller = quill.QuillController.basic();
      controller.document.insert(0, text);
      addTearDown(controller.dispose);
      return controller;
    }

    test('inserts references at the current selection', () {
      final controller = controllerWithText('Hello world');
      controller.updateSelection(
        const TextSelection.collapsed(offset: 5),
        quill.ChangeSource.local,
      );

      final result = service.insertAtSelection(
        controller: controller,
        reference: '[TABLE:1]',
      );

      expect(result.offset, 5);
      expect(result.reference, '[TABLE:1]');
      expect(controller.document.toPlainText(), contains('Hello[TABLE:1]'));
    });

    test('clamps invalid offsets before inserting', () {
      final controller = controllerWithText('Body');

      final result = service.insertAtOffset(
        controller: controller,
        offset: -10,
        reference: '[NOTE]',
      );

      expect(result.offset, 0);
      expect(controller.document.toPlainText(), startsWith('[NOTE]Body'));
    });

    test('normalizes selection offsets to the document range', () {
      expect(service.normalizeOffset(offset: -1, documentLength: 10), 0);
      expect(service.normalizeOffset(offset: 20, documentLength: 10), 10);
      expect(service.normalizeOffset(offset: 4, documentLength: 10), 4);
    });
  });
}
