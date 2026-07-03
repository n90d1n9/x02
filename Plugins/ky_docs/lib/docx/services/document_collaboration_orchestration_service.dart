import '../models/collaboration_service.dart';
import '../models/document_state.dart';
import 'document_collaboration_controller.dart';

typedef CollaborationStateReader = DocumentState Function();
typedef CollaborationStateEmitter = void Function(DocumentState state);

class DocumentCollaborationOrchestrationService {
  final DocumentCollaborationController collaborationController;

  const DocumentCollaborationOrchestrationService({
    required this.collaborationController,
  });

  factory DocumentCollaborationOrchestrationService.fromCollaboration(
    CollaborationService collaboration,
  ) {
    return DocumentCollaborationOrchestrationService(
      collaborationController: DocumentCollaborationController(collaboration),
    );
  }

  void enable({
    required CollaborationStateReader readState,
    required CollaborationStateEmitter emitState,
    required String userId,
    required String userName,
  }) {
    _emitSnapshot(
      readState: readState,
      emitState: emitState,
      snapshot: collaborationController.enable(
        userId: userId,
        userName: userName,
      ),
    );
  }

  void disable({
    required CollaborationStateReader readState,
    required CollaborationStateEmitter emitState,
  }) {
    _emitSnapshot(
      readState: readState,
      emitState: emitState,
      snapshot: collaborationController.disable(),
    );
  }

  void updateCursor({
    required CollaborationStateReader readState,
    required CollaborationStateEmitter emitState,
    required int position,
  }) {
    final current = readState();
    final snapshot = collaborationController.updateCursor(
      isEnabled: current.isCollaborationEnabled,
      currentCollaborators: current.collaborators,
      position: position,
    );
    if (snapshot == null) return;

    _emitSnapshot(
      readState: readState,
      emitState: emitState,
      snapshot: snapshot,
    );
  }

  void addMockCollaborator({
    required CollaborationStateReader readState,
    required CollaborationStateEmitter emitState,
    required String name,
  }) {
    _emitSnapshot(
      readState: readState,
      emitState: emitState,
      snapshot: collaborationController.addMockCollaborator(
        isEnabled: readState().isCollaborationEnabled,
        name: name,
      ),
    );
  }

  void dispose() {
    collaborationController.dispose();
  }

  void _emitSnapshot({
    required CollaborationStateReader readState,
    required CollaborationStateEmitter emitState,
    required CollaborationSnapshot snapshot,
  }) {
    emitState(
      readState().copyWith(
        isCollaborationEnabled: snapshot.isEnabled,
        collaborators: snapshot.collaborators,
      ),
    );
  }
}
