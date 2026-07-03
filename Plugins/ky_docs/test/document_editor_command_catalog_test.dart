import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/document_editing_mode.dart';
import 'package:ky_docs/docx/models/document_metadata.dart';
import 'package:ky_docs/docx/models/document_state.dart';
import 'package:ky_docs/docx/models/page_layout.dart';
import 'package:ky_docs/docx/widgets/command_palette/document_command.dart';
import 'package:ky_docs/docx/widgets/command_palette/document_editor_command_catalog.dart';
import 'package:ky_docs/docx/widgets/review_hub/document_side_panel.dart';

void main() {
  group('DocumentEditorCommandCatalog', () {
    test('mirrors save availability from the document dirty state', () {
      final cleanSave = _command(_catalog(hasUnsavedChanges: false), 'save');
      final dirtySave = _command(_catalog(hasUnsavedChanges: true), 'save');

      expect(cleanSave.enabled, isFalse);
      expect(cleanSave.subtitle, 'No unsaved changes right now');
      expect(cleanSave.disabledLabel, 'Saved');
      expect(cleanSave.disabledReason, 'No unsaved changes right now');
      expect(cleanSave.disabledIcon, Icons.task_alt);
      expect(dirtySave.enabled, isTrue);
      expect(dirtySave.subtitle, 'Save the latest document changes');
    });

    test('describes find as find-only while viewing', () {
      final editingFind = _command(
        _catalog(editingMode: DocumentEditingMode.editing),
        'find',
      );
      final viewingFind = _command(
        _catalog(editingMode: DocumentEditingMode.viewing),
        'find',
      );

      expect(editingFind.title, 'Find and replace');
      expect(editingFind.keywords, contains('replace'));
      expect(viewingFind.title, 'Find');
      expect(viewingFind.subtitle, contains('locks replacement'));
      expect(viewingFind.keywords, contains('find only'));
      expect(viewingFind.keywords, contains('read only'));
    });

    test('locks mutating assistant and insert commands while viewing', () {
      final commands = _catalog(editingMode: DocumentEditingMode.viewing);
      final ai = _command(commands, 'ai');
      final insert = _command(commands, 'insert');

      expect(ai.enabled, isFalse);
      expect(ai.subtitle, contains('Editing or Suggesting'));
      expect(ai.disabledLabel, 'Locked');
      expect(ai.disabledReason, contains('Editing or Suggesting'));
      expect(ai.disabledIcon, Icons.lock_outline);
      expect(insert.enabled, isFalse);
      expect(insert.subtitle, contains('Editing or Suggesting'));
      expect(insert.disabledLabel, 'Locked');
    });

    test('marks the active editing mode command as current', () {
      final commands = _catalog(editingMode: DocumentEditingMode.suggesting);
      final suggesting = _command(commands, 'mode-suggesting');
      final viewing = _command(commands, 'mode-viewing');

      expect(suggesting.enabled, isFalse);
      expect(suggesting.disabledLabel, 'Current');
      expect(suggesting.disabledReason, 'Suggesting mode is already active');
      expect(viewing.enabled, isTrue);
    });

    test('routes panel, mode, and layout commands through callbacks', () async {
      DocumentSidePanel? selectedPanel;
      DocumentEditingMode? selectedMode;
      PageLayout? selectedLayout;
      var openedPageNavigator = false;
      final commands = _catalog(
        onOpenSidePanel: (panel) => selectedPanel = panel,
        onSetEditingMode: (mode) => selectedMode = mode,
        onSetPageLayout: (layout) => selectedLayout = layout,
        onShowPageNavigator: () => openedPageNavigator = true,
      );

      await _command(commands, 'track-changes').onSelected();
      await _command(commands, 'mode-suggesting').onSelected();
      await _command(commands, 'layout-web').onSelected();
      await _command(commands, 'page-navigator').onSelected();

      expect(selectedPanel, DocumentSidePanel.trackChanges);
      expect(selectedMode, DocumentEditingMode.suggesting);
      expect(selectedLayout, PageLayout.web);
      expect(openedPageNavigator, isTrue);
    });
  });
}

List<DocumentCommand> _catalog({
  DocumentEditingMode editingMode = DocumentEditingMode.editing,
  bool hasUnsavedChanges = false,
  ValueChanged<DocumentSidePanel>? onOpenSidePanel,
  ValueChanged<DocumentEditingMode>? onSetEditingMode,
  ValueChanged<PageLayout>? onSetPageLayout,
  VoidCallback? onShowPageNavigator,
}) {
  final controller = quill.QuillController.basic();
  addTearDown(controller.dispose);

  return DocumentEditorCommandCatalog(
    documentState: DocumentState(
      controller: controller,
      metadata: DocumentMetadata(
        id: 'doc-1',
        title: 'Proposal',
        createdAt: DateTime(2026),
        modifiedAt: DateTime(2026, 1, 2),
      ),
      hasUnsavedChanges: hasUnsavedChanges,
    ),
    editingMode: editingMode,
    onSave: () {},
    onShowFindReplace: () {},
    onOpenSidePanel: onOpenSidePanel ?? (_) {},
    onSetEditingMode: onSetEditingMode ?? (_) {},
    onShowStatistics: () {},
    onShowAIAssistant: () {},
    onShowInsertPanel: () {},
    onShowPageNavigator: onShowPageNavigator ?? () {},
    onOpenCollaboration: () {},
    onPrint: () {},
    onCreateNewDocument: () {},
    onSetPageLayout: onSetPageLayout ?? (_) {},
  ).build();
}

DocumentCommand _command(List<DocumentCommand> commands, String id) {
  return commands.singleWhere((command) => command.id == id);
}
