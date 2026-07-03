import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/ky_docs.dart';
import 'package:ky_office_core/ky_office_core.dart';
import 'package:ky_docs/docx/models/footnote.dart';
import 'package:ky_docs/docx/models/page_settings.dart';
import 'package:ky_docs/docx/services/document_footnote_service.dart';
import 'package:ky_docs/docx/services/document_outline_service.dart';
import 'package:ky_docs/docx/services/document_pagination_service.dart';

void main() {
  test('exposes Office family product metadata', () {
    expect(kyDocsOfficeProduct.id, 'docs');
    expect(kyDocsOfficeProduct.familyName, 'Kaysir Office');
    expect(kyDocsOfficeProduct.kind, KyOfficeProductKind.document);
    expect(kyDocsOfficeProduct.supports('analyze'), isTrue);
  });

  test('ky docs exposes stable workspace surfaces', () {
    expect(KyDocsSurfaceCatalog.primary, hasLength(4));
    expect(KyDocsSurface.home.label, 'Home');
    expect(KyDocsSurface.wordEditor.opensEditor, isTrue);
    expect(KyDocsSurface.liveDocs.opensEditor, isTrue);
    expect(KyDocsSurface.library.opensEditor, isFalse);
  });

  group('DocumentPaginationService', () {
    const service = DocumentPaginationService();

    test('estimates page count from plain text length', () {
      expect(
        service.estimateTotalPages(
          text: '',
          pageSettings: const PageSettings(),
        ),
        1,
      );

      final twoPageText = List.filled(80 * 35, 'a').join();
      expect(
        service.estimateTotalPages(
          text: twoPageText,
          pageSettings: const PageSettings(),
        ),
        2,
      );
    });

    test('stays bounded for cramped and very long documents', () {
      final crampedText = List.filled(160, 'a').join();
      expect(
        service.estimateTotalPages(
          text: crampedText,
          pageSettings: const PageSettings(
            margins: EdgeInsets.symmetric(vertical: 600),
          ),
        ),
        greaterThanOrEqualTo(1),
      );

      final longText = List.filled(80 * 1000, 'a').join();
      expect(
        const DocumentPaginationService(maxPages: 3).estimateTotalPages(
          text: longText,
          pageSettings: const PageSettings(),
        ),
        3,
      );
    });
  });

  group('DocumentFootnoteService', () {
    const service = DocumentFootnoteService();

    test('adds a sequential footnote and exposes its document reference', () {
      final insertion = service.addFootnote(
        currentFootnotes: const [
          Footnote(id: 'fn-1', number: 1, text: 'First', offset: 4),
        ],
        id: 'fn-2',
        text: 'Second',
        offset: 12,
      );

      expect(insertion.reference, '[2]');
      expect(insertion.footnote.number, 2);
      expect(insertion.footnote.offset, 12);
      expect(insertion.footnotes, hasLength(2));
    });

    test('updates only the matching footnote text', () {
      final footnotes = service.updateFootnote(
        currentFootnotes: const [
          Footnote(id: 'fn-1', number: 1, text: 'First', offset: 4),
          Footnote(id: 'fn-2', number: 2, text: 'Second', offset: 12),
        ],
        id: 'fn-2',
        text: 'Updated second',
      );

      expect(footnotes[0].text, 'First');
      expect(footnotes[1].text, 'Updated second');
      expect(footnotes[1].number, 2);
    });

    test('deletes and renumbers remaining footnotes', () {
      final footnotes = service.deleteFootnote(
        currentFootnotes: const [
          Footnote(id: 'fn-1', number: 1, text: 'First', offset: 4),
          Footnote(id: 'fn-2', number: 2, text: 'Second', offset: 12),
          Footnote(id: 'fn-3', number: 3, text: 'Third', offset: 20),
        ],
        id: 'fn-2',
      );

      expect(footnotes.map((footnote) => footnote.id), ['fn-1', 'fn-3']);
      expect(footnotes.map((footnote) => footnote.number), [1, 2]);
      expect(footnotes.last.text, 'Third');
    });
  });

  group('DocumentOutlineService', () {
    const service = DocumentOutlineService();

    test('detects markdown headings with deterministic ids', () {
      var id = 0;
      final outline = service.generateOutline(
        text: '# Title\nBody copy\n## Section',
        createId: () => 'outline-${++id}',
      );

      expect(outline.map((item) => item.id), ['outline-1', 'outline-2']);
      expect(outline.map((item) => item.title), ['Title', 'Section']);
      expect(outline.map((item) => item.level), [1, 2]);
      expect(outline.map((item) => item.offset), [0, 18]);
    });

    test('detects all-caps headings and ignores regular paragraphs', () {
      final outline = service.generateOutline(
        text: 'EXECUTIVE SUMMARY\nThis is regular copy\nNEXT STEPS',
        createId: () => 'outline-id',
      );

      expect(outline.map((item) => item.title), [
        'EXECUTIVE SUMMARY',
        'NEXT STEPS',
      ]);
      expect(outline.map((item) => item.level), [1, 1]);
    });

    test('ignores invalid markdown heading markers', () {
      final outline = service.generateOutline(
        text: '#Missing space\n####### Too deep\n# Valid',
        createId: () => 'outline-id',
      );

      expect(outline.map((item) => item.title), ['Valid']);
    });
  });
}
