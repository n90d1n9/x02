import '../models/document_metadata.dart';

class DocumentMetadataService {
  const DocumentMetadataService();

  DocumentMetadata updateTitle(DocumentMetadata metadata, String title) {
    return metadata.copyWith(title: title);
  }

  DocumentMetadata toggleFavorite(DocumentMetadata metadata) {
    return metadata.copyWith(isFavorite: !metadata.isFavorite);
  }

  DocumentMetadata moveToFolder(DocumentMetadata metadata, String? folderId) {
    return metadata.copyWith(folderId: folderId, clearFolder: folderId == null);
  }

  DocumentMetadata addTag(DocumentMetadata metadata, String tag) {
    final normalizedTag = tag.trim();
    if (normalizedTag.isEmpty || metadata.tags.contains(normalizedTag)) {
      return metadata;
    }

    return metadata.copyWith(tags: [...metadata.tags, normalizedTag]);
  }

  DocumentMetadata removeTag(DocumentMetadata metadata, String tag) {
    return metadata.copyWith(
      tags: metadata.tags.where((currentTag) => currentTag != tag).toList(),
    );
  }

  DocumentMetadata duplicateMetadata({
    required DocumentMetadata metadata,
    required String newId,
    required DateTime timestamp,
  }) {
    return metadata.copyWith(
      id: newId,
      title: '${metadata.title} (Copy)',
      createdAt: timestamp,
      lastModified: timestamp,
    );
  }
}
