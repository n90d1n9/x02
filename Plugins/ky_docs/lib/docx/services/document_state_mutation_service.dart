import '../models/document_state.dart';

typedef DocumentStateUpdate = DocumentState Function(DocumentState state);

class DocumentStateMutationService {
  const DocumentStateMutationService();

  DocumentState markChanged(DocumentState state, DocumentStateUpdate update) {
    return update(state).copyWith(hasUnsavedChanges: true);
  }
}
