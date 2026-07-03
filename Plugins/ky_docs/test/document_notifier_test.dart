import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/aiaction.dart';
import 'package:ky_docs/docx/models/aiassistant_service.dart';
import 'package:ky_docs/docx/models/chart_type.dart';
import 'package:ky_docs/docx/models/cloud_sync_service.dart';
import 'package:ky_docs/docx/models/collaboration_service.dart';
import 'package:ky_docs/docx/models/collaboration_user.dart';
import 'package:ky_docs/docx/models/document_change.dart';
import 'package:ky_docs/docx/models/document_metadata.dart';
import 'package:ky_docs/docx/models/document_storage_service.dart';
import 'package:ky_docs/docx/models/document_template.dart';
import 'package:ky_docs/docx/models/document_theme.dart';
import 'package:ky_docs/docx/models/document_version.dart';
import 'package:ky_docs/docx/models/page_settings.dart';
import 'package:ky_docs/docx/models/spell_check_error.dart';
import 'package:ky_docs/docx/models/spell_check_service.dart';
import 'package:ky_docs/docx/services/docx_service.dart';
import 'package:ky_docs/docx/services/pdf_service.dart';
import 'package:ky_docs/docx/states/doc_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DocumentNotifier properties orchestration', () {
    test('updates title and favorite state through notifier metadata', () {
      final notifier = _createNotifier();

      notifier.updateTitle('Updated Proposal');
      notifier.toggleFavorite();

      expect(notifier.state.metadata.title, 'Updated Proposal');
      expect(notifier.state.metadata.isFavorite, isTrue);
      expect(notifier.state.hasUnsavedChanges, isTrue);
    });

    test('moves, tags, and untags document metadata', () {
      final notifier = _createNotifier();

      notifier.moveToFolder('folder-1');
      notifier.addTag(' review ');
      notifier.removeTag('review');
      notifier.moveToFolder(null);

      expect(notifier.state.metadata.folderId, isNull);
      expect(notifier.state.metadata.tags, isEmpty);
      expect(notifier.state.hasUnsavedChanges, isTrue);
    });

    test('ignores empty tags without dirtying a clean document', () {
      final notifier = _createNotifier();

      notifier.addTag('   ');

      expect(notifier.state.metadata.tags, isEmpty);
      expect(notifier.state.hasUnsavedChanges, isFalse);
    });

    test('applies selected document themes', () {
      final notifier = _createNotifier();
      final theme = DocumentTheme.predefinedThemes[2];

      notifier.applyTheme(theme);

      expect(notifier.state.currentTheme, same(theme));
      expect(notifier.state.hasUnsavedChanges, isTrue);
    });
  });

  group('DocumentNotifier embedded content orchestration', () {
    test('inserts tables with a document marker and mutable state', () {
      final notifier = _createNotifier();

      notifier.insertTable(2, 3);
      final table = notifier.state.tables.single;

      expect(table.rows, 2);
      expect(table.columns, 3);
      expect(_plainText(notifier), contains('[TABLE:${table.id}]'));
      expect(notifier.state.hasUnsavedChanges, isTrue);

      notifier.updateTableCell(table.id, 1, 2, 'Total');
      expect(notifier.state.tables.single.data[1][2], 'Total');

      notifier.deleteTable(table.id);
      expect(notifier.state.tables, isEmpty);
    });

    test('inserts, updates, and deletes charts through notifier state', () {
      final notifier = _createNotifier();

      notifier.insertChart(
        ChartType.bar,
        'Revenue',
        const ['Q1', 'Q2'],
        const [10, 20],
      );
      final chart = notifier.state.charts.single;

      expect(chart.title, 'Revenue');
      expect(_plainText(notifier), contains('[CHART:${chart.id}]'));

      notifier.updateChart(
        chart.id,
        'Updated revenue',
        const ['Q3'],
        const [30],
      );
      expect(notifier.state.charts.single.title, 'Updated revenue');
      expect(notifier.state.charts.single.labels, ['Q3']);
      expect(notifier.state.charts.single.values, [30]);

      notifier.deleteChart(chart.id);
      expect(notifier.state.charts, isEmpty);
    });

    test('inserts and deletes drawings with immutable image bytes', () {
      final notifier = _createNotifier();
      final imageBytes = Uint8List.fromList([1, 2, 3]);

      notifier.insertDrawing(imageBytes, 320, 180);
      imageBytes[0] = 99;
      final drawing = notifier.state.drawings.single;

      expect(drawing.imageBytes, [1, 2, 3]);
      expect(drawing.width, 320);
      expect(drawing.height, 180);
      expect(_plainText(notifier), contains('[DRAWING:${drawing.id}]'));

      notifier.deleteDrawing(drawing.id);
      expect(notifier.state.drawings, isEmpty);
    });

    test(
      'renders supported shapes as drawing state and document markers',
      () async {
        final notifier = _createNotifier();

        await notifier.insertShape('rectangle');
        final drawing = notifier.state.drawings.single;

        expect(drawing.width, 200);
        expect(drawing.height, 200);
        expect(drawing.imageBytes.take(8).toList(), [
          137,
          80,
          78,
          71,
          13,
          10,
          26,
          10,
        ]);
        expect(_plainText(notifier), contains('[DRAWING:${drawing.id}]'));
        expect(notifier.state.hasUnsavedChanges, isTrue);
      },
    );

    test('ignores unsupported shapes without dirtying the document', () async {
      final notifier = _createNotifier();

      await notifier.insertShape('hexagon');

      expect(notifier.state.drawings, isEmpty);
      expect(_plainText(notifier), isNot(contains('[DRAWING:')));
      expect(notifier.state.hasUnsavedChanges, isFalse);
    });
  });

  group('DocumentNotifier structure orchestration', () {
    test('adds, updates, and deletes footnotes through notifier state', () {
      final notifier = _createNotifier();

      notifier.addFootnote('Reference note');
      final footnote = notifier.state.footnotes.single;

      expect(footnote.number, 1);
      expect(_plainText(notifier), contains('[1]'));
      expect(notifier.state.hasUnsavedChanges, isTrue);

      notifier.updateFootnote(footnote.id, 'Updated reference');
      expect(notifier.state.footnotes.single.text, 'Updated reference');

      notifier.deleteFootnote(footnote.id);
      expect(notifier.state.footnotes, isEmpty);
    });

    test('adds, resolves, reopens, and deletes anchored comments', () {
      final notifier = _createNotifier();
      notifier.state.controller.document.insert(0, 'Draft paragraph');
      notifier.state.controller.updateSelection(
        const TextSelection(baseOffset: 0, extentOffset: 5),
        quill.ChangeSource.local,
      );

      notifier.addComment(' Clarify this claim. ');
      final comment = notifier.state.comments.single;

      expect(comment.text, 'Clarify this claim.');
      expect(comment.offset, 0);
      expect(comment.anchorText, 'Draft');
      expect(comment.isOpen, isTrue);
      expect(notifier.state.hasUnsavedChanges, isTrue);

      notifier.resolveComment(comment.id);
      expect(notifier.state.comments.single.resolved, isTrue);

      notifier.reopenComment(comment.id);
      expect(notifier.state.comments.single.resolved, isFalse);

      notifier.deleteComment(comment.id);
      expect(notifier.state.comments, isEmpty);
    });

    test('proposes, accepts, rejects, and deletes tracked changes', () {
      final notifier = _createNotifier();
      notifier.state.controller.document.insert(0, 'rough copy');
      notifier.state.controller.updateSelection(
        const TextSelection(baseOffset: 0, extentOffset: 5),
        quill.ChangeSource.local,
      );

      notifier.proposeTrackedChange('polished');
      final replacement = notifier.state.trackedChanges.single;

      expect(replacement.changeType, 'replace');
      expect(replacement.originalText, 'rough');
      expect(replacement.replacementText, 'polished');
      expect(replacement.isPending, isTrue);

      notifier.acceptTrackedChange(replacement.id);

      expect(_plainText(notifier), contains('polished copy'));
      expect(
        notifier.state.trackedChanges.single.status,
        DocumentChangeStatus.accepted,
      );

      notifier.state.controller.updateSelection(
        const TextSelection.collapsed(offset: 0),
        quill.ChangeSource.local,
      );
      notifier.proposeTrackedChange('Intro: ');
      final insertion = notifier.state.trackedChanges.last;

      expect(insertion.changeType, 'insert');
      expect(insertion.originalText, isNull);

      notifier.rejectTrackedChange(insertion.id);
      expect(
        notifier.state.trackedChanges.last.status,
        DocumentChangeStatus.rejected,
      );

      notifier.deleteTrackedChange(insertion.id);
      expect(notifier.state.trackedChanges.map((change) => change.id), [
        replacement.id,
      ]);
    });

    test('generates outline from current editor text', () {
      final notifier = _createNotifier();
      notifier.state.controller.document.insert(0, '# Title\nBody\n## Details');

      final outline = notifier.generateOutline();

      expect(outline.map((item) => item.title), ['Title', 'Details']);
      expect(outline.map((item) => item.level), [1, 2]);
    });

    test('normalizes explicit page counts and recalculates page settings', () {
      final notifier = _createNotifier();

      notifier.updatePageCount(10000);
      expect(notifier.state.totalPages, 9999);

      notifier.state.controller.document.insert(
        0,
        List.filled(80 * 35, 'a').join(),
      );
      notifier.updatePageSettings(const PageSettings());

      expect(notifier.state.totalPages, 2);
      expect(notifier.state.hasUnsavedChanges, isTrue);
    });

    test('selects pages without dirtying document content', () {
      final notifier = _createNotifier();

      notifier.updatePageCount(4);
      notifier.selectPage(3);

      expect(notifier.state.currentPage, 3);
      expect(notifier.state.hasUnsavedChanges, isFalse);

      notifier.selectPage(99);
      expect(notifier.state.currentPage, 4);

      notifier.updatePageCount(2);
      expect(notifier.state.currentPage, 2);
    });
  });

  group('DocumentNotifier lifecycle orchestration', () {
    test('creates documents from templates through notifier state', () async {
      final notifier = _createNotifier();

      await notifier.createFromTemplate(
        const DocumentTemplate(
          id: 'brief',
          name: 'Brief',
          description: 'Short brief',
          category: 'Business',
          icon: Icons.description,
          content: 'Template body',
        ),
      );

      expect(notifier.state.metadata.title, 'Brief');
      expect(notifier.state.hasUnsavedChanges, isTrue);
      expect(_plainText(notifier), contains('Template body'));

      await notifier.createNewDocument();

      expect(notifier.state.metadata.title, 'Untitled Document');
      expect(notifier.state.hasUnsavedChanges, isFalse);
      expect(_plainText(notifier).trim(), isEmpty);
    });

    test('saves, loads, duplicates, restores, and deletes documents', () async {
      final storage = _FakeStorage();
      final notifier = _createNotifier(storage: storage);
      notifier.state.controller.document.insert(0, 'Lifecycle body');

      await notifier.saveDocument();
      final savedId = notifier.state.metadata.id;

      expect(storage.documents[savedId], isNotNull);
      expect(notifier.state.hasUnsavedChanges, isFalse);
      expect(notifier.state.versions, hasLength(1));

      await notifier.duplicateDocument();

      expect(notifier.state.metadata.title, endsWith('(Copy)'));
      expect(notifier.state.hasUnsavedChanges, isFalse);
      expect(_plainText(notifier), contains('Lifecycle body'));

      await notifier.loadDocument(savedId);

      expect(notifier.state.metadata.id, savedId);
      expect(_plainText(notifier), contains('Lifecycle body'));

      notifier.restoreVersion(0);

      expect(notifier.state.currentVersionIndex, 0);
      expect(notifier.state.hasUnsavedChanges, isTrue);

      await notifier.deleteDocument(savedId);

      expect(storage.documents, isNot(contains(savedId)));
    });
  });

  group('DocumentNotifier collaboration orchestration', () {
    test('enables and disables collaboration through notifier state', () {
      final collaboration = _FakeCollaborationService();
      final notifier = _createNotifier(collaboration: collaboration);

      notifier.enableCollaboration('local', 'You');

      expect(collaboration.initializedWith, ('local', 'You'));
      expect(notifier.state.isCollaborationEnabled, isTrue);
      expect(notifier.state.collaborators.single.name, 'You');

      notifier.disableCollaboration();

      expect(collaboration.wasDisabled, isTrue);
      expect(notifier.state.isCollaborationEnabled, isFalse);
      expect(notifier.state.collaborators, isEmpty);
    });

    test('updates cursors and mock collaborators through notifier state', () {
      final notifier = _createNotifier(
        collaboration: _FakeCollaborationService(),
      );

      notifier.enableCollaboration('local', 'You');
      notifier.updateCollaboratorCursor(42);
      notifier.addMockCollaborator('Guest');

      expect(notifier.state.collaborators.first.cursorPosition, 42);
      expect(notifier.state.collaborators.map((user) => user.name), [
        'You',
        'Guest',
      ]);
      expect(notifier.state.isCollaborationEnabled, isTrue);
    });

    test('ignores cursor updates while collaboration is disabled', () {
      final notifier = _createNotifier(
        collaboration: _FakeCollaborationService(),
      );

      notifier.updateCollaboratorCursor(42);

      expect(notifier.state.isCollaborationEnabled, isFalse);
      expect(notifier.state.collaborators, isEmpty);
    });
  });

  group('DocumentNotifier spell-check orchestration', () {
    test('toggles spell check and clears errors when disabled', () {
      final notifier = _createNotifier(spellCheck: SpellCheckService());
      notifier.state.controller.document.insert(0, 'write wrte');

      notifier.toggleSpellCheck();

      expect(notifier.state.spellCheckEnabled, isTrue);
      expect(notifier.state.spellErrors, hasLength(1));
      expect(notifier.state.spellErrors.single.word, 'wrte');

      notifier.toggleSpellCheck();

      expect(notifier.state.spellCheckEnabled, isFalse);
      expect(notifier.state.spellErrors, isEmpty);
    });

    test('adds dictionary words and ignores spelling errors', () {
      final notifier = _createNotifier(spellCheck: SpellCheckService());
      notifier.state.controller.document.insert(0, 'wrte typo');

      notifier.toggleSpellCheck();
      expect(notifier.state.spellErrors.map((error) => error.word), [
        'wrte',
        'typo',
      ]);

      notifier.addWordToDictionary('wrte');
      expect(notifier.state.spellErrors.map((error) => error.word), ['typo']);

      notifier.ignoreSpellingError('typo');
      expect(notifier.state.spellErrors, isEmpty);
    });

    test('replaces spelling errors with suggestions', () {
      final notifier = _createNotifier(spellCheck: SpellCheckService());
      notifier.state.controller.document.insert(0, 'write wrte');
      notifier.toggleSpellCheck();
      final error = notifier.state.spellErrors.single;

      notifier.replaceWithSuggestion(error, 'write');

      expect(_plainText(notifier), contains('write write'));
      expect(notifier.state.spellErrors, isEmpty);
      expect(notifier.state.hasUnsavedChanges, isTrue);
    });
  });

  group('DocumentNotifier AI orchestration', () {
    test('processes selected text and stores the AI result', () async {
      final notifier = _createNotifier(
        aiService: _FakeAIAssistantService(
          process: (text, action) async {
            expect(text, 'rough');
            expect(action, AIAction.improve);
            return 'polished';
          },
        ),
      );
      notifier.state.controller.document.insert(0, 'rough draft');
      notifier.state.controller.updateSelection(
        const TextSelection(baseOffset: 0, extentOffset: 5),
        quill.ChangeSource.local,
      );

      await notifier.applyAIAction(AIAction.improve);

      expect(notifier.state.isAIProcessing, isFalse);
      expect(notifier.state.aiResult, 'polished');
      expect(notifier.state.errorMessage, isNull);
    });

    test('replaces selected text with the AI result', () async {
      final notifier = _createNotifier(
        aiService: _FakeAIAssistantService(
          process: (text, action) async => 'polished',
        ),
      );
      notifier.state.controller.document.insert(0, 'rough draft');
      notifier.state.controller.updateSelection(
        const TextSelection(baseOffset: 0, extentOffset: 5),
        quill.ChangeSource.local,
      );

      await notifier.applyAIAction(AIAction.improve);
      notifier.replaceWithAIResult();

      expect(_plainText(notifier), contains('polished draft'));
      expect(notifier.state.aiResult, isNull);
      expect(notifier.state.hasUnsavedChanges, isTrue);
    });

    test('inserts AI result at the current cursor', () async {
      final notifier = _createNotifier(
        aiService: _FakeAIAssistantService(
          process: (text, action) async => 'inserted idea',
        ),
      );
      notifier.state.controller.document.insert(0, 'hello');
      notifier.state.controller.updateSelection(
        const TextSelection.collapsed(offset: 5),
        quill.ChangeSource.local,
      );

      await notifier.applyAIAction(AIAction.continueWriting);
      notifier.insertAIResult();

      expect(_plainText(notifier), contains('hello\n\ninserted idea\n\n'));
      expect(notifier.state.aiResult, isNull);
    });

    test('captures AI processing failures', () async {
      final notifier = _createNotifier(
        aiService: _FakeAIAssistantService(
          process: (text, action) async => throw Exception('no key'),
        ),
      );
      notifier.state.controller.document.insert(0, 'draft');

      await notifier.applyAIAction(AIAction.improve);

      expect(notifier.state.isAIProcessing, isFalse);
      expect(notifier.state.aiResult, isNull);
      expect(notifier.state.errorMessage, 'Exception: no key');
    });
  });
}

