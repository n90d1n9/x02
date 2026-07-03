import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/collaboration_service.dart';
import 'package:ky_docs/docx/models/collaboration_user.dart';
import 'package:ky_docs/docx/models/document_metadata.dart';
import 'package:ky_docs/docx/models/document_state.dart';
import 'package:ky_docs/docx/services/document_collaboration_controller.dart';
import 'package:ky_docs/docx/services/document_collaboration_orchestration_service.dart';

void main() {
  group('DocumentCollaborationOrchestrationService', () {
    late _FakeCollaborationService collaboration;
    late DocumentCollaborationOrchestrationService service;

    setUp(() {
      collaboration = _FakeCollaborationService();
      service = DocumentCollaborationOrchestrationService(
        collaborationController: DocumentCollaborationController(collaboration),
      );
    });

    test('enables collaboration and emits active collaborators', () {
      var currentState = _state();

      service.enable(
        readState: () => currentState,
        emitState: (state) => currentState = state,
        userId: 'local',
        userName: 'You',
      );

      expect(collaboration.initializedWith, ('local', 'You'));
      expect(currentState.isCollaborationEnabled, isTrue);
      expect(currentState.collaborators.single.name, 'You');
    });

    test('disables collaboration and clears collaborators', () {
      collaboration.users.add(_user('local'));
      var currentState = _state(
        isCollaborationEnabled: true,
        collaborators: [_user('local')],
      );

      service.disable(
        readState: () => currentState,
        emitState: (state) => currentState = state,
      );

      expect(collaboration.wasDisabled, isTrue);
      expect(currentState.isCollaborationEnabled, isFalse);
      expect(currentState.collaborators, isEmpty);
    });

    test('updates cursor only when collaboration is enabled', () {
      collaboration.users.add(_user('local'));
      var currentState = _state(
        isCollaborationEnabled: true,
        collaborators: [_user('local')],
      );

      service.updateCursor(
        readState: () => currentState,
        emitState: (state) => currentState = state,
        position: 42,
      );

      expect(collaboration.updatedCursor, ('local', 42));
      expect(currentState.collaborators.single.cursorPosition, 42);

      currentState = currentState.copyWith(isCollaborationEnabled: false);
      var emitCount = 0;
      service.updateCursor(
        readState: () => currentState,
        emitState: (state) {
          currentState = state;
          emitCount++;
        },
        position: 7,
      );

      expect(emitCount, 0);
    });

    test('adds mock collaborators while preserving enabled state', () {
      var currentState = _state(isCollaborationEnabled: true);

      service.addMockCollaborator(
        readState: () => currentState,
        emitState: (state) => currentState = state,
        name: 'Guest',
      );

      expect(collaboration.mockNames, ['Guest']);
      expect(currentState.isCollaborationEnabled, isTrue);
      expect(currentState.collaborators.single.name, 'Guest');
    });

    test('disposes the collaboration controller', () {
      service.dispose();

      expect(collaboration.wasDisposed, isTrue);
    });
  });
}

DocumentState _state({
  bool isCollaborationEnabled = false,
  List<CollaborationUser> collaborators = const [],
}) {
  final controller = quill.QuillController.basic();
  addTearDown(controller.dispose);

  final now = DateTime(2026);
  return DocumentState(
    controller: controller,
    metadata: DocumentMetadata(
      id: 'doc-1',
      title: 'Document',
      createdAt: now,
      modifiedAt: now,
    ),
    isCollaborationEnabled: isCollaborationEnabled,
    collaborators: collaborators,
  );
}

CollaborationUser _user(String id, {String? name, int cursorPosition = 0}) {
  return CollaborationUser(
    id: id,
    name: name ?? id,
    color: Colors.blue,
    cursorPosition: cursorPosition,
    lastActive: DateTime(2026),
  );
}

class _FakeCollaborationService extends CollaborationService {
  final users = <CollaborationUser>[];
  final mockNames = <String>[];
  (String, String)? initializedWith;
  (String, int)? updatedCursor;
  var wasDisabled = false;
  var wasDisposed = false;

  @override
  List<CollaborationUser> get activeUsers => users;

  @override
  void initialize(String userId, String userName) {
    initializedWith = (userId, userName);
    users.add(_user(userId, name: userName));
  }

  @override
  void disable() {
    wasDisabled = true;
    users.clear();
  }

  @override
  void updateCursorPosition(String userId, int position) {
    updatedCursor = (userId, position);
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
    mockNames.add(name);
    users.add(_user('mock-${mockNames.length}', name: name));
  }

  @override
  void dispose() {
    wasDisposed = true;
  }
}
