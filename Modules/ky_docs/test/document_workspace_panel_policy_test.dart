import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/document_editing_mode.dart';
import 'package:ky_docs/docx/models/document_editor_action_policy.dart';
import 'package:ky_docs/docx/widgets/workspace_panel/document_workspace_panel_id.dart';
import 'package:ky_docs/docx/widgets/workspace_panel/document_workspace_panel_policy.dart';

void main() {
  group('DocumentWorkspacePanelPolicy', () {
    test('allows every utility panel while editing', () {
      final policy = _policyFor(DocumentEditingMode.editing);

      expect(
        policy.panels.map((panel) => panel.id),
        DocumentWorkspacePanelId.values,
      );
      for (final panel in DocumentWorkspacePanelId.values) {
        expect(policy.canOpen(panel), isTrue);
      }
    });

    test('keeps read-only panels available while viewing', () {
      final policy = _policyFor(DocumentEditingMode.viewing);

      expect(policy.canOpen(DocumentWorkspacePanelId.statistics), isTrue);
      expect(policy.canOpen(DocumentWorkspacePanelId.findReplace), isTrue);
    });

    test('locks mutating panels while viewing', () {
      final policy = _policyFor(DocumentEditingMode.viewing);
      final aiAvailability = policy.availabilityFor(
        DocumentWorkspacePanelId.aiAssistant,
      );
      final insertAvailability = policy.availabilityFor(
        DocumentWorkspacePanelId.insert,
      );

      expect(aiAvailability.enabled, isFalse);
      expect(insertAvailability.enabled, isFalse);
      expect(aiAvailability.disabledReason, contains('Switch to Editing'));
      expect(insertAvailability.disabledReason, contains('Switch to Editing'));
    });
  });
}

DocumentWorkspacePanelPolicy _policyFor(DocumentEditingMode mode) {
  return DocumentWorkspacePanelPolicy(
    actionPolicy: DocumentEditorActionPolicy(editingMode: mode),
  );
}