DocumentNotifier _createNotifier({
  AIAssistantService? aiService,
  CollaborationService? collaboration,
  DocumentStorageService? storage,
  SpellCheckService? spellCheck,
}) {
  final notifier = DocumentNotifier(
    storage ?? _FakeStorage(),
    DocxService(),
    PdfService(),
    aiService ?? _FakeAIAssistantService(),
    _FakeCloudSyncService(),
    collaboration ?? _FakeCollaborationService(),
    spellCheck ?? _FakeSpellCheckService(),
  );
  addTearDown(notifier.dispose);
  return notifier;
}

String _plainText(DocumentNotifier notifier) {
  return notifier.state.controller.document.toPlainText();
}

class _FakeStorage extends DocumentStorageService {
  final documents = <String, String>{};
  final metadataById = <String, DocumentMetadata>{};
  final versionsById = <String, List<DocumentVersion>>{};

  @override
  Future<void> initialize() async {}

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
  Future<String?> loadDocument(String id) async => documents[id];

  @override
  Future<DocumentMetadata?> loadMetadata(String id) async => metadataById[id];

  @override
  Future<void> saveVersions(
    String documentId,
    List<DocumentVersion> versions,
  ) async {
    versionsById[documentId] = versions;
  }

  @override
  Future<List<DocumentVersion>> loadVersions(String documentId) async =>
      versionsById[documentId] ?? const [];

