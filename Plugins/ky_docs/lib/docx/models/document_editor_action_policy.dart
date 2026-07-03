import 'document_editing_mode.dart';

/// Defines which editor actions are available for the active editing mode.
class DocumentEditorActionPolicy {
  final DocumentEditingMode editingMode;

  const DocumentEditorActionPolicy({required this.editingMode});

  bool get canMutateDocument {
    return editingMode != DocumentEditingMode.viewing;
  }

  bool get canUseAIAssistant {
    return canMutateDocument;
  }

  bool get canInsertContent {
    return canMutateDocument;
  }

  bool get canImportContent {
    return canMutateDocument;
  }

  bool get canEditMetadata {
    return canMutateDocument;
  }

  String get lockedMutationReason {
    return 'Switch to Editing or Suggesting mode to change the document';
  }
}
