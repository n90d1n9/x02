import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/document_metadata.dart';
import 'package:ky_docs/docx/models/document_theme.dart';
import 'package:ky_docs/docx/services/document_properties_service.dart';

void main() {
  group('DocumentPropertiesService', () {
    const service = DocumentPropertiesService();

    DocumentMetadata metadata({
      List<String> tags = const ['draft'],
      String? folderId = 'folder-1',
      bool isFavorite = false,
    }) {
      final now = DateTime(2026);
      return DocumentMetadata(
        id: 'doc-1',
        title: 'Proposal',
        createdAt: now,
        modifiedAt: now,
        tags: tags,
        folderId: folderId,
        isFavorite: isFavorite,
      );
    }

    test('updates core document metadata properties', () {
      final renamed = service.updateTitle(
        metadata: metadata(),
        title: 'Updated Proposal',
      );
      final favorite = service.toggleFavorite(renamed);

      expect(renamed.title, 'Updated Proposal');
      expect(favorite.isFavorite, isTrue);
    });

    test('moves and clears folder assignment', () {
      final moved = service.moveToFolder(
        metadata: metadata(),
        folderId: 'folder-2',
      );
      final cleared = service.moveToFolder(metadata: moved, folderId: null);

      expect(moved.folderId, 'folder-2');
      expect(cleared.folderId, isNull);
    });

    test('adds trimmed tags and preserves no-op metadata identity', () {
      final tagged = service.addTag(metadata: metadata(), tag: ' review ');
      final duplicate = service.addTag(metadata: tagged, tag: 'review');
      final empty = service.addTag(metadata: tagged, tag: '   ');

      expect(tagged.tags, ['draft', 'review']);
      expect(duplicate, same(tagged));
      expect(empty, same(tagged));
    });

    test('removes tags through the properties API', () {
      final updated = service.removeTag(
        metadata: metadata(tags: const ['draft', 'review']),
        tag: 'draft',
      );

      expect(updated.tags, ['review']);
    });

    test('selects document themes without mutating theme instances', () {
      final theme = DocumentTheme.predefinedThemes[2];

      expect(service.selectTheme(theme), same(theme));
    });
  });
}
