import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/document_editor_action_policy.dart';
import 'package:ky_docs/docx/models/document_editing_mode.dart';

void main() {
  group('DocumentEditorActionPolicy', () {
    test('allows document mutation in editing and suggesting modes', () {
      const editing = DocumentEditorActionPolicy(
        editingMode: DocumentEditingMode.editing,
      );
      const suggesting = DocumentEditorActionPolicy(
        editingMode: DocumentEditingMode.suggesting,
      );

      expect(editing.canUseAIAssistant, isTrue);
      expect(editing.canInsertContent, isTrue);
      expect(editing.canImportContent, isTrue);
      expect(editing.canEditMetadata, isTrue);
      expect(suggesting.canMutateDocument, isTrue);
    });

    test('locks mutating document actions in viewing mode', () {
      const policy = DocumentEditorActionPolicy(
        editingMode: DocumentEditingMode.viewing,
      );

      expect(policy.canMutateDocument, isFalse);
      expect(policy.canUseAIAssistant, isFalse);
      expect(policy.canInsertContent, isFalse);
      expect(policy.canImportContent, isFalse);
      expect(policy.canEditMetadata, isFalse);
      expect(policy.lockedMutationReason, contains('Editing'));
    });
  });
}
