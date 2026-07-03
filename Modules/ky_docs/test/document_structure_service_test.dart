import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/footnote.dart';
import 'package:ky_docs/docx/models/page_settings.dart';
import 'package:ky_docs/docx/services/document_structure_service.dart';

void main() {
  group('DocumentStructureService', () {
    const service = DocumentStructureService();

    quill.QuillController controllerWithText(String text, {int? selection}) {
      final controller = quill.QuillController.basic();
      controller.document.insert(0, text);
      controller.updateSelection(
        TextSelection.collapsed(offset: selection ?? text.length),
        quill.ChangeSource.local,
      );
      addTearDown(controller.dispose);
      return controller;
    }

    test('adds footnotes at the current selection and inserts a marker', () {
      final controller = controllerWithText('Body copy', selection: 4);

      final insertion = service.addFootnote(
        controller: controller,
        currentFootnotes: const [],
        id: 'footnote-1',
        text: 'Reference note',
      );

      expect(insertion.footnote.number, 1);
      expect(insertion.footnote.offset, 4);
      expect(insertion.footnotes, [insertion.footnote]);
      expect(controller.document.toPlainText(), contains('Body[1] copy'));
    });

    test('updates and deletes footnotes through a single structure API', () {
      const first = Footnote(id: 'fn-1', number: 1, text: 'First', offset: 4);
      const second = Footnote(id: 'fn-2', number: 2, text: 'Second', offset: 8);

      final updated = service.updateFootnote(
        currentFootnotes: const [first, second],
        id: 'fn-2',
        text: 'Updated second',
      );
      final deleted = service.deleteFootnote(
        currentFootnotes: updated,
        id: 'fn-1',
      );

      expect(updated.last.text, 'Updated second');
      expect(deleted.single.id, 'fn-2');
      expect(deleted.single.number, 1);
    });

    test('generates outlines from the current document text', () {
      var nextId = 0;
      final controller = controllerWithText('# Title\nBody\n## Details');

      final outline = service.generateOutline(
        controller: controller,
        createId: () => 'outline-${++nextId}',
      );

      expect(outline.map((item) => item.id), ['outline-1', 'outline-2']);
      expect(outline.map((item) => item.title), ['Title', 'Details']);
      expect(outline.map((item) => item.level), [1, 2]);
    });

    test('estimates total pages using the current document and settings', () {
      final controller = controllerWithText(List.filled(80 * 35, 'a').join());

      final pages = service.estimateTotalPages(
        controller: controller,
        pageSettings: const PageSettings(),
      );

      expect(pages, 2);
    });

    test('normalizes page counts to editor bounds', () {
      expect(service.normalizePageCount(-1), 1);
      expect(service.normalizePageCount(0), 1);
      expect(service.normalizePageCount(12), 12);
      expect(service.normalizePageCount(10000), 9999);
    });

    test('normalizes selected pages to the available page range', () {
      expect(service.normalizePageNumber(-1, 5), 1);
      expect(service.normalizePageNumber(0, 5), 1);
      expect(service.normalizePageNumber(3, 5), 3);
      expect(service.normalizePageNumber(99, 5), 5);
      expect(service.normalizePageNumber(99, -1), 1);
    });
  });
}
