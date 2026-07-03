import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/document_change.dart';
import 'package:ky_docs/docx/services/document_track_changes_service.dart';

void main() {
  group('DocumentTrackChangesService', () {
    final timestamp = DateTime(2026, 1, 2, 9, 30);
    final service = DocumentTrackChangesService(now: () => timestamp);

    test('creates replacement suggestions from selected text', () {
      final changes = service.proposeChange(
        currentChanges: const [],
        id: 'change-1',
        userId: 'local',
        userName: 'You',
        offset: 12,
        originalText: 'rough copy',
        replacementText: ' polished copy ',
      );

      expect(changes, hasLength(1));
      expect(changes.single.id, 'change-1');
      expect(changes.single.changeType, 'replace');
      expect(changes.single.offset, 12);
      expect(changes.single.length, 10);
      expect(changes.single.originalText, 'rough copy');
      expect(changes.single.replacementText, 'polished copy');
      expect(changes.single.timestamp, timestamp);
      expect(changes.single.isPending, isTrue);
    });

    test('creates insertion suggestions from a collapsed selection', () {
      final changes = service.proposeChange(
        currentChanges: const [],
        id: 'change-1',
        userId: 'local',
        userName: 'You',
        offset: 4,
        originalText: '',
        replacementText: 'new text',
      );

      expect(changes.single.changeType, 'insert');
      expect(changes.single.length, 0);
      expect(changes.single.originalText, isNull);
      expect(changes.single.replacementText, 'new text');
    });

    test('ignores empty or unchanged suggestions', () {
      final existing = [
        DocumentChange(
          id: 'change-1',
          userId: 'local',
          userName: 'You',
          changeType: 'replace',
          offset: 0,
          length: 4,
          originalText: 'copy',
          data: 'draft',
          timestamp: timestamp,
        ),
      ];

      final empty = service.proposeChange(
        currentChanges: existing,
        id: 'change-2',
        userId: 'local',
        userName: 'You',
        offset: 0,
        originalText: 'copy',
        replacementText: ' ',
      );
      final unchanged = service.proposeChange(
        currentChanges: existing,
        id: 'change-3',
        userId: 'local',
        userName: 'You',
        offset: 0,
        originalText: 'copy',
        replacementText: 'copy',
      );

      expect(identical(empty, existing), isTrue);
      expect(identical(unchanged, existing), isTrue);
    });

    test('accepts, rejects, and deletes suggestions immutably', () {
      final changes = [
        DocumentChange(
          id: 'change-1',
          userId: 'local',
          userName: 'You',
          changeType: 'replace',
          offset: 0,
          length: 4,
          originalText: 'copy',
          data: 'draft',
          timestamp: timestamp,
        ),
      ];

      final accepted = service.acceptChange(
        currentChanges: changes,
        id: 'change-1',
      );
      final rejected = service.rejectChange(
        currentChanges: accepted,
        id: 'change-1',
      );
      final deleted = service.deleteChange(
        currentChanges: rejected,
        id: 'change-1',
      );

      expect(changes.single.status, DocumentChangeStatus.pending);
      expect(accepted.single.status, DocumentChangeStatus.accepted);
      expect(rejected.single.status, DocumentChangeStatus.rejected);
      expect(deleted, isEmpty);
    });
  });
}
