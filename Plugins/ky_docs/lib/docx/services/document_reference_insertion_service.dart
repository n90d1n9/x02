import 'package:flutter_quill/flutter_quill.dart' as quill;

class DocumentReferenceInsertionResult {
  final int offset;
  final String reference;

  const DocumentReferenceInsertionResult({
    required this.offset,
    required this.reference,
  });
}

class DocumentReferenceInsertionService {
  const DocumentReferenceInsertionService();

  DocumentReferenceInsertionResult insertAtSelection({
    required quill.QuillController controller,
    required String reference,
  }) {
    final offset = selectionOffset(controller);
    controller.document.insert(offset, reference);
    return DocumentReferenceInsertionResult(
      offset: offset,
      reference: reference,
    );
  }

  DocumentReferenceInsertionResult insertAtOffset({
    required quill.QuillController controller,
    required int offset,
    required String reference,
  }) {
    final safeOffset = normalizeOffset(
      offset: offset,
      documentLength: controller.document.length,
    );
    controller.document.insert(safeOffset, reference);
    return DocumentReferenceInsertionResult(
      offset: safeOffset,
      reference: reference,
    );
  }

  int selectionOffset(quill.QuillController controller) {
    return normalizeOffset(
      offset: controller.selection.baseOffset,
      documentLength: controller.document.length,
    );
  }

  int normalizeOffset({required int offset, required int documentLength}) {
    if (offset < 0) return 0;
    if (offset > documentLength) return documentLength;
    return offset;
  }
}