  @override
  Future<void> deleteDocument(String id) async {
    documents.remove(id);
    metadataById.remove(id);
    versionsById.remove(id);
  }
}

class _FakeAIAssistantService extends AIAssistantService {
  final Future<String> Function(String text, AIAction action)? process;

  _FakeAIAssistantService({this.process});

  @override
  Future<String> processText(String text, AIAction action) async {
    return process?.call(text, action) ?? text;
  }
}

class _FakeCloudSyncService extends CloudSyncService {
  @override
  Future<void> syncDocument(
    String docId,
    String content,
    DocumentMetadata metadata,
  ) async {}
}

class _FakeCollaborationService extends CollaborationService {
  final users = <CollaborationUser>[];
  (String, String)? initializedWith;
  var wasDisabled = false;
  var wasDisposed = false;

  @override
  List<CollaborationUser> get activeUsers => users;

  @override
  void initialize(String userId, String userName) {
    initializedWith = (userId, userName);
    users.add(_collaborator(userId, name: userName));
  }

  @override
  void disable() {
    wasDisabled = true;
    users.clear();
  }

  @override
  void updateCursorPosition(String userId, int position) {
    final index = users.indexWhere((user) => user.id == userId);
    if (index == -1) return;

    final user = users[index];
    users[index] = CollaborationUser(
      id: user.id,
      name: user.name,
      color: user.color,
      cursorPosition: position,
      lastActive: user.lastActive,
    );
  }

  @override
  void addMockUser(String name) {
    users.add(_collaborator('mock-${users.length}', name: name));
  }

  @override
  void dispose() {
    wasDisposed = true;
  }
}

CollaborationUser _collaborator(String id, {String? name}) {
  return CollaborationUser(
    id: id,
    name: name ?? id,
    color: Colors.blue,
    cursorPosition: 0,
    lastActive: DateTime(2026),
  );
}

class _FakeSpellCheckService extends SpellCheckService {
  @override
  List<SpellCheckError> checkText(String text) => const [];
}
