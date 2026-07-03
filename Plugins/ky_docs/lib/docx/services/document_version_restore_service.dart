import '../models/document_version.dart';

class DocumentVersionRestorePlan {
  final int index;
  final DocumentVersion version;

  const DocumentVersionRestorePlan({
    required this.index,
    required this.version,
  });

  String get content => version.content;
}

class DocumentVersionRestoreService {
  const DocumentVersionRestoreService();

  DocumentVersionRestorePlan? restorePlan({
    required List<DocumentVersion> versions,
    required int index,
  }) {
    if (index < 0 || index >= versions.length) return null;

    return DocumentVersionRestorePlan(index: index, version: versions[index]);
  }
}
