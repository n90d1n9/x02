import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:ky_docs/docx/models/document_metadata.dart';
import 'package:ky_docs/docx/models/document_state.dart';
import 'package:ky_docs/docx/services/document_state_mutation_service.dart';

void main() {
  group('DocumentStateMutationService', () {
    const service = DocumentStateMutationService();

    DocumentState state({bool hasUnsavedChanges = false}) {
      final controller = quill.QuillController.basic();
      addTearDown(controller.dispose);

      return DocumentState(
        controller: controller,
        metadata: DocumentMetadata(
          id: 'doc-1',
          title: 'Proposal',
          createdAt: DateTime(2026),
          modifiedAt: DateTime(2026, 1, 2),
        ),
        hasUnsavedChanges: hasUnsavedChanges,
      );
    }

    test('marks updated state as changed', () {
      final changed = service.markChanged(
        state(),
        (current) => current.copyWith(totalPages: 4),
      );

      expect(changed.totalPages, 4);
      expect(changed.hasUnsavedChanges, isTrue);
    });

    test('dirty policy wins over updater supplied clean state', () {
      final changed = service.markChanged(
        state(hasUnsavedChanges: true),
        (current) => current.copyWith(hasUnsavedChanges: false),
      );

      expect(changed.hasUnsavedChanges, isTrue);
    });
  });
}
