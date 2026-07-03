import '../models/document_metadata.dart';
import '../models/document_theme.dart';
import 'document_metadata_service.dart';

class DocumentPropertiesService {
  final DocumentMetadataService metadataService;

  const DocumentPropertiesService({
    this.metadataService = const DocumentMetadataService(),
  });

  DocumentMetadata updateTitle({
    required DocumentMetadata metadata,
    required String title,
  }) {
    return metadataService.updateTitle(metadata, title);
  }

  DocumentMetadata toggleFavorite(DocumentMetadata metadata) {
    return metadataService.toggleFavorite(metadata);
  }

  DocumentMetadata moveToFolder({
    required DocumentMetadata metadata,
    required String? folderId,
  }) {
    return metadataService.moveToFolder(metadata, folderId);
  }

  DocumentMetadata addTag({
    required DocumentMetadata metadata,
    required String tag,
  }) {
    return metadataService.addTag(metadata, tag);
  }

  DocumentMetadata removeTag({
    required DocumentMetadata metadata,
    required String tag,
  }) {
    return metadataService.removeTag(metadata, tag);
  }

  DocumentTheme selectTheme(DocumentTheme theme) {
    return theme;
  }
}
