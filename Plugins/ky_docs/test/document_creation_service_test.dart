import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/document_template.dart';
import 'package:ky_docs/docx/services/document_creation_service.dart';

void main() {
  group('DocumentCreationService', () {
    late int idCounter;

    setUp(() {
      idCounter = 0;
    });

    DocumentCreationService service({DateTime? now}) {
      return DocumentCreationService(
        createId: () => 'doc-${++idCounter}',
        now: () => now ?? DateTime(2026, 1, 2, 3, 4, 5),
      );
    }

    test('creates blank untitled drafts without unsaved changes', () {
      final draft = service().blank();

      expect(draft.content, isEmpty);
      expect(draft.hasUnsavedChanges, isFalse);
      expect(draft.metadata.id, 'doc-1');
      expect(draft.metadata.title, DocumentCreationService.untitledTitle);
      expect(draft.metadata.createdAt, DateTime(2026, 1, 2, 3, 4, 5));
      expect(draft.metadata.modifiedAt, DateTime(2026, 1, 2, 3, 4, 5));
    });

    test(
      'creates drafts from templates and marks populated templates dirty',
      () {
        final draft = service().fromTemplate(
          const DocumentTemplate(
            id: 'template-1',
            name: 'Project Brief',
            description: 'Brief document',
            category: 'Business',
            icon: Icons.description,
            content: 'Overview\nGoals',
          ),
        );

        expect(draft.content, 'Overview\nGoals');
        expect(draft.hasUnsavedChanges, isTrue);
        expect(draft.metadata.id, 'doc-1');
        expect(draft.metadata.title, 'Project Brief');
      },
    );

    test('keeps empty templates clean', () {
      final draft = service().fromTemplate(
        const DocumentTemplate(
          id: 'template-empty',
          name: 'Empty Template',
          description: 'No starter content',
          category: 'Blank',
          icon: Icons.article,
          content: '',
        ),
      );

      expect(draft.content, isEmpty);
      expect(draft.hasUnsavedChanges, isFalse);
    });

    test('creates imported drafts with source title and dirty state', () {
      final draft = service(
        now: DateTime(2026, 2, 3),
      ).imported(title: 'Imported Contract', content: 'Imported body');

      expect(draft.content, 'Imported body');
      expect(draft.hasUnsavedChanges, isTrue);
      expect(draft.metadata.id, 'doc-1');
      expect(draft.metadata.title, 'Imported Contract');
      expect(draft.metadata.createdAt, DateTime(2026, 2, 3));
      expect(draft.metadata.modifiedAt, DateTime(2026, 2, 3));
    });
  });
}
