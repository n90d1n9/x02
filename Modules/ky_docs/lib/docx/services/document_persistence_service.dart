import '../models/cloud_sync_service.dart';
import '../models/document_metadata.dart';
import '../models/document_storage_service.dart';
import '../models/document_version.dart';
import 'document_metadata_service.dart';

typedef DocumentIdProvider = String Function();
typedef DocumentClock = DateTime Function();
typedef SyncStartedCallback = void Function();

class DocumentSaveResult {
  final List<DocumentVersion> versions;
  final DateTime lastSyncTime;

  const DocumentSaveResult({
    required this.versions,
    required this.lastSyncTime,
  });

  int get currentVersionIndex => versions.length - 1;
}

class LoadedDocument {
  final String content;
  final DocumentMetadata metadata;
  final List<DocumentVersion> versions;

  const LoadedDocument({
    required this.content,
    required this.metadata,
    required this.versions,
  });

  int get currentVersionIndex => versions.isEmpty ? -1 : versions.length - 1;
}

class DuplicatedDocument {
  final String content;
  final DocumentMetadata metadata;

  const DuplicatedDocument({required this.content, required this.metadata});
}

class DocumentPersistenceService {
  final DocumentStorageService storage;
  final CloudSyncService cloudSync;
  final DocumentMetadataService metadataService;
  final DocumentIdProvider createId;
  final DocumentClock now;

  const DocumentPersistenceService({
    required this.storage,
    required this.cloudSync,
    this.metadataService = const DocumentMetadataService(),
    required this.createId,
    this.now = DateTime.now,
  });

  Future<void> initialize() {
    return storage.initialize();
  }

  Future<DocumentSaveResult> save({
    required String content,
    required DocumentMetadata metadata,
    required List<DocumentVersion> existingVersions,
    SyncStartedCallback? onSyncStarted,
  }) async {
    await storage.saveDocument(metadata.id, content, metadata);

    final timestamp = now();
    final versions = [
      ...existingVersions,
      DocumentVersion(
        id: createId(),
        timestamp: timestamp,
        content: content,
        description: 'Saved at ${timestamp.toLocal()}',
        title: '',
        author: '',
      ),
    ];
    await storage.saveVersions(metadata.id, versions);

    onSyncStarted?.call();
    await cloudSync.syncDocument(metadata.id, content, metadata);

    return DocumentSaveResult(versions: versions, lastSyncTime: now());
  }

  Future<LoadedDocument> load(String id) async {
    final content = await storage.loadDocument(id);
    final metadata = await storage.loadMetadata(id);
    final versions = await storage.loadVersions(id);

    if (content == null || metadata == null) {
      throw Exception('Document not found');
    }

    return LoadedDocument(
      content: content,
      metadata: metadata,
      versions: versions,
    );
  }

  Future<DuplicatedDocument> duplicate({
    required String content,
    required DocumentMetadata metadata,
  }) async {
    final duplicatedMetadata = metadataService.duplicateMetadata(
      metadata: metadata,
      newId: createId(),
      timestamp: now(),
    );

    await storage.saveDocument(
      duplicatedMetadata.id,
      content,
      duplicatedMetadata,
    );

    return DuplicatedDocument(content: content, metadata: duplicatedMetadata);
  }

  Future<void> delete(String id) {
    return storage.deleteDocument(id);
  }
}
