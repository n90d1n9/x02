import 'package:flutter_quill/flutter_quill.dart' as quill;

import '../models/document_outline.dart';
import '../models/footnote.dart';
import '../models/page_settings.dart';
import 'document_change_service.dart';
import 'document_footnote_service.dart';
import 'document_outline_service.dart';
import 'document_reference_insertion_service.dart';

/// Coordinates document structure helpers such as outline, footnotes, and pages.
class DocumentStructureService {
  final DocumentChangeService changeService;
  final DocumentFootnoteService footnoteService;
  final DocumentOutlineService outlineService;
  final DocumentReferenceInsertionService referenceInsertionService;

  const DocumentStructureService({
    this.changeService = const DocumentChangeService(),
    this.footnoteService = const DocumentFootnoteService(),
    this.outlineService = const DocumentOutlineService(),
    this.referenceInsertionService = const DocumentReferenceInsertionService(),
  });

  FootnoteInsertion addFootnote({
    required quill.QuillController controller,
    required List<Footnote> currentFootnotes,
    required String id,
    required String text,
  }) {
    final offset = referenceInsertionService.selectionOffset(controller);
    final insertion = footnoteService.addFootnote(
      currentFootnotes: currentFootnotes,
      id: id,
      text: text,
      offset: offset,
    );

    referenceInsertionService.insertAtOffset(
      controller: controller,
      offset: offset,
      reference: insertion.reference,
    );
    return insertion;
  }

  List<Footnote> updateFootnote({
    required List<Footnote> currentFootnotes,
    required String id,
    required String text,
  }) {
    return footnoteService.updateFootnote(
      currentFootnotes: currentFootnotes,
      id: id,
      text: text,
    );
  }

  List<Footnote> deleteFootnote({
    required List<Footnote> currentFootnotes,
    required String id,
  }) {
    return footnoteService.deleteFootnote(
      currentFootnotes: currentFootnotes,
      id: id,
    );
  }

  List<DocumentOutline> generateOutline({
    required quill.QuillController controller,
    required DocumentOutlineIdFactory createId,
  }) {
    return outlineService.generateOutline(
      text: controller.document.toPlainText(),
      createId: createId,
    );
  }

  int estimateTotalPages({
    required quill.QuillController controller,
    required PageSettings pageSettings,
  }) {
    return changeService.estimateTotalPages(
      text: controller.document.toPlainText(),
      pageSettings: pageSettings,
    );
  }

  int normalizePageCount(int totalPages) {
    return totalPages.clamp(1, 9999).toInt();
  }

  int normalizePageNumber(int pageNumber, int totalPages) {
    final pageCount = normalizePageCount(totalPages);
    return pageNumber.clamp(1, pageCount).toInt();
  }
}
