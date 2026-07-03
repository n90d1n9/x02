import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/cloud_sync_service.dart';
import 'package:ky_docs/docx/models/document_metadata.dart';
import 'package:ky_docs/docx/models/document_storage_service.dart';
import 'package:ky_docs/docx/models/document_version.dart';
import 'package:ky_docs/docx/services/document_persistence_service.dart';

void main() {
  group('DocumentPersistenceService', () {
    late _FakeStorage storage;
    late _FakeCloudSync cloudSync;
    late int idCounter;

    setUp(() {
      storage = _FakeStorage();
      cloudSync = _FakeCloudSync();
      idCounter = 0;
    });

    DocumentPersistenceService service({DateTime? now}) {
      return DocumentPersistenceService(
        storage: storage,
        cloudSync: cloudSync,
        createId: () => 'id-${++idCounter}',
        now: () => now ?? DateTime(2026, 1, 2, 3, 4, 5),
      );
    }

    DocumentMetadata metadata({
      String id = 'doc-1',
      String title = 'Proposal',
    }) {
      return DocumentMetadata(
        id: id,
        title: title,
        createdAt: DateTime(2026),
        modifiedAt: DateTime(2026, 1, 2),
      );
    }

    test('initializes the backing storage service', () async {
      await service().initialize();

      expect(storage.initialized, isTrue);
    });

    test('saves content, appends a version, and syncs the document', () async {
      var syncStarted = false;

      final result = await service().save(
        content: 'delta-json',
        metadata: metadata(),
        existingVersions: [
          DocumentVersion(
            id: 'existing',
            timestamp: DateTime(2026),
            content: 'old',
          ),
        ],
        onSyncStarted: () => syncStarted = true,
      );

      expect(storage.documents['doc-1'], 'delta-json');
      expect(storage.metadataById['doc-1']?.title, 'Proposal');
      expect(storage.versionsById['doc-1'], hasLength(2));
      expect(result.versions.last.id, 'id-1');
      expect(result.versions.last.content, 'delta-json');
      expect(result.currentVersionIndex, 1);
      expect(result.lastSyncTime, DateTime(2026, 1, 2, 3, 4, 5));
      expect(syncStarted, isTrue);
      expect(cloudSync.synced.single.id, 'doc-1');
      expect(cloudSync.synced.single.content, 'delta-json');
    });

    test('loads content, metadata, and version history', () async {
      storage.documents['doc-1'] = 'delta-json';
      storage.metadataById['doc-1'] = metadata();
      storage.versionsById['doc-1'] = [
        DocumentVersion(
          id: 'version-1',
          timestamp: DateTime(2026),
          content: 'delta-json',
        ),
      ];

      final loaded = await service().load('doc-1');

      expect(loaded.content, 'delta-json');
      expect(loaded.metadata.title, 'Proposal');
      expect(loaded.currentVersionIndex, 0);
    });

    test('throws when a requested document is incomplete', () async {
      storage.documents['doc-1'] = 'delta-json';

      expect(service().load('doc-1'), throwsException);
    });

    test('duplicates metadata and stores the copied content', () async {
      final duplicated = await service(
        now: DateTime(2026, 2, 3),
      ).duplicate(content: 'delta-json', metadata: metadata());

      expect(duplicated.content, 'delta-json');
      expect(duplicated.metadata.id, 'id-1');
      expect(duplicated.metadata.title, 'Proposal (Copy)');
      expect(duplicated.metadata.createdAt, DateTime(2026, 2, 3));
      expect(storage.documents['id-1'], 'delta-json');
      expect(storage.metadataById['id-1']?.title, 'Proposal (Copy)');
    });

    test('deletes documents through storage', () async {
      storage.documents['doc-1'] = 'delta-json';
      storage.metadataById['doc-1'] = metadata();

      await service().delete('doc-1');

      expect(storage.documents, isNot(contains('doc-1')));
      expect(storage.metadataById, isNot(contains('doc-1')));
    });
  });
}

class _FakeStorage extends DocumentStorageService {
  final documents = <String, String>{};
  final metadataById = <String, DocumentMetadata>{};
  final versionsById = <String, List<DocumentVersion>>{};
  var initialized = false;

  @override
  Future<void> initialize() async {
    initialized = true;
  }

  @override
  Future<void> saveDocument(
    String id,
    String content,
    DocumentMetadata metadata,
  ) async {
    documents[id] = content;
    metadataById[id] = metadata;
  }

  @override
  Future<String?> loadDocument(String id) async {
    return documents[id];
  }

  @override
  Future<DocumentMetadata?> loadMetadata(String id) async {
    return metadataById[id];
  }

  @override
  Future<void> saveVersions(
    String documentId,
    List<DocumentVersion> versions,
  ) async {
    versionsById[documentId] = versions;
  }

  @override
  Future<List<DocumentVersion>> loadVersions(String documentId) async {
    return versionsById[documentId] ?? [];
  }

  @override
  Future<void> deleteDocument(String id) async {
    documents.remove(id);
    metadataById.remove(id);
    versionsById.remove(id);
  }
}

class _SyncedDocument {
  final String id;
  final String content;
  final DocumentMetadata metadata;

  const _SyncedDocument({
    required this.id,
    required this.content,
    required this.metadata,
  });
}

class _FakeCloudSync extends CloudSyncService {
  final synced = <_SyncedDocument>[];

  @override
  Future<void> syncDocument(
    String docId,
    String content,
    DocumentMetadata metadata,
  ) async {
    synced.add(
      _SyncedDocument(id: docId, content: content, metadata: metadata),
    );
  }
}
