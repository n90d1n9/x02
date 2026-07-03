import '../models/document_metadata.dart';
import '../models/document_template.dart';

typedef DocumentCreationIdProvider = String Function();
typedef DocumentCreationClock = DateTime Function();

class DocumentDraft {
  final String content;
  final DocumentMetadata metadata;
  final bool hasUnsavedChanges;

  const DocumentDraft({
    required this.content,
    required this.metadata,
    required this.hasUnsavedChanges,
  });
}

class DocumentCreationService {
  static const untitledTitle = 'Untitled Document';

  final DocumentCreationIdProvider createId;
  final DocumentCreationClock now;

  const DocumentCreationService({
    required this.createId,
    this.now = DateTime.now,
  });

  DocumentDraft blank() {
    return _draft(title: untitledTitle, content: '', hasUnsavedChanges: false);
  }

  DocumentDraft fromTemplate(DocumentTemplate template) {
    return _draft(
      title: template.name,
      content: template.content,
      hasUnsavedChanges: template.content.isNotEmpty,
    );
  }

  DocumentDraft imported({required String title, required String content}) {
    return _draft(title: title, content: content, hasUnsavedChanges: true);
  }

  DocumentDraft _draft({
    required String title,
    required String content,
    required bool hasUnsavedChanges,
  }) {
    final timestamp = now();
    return DocumentDraft(
      content: content,
      metadata: DocumentMetadata(
        id: createId(),
        title: title,
        createdAt: timestamp,
        lastModified: timestamp,
      ),
      hasUnsavedChanges: hasUnsavedChanges,
    );
  }
}
