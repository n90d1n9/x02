import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/document_metadata.dart';
import 'package:ky_docs/docx/services/document_metadata_service.dart';

void main() {
  group('DocumentMetadataService', () {
    const service = DocumentMetadataService();

    final createdAt = DateTime(2026);
    final modifiedAt = DateTime(2026, 1, 2);

    DocumentMetadata metadata({
      String folderId = 'folder-1',
      List<String> tags = const ['draft'],
      bool isFavorite = false,
    }) {
      return DocumentMetadata(
        id: 'doc-1',
        title: 'Proposal',
        createdAt: createdAt,
        modifiedAt: modifiedAt,
        tags: tags,
        folderId: folderId,
        isFavorite: isFavorite,
      );
    }

    test('updates title and toggles favorite state', () {
      final renamed = service.updateTitle(metadata(), 'Updated Proposal');
      final favorite = service.toggleFavorite(renamed);

      expect(renamed.title, 'Updated Proposal');
      expect(favorite.isFavorite, isTrue);
    });

    test('moves metadata to a folder and clears folder assignment', () {
      final moved = service.moveToFolder(metadata(), 'folder-2');
      final cleared = service.moveToFolder(moved, null);

      expect(moved.folderId, 'folder-2');
      expect(cleared.folderId, isNull);
    });

    test('adds trimmed unique tags and ignores empty duplicates', () {
      final first = service.addTag(metadata(), ' review ');
      final duplicate = service.addTag(first, 'review');
      final empty = service.addTag(first, '   ');

      expect(first.tags, ['draft', 'review']);
      expect(duplicate, same(first));
      expect(empty, same(first));
    });

    test('removes matching tags', () {
      final updated = service.removeTag(
        metadata(tags: const ['draft', 'review']),
        'draft',
      );

      expect(updated.tags, ['review']);
    });

    test('builds duplicate metadata with new identity and timestamps', () {
      final timestamp = DateTime(2026, 2, 3, 4, 5);
      final duplicated = service.duplicateMetadata(
        metadata: metadata(isFavorite: true),
        newId: 'doc-2',
        timestamp: timestamp,
      );

      expect(duplicated.id, 'doc-2');
      expect(duplicated.title, 'Proposal (Copy)');
      expect(duplicated.createdAt, timestamp);
      expect(duplicated.modifiedAt, timestamp);
      expect(duplicated.tags, ['draft']);
      expect(duplicated.folderId, 'folder-1');
      expect(duplicated.isFavorite, isTrue);
    });
  });
}
