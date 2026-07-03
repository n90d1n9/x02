import '../../models/document_editor_action_policy.dart';
import 'document_workspace_panel_id.dart';

/// Describes whether a workspace utility panel can be opened.
class DocumentWorkspacePanelAvailability {
  final DocumentWorkspacePanelId id;
  final bool enabled;
  final String? disabledReason;

  const DocumentWorkspacePanelAvailability({
    required this.id,
    this.enabled = true,
    this.disabledReason,
  });
}

/// Centralizes workspace panel availability for the active editor mode.
class DocumentWorkspacePanelPolicy {
  final DocumentEditorActionPolicy actionPolicy;

  const DocumentWorkspacePanelPolicy({required this.actionPolicy});

  List<DocumentWorkspacePanelAvailability> get panels {
    return [
      const DocumentWorkspacePanelAvailability(
        id: DocumentWorkspacePanelId.statistics,
      ),
      const DocumentWorkspacePanelAvailability(
        id: DocumentWorkspacePanelId.findReplace,
      ),
      DocumentWorkspacePanelAvailability(
        id: DocumentWorkspacePanelId.aiAssistant,
        enabled: actionPolicy.canUseAIAssistant,
        disabledReason: actionPolicy.lockedMutationReason,
      ),
      DocumentWorkspacePanelAvailability(
        id: DocumentWorkspacePanelId.insert,
        enabled: actionPolicy.canInsertContent,
        disabledReason: actionPolicy.lockedMutationReason,
      ),
    ];
  }

  DocumentWorkspacePanelAvailability availabilityFor(
    DocumentWorkspacePanelId id,
  ) {
    return panels.firstWhere((panel) => panel.id == id);
  }

  bool canOpen(DocumentWorkspacePanelId id) {
    return availabilityFor(id).enabled;
  }
}
