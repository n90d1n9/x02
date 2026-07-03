import '../models/collaboration_service.dart';
import '../models/collaboration_user.dart';

class CollaborationSnapshot {
  final bool isEnabled;
  final List<CollaborationUser> collaborators;

  const CollaborationSnapshot({
    required this.isEnabled,
    required this.collaborators,
  });
}

class DocumentCollaborationController {
  final CollaborationService collaboration;

  const DocumentCollaborationController(this.collaboration);

  CollaborationSnapshot enable({
    required String userId,
    required String userName,
  }) {
    collaboration.initialize(userId, userName);
    return CollaborationSnapshot(isEnabled: true, collaborators: _snapshot());
  }

  CollaborationSnapshot disable() {
    collaboration.disable();
    return const CollaborationSnapshot(isEnabled: false, collaborators: []);
  }

  CollaborationSnapshot? updateCursor({
    required bool isEnabled,
    required List<CollaborationUser> currentCollaborators,
    required int position,
  }) {
    if (!isEnabled) return null;

    final userId = currentCollaborators.isEmpty
        ? 'local'
        : currentCollaborators.first.id;
    collaboration.updateCursorPosition(userId, position);

    return CollaborationSnapshot(isEnabled: true, collaborators: _snapshot());
  }

  CollaborationSnapshot addMockCollaborator({
    required bool isEnabled,
    required String name,
  }) {
    collaboration.addMockUser(name);
    return CollaborationSnapshot(
      isEnabled: isEnabled,
      collaborators: _snapshot(),
    );
  }

  List<CollaborationUser> _snapshot() {
    return List.unmodifiable(collaboration.activeUsers);
  }

  void dispose() {
    collaboration.dispose();
  }
}
