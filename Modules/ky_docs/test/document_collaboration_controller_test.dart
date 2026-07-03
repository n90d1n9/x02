import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/collaboration_service.dart';
import 'package:ky_docs/docx/models/collaboration_user.dart';
import 'package:ky_docs/docx/services/document_collaboration_controller.dart';

void main() {
  group('DocumentCollaborationController', () {
    late _FakeCollaborationService service;
    late DocumentCollaborationController controller;

    setUp(() {
      service = _FakeCollaborationService();
      controller = DocumentCollaborationController(service);
    });

    test('enables collaboration and returns an immutable snapshot', () {
      final snapshot = controller.enable(userId: 'local', userName: 'You');

      expect(service.initializedWith, ('local', 'You'));
      expect(snapshot.isEnabled, isTrue);
      expect(snapshot.collaborators.single.id, 'local');
      expect(
        () => snapshot.collaborators.add(_user('other')),
        throwsUnsupportedError,
      );
    });

    test('disables collaboration and clears collaborators', () {
      service.users.add(_user('local'));

      final snapshot = controller.disable();

      expect(service.wasDisabled, isTrue);
      expect(snapshot.isEnabled, isFalse);
      expect(snapshot.collaborators, isEmpty);
      expect(service.users, isEmpty);
    });

    test('does not update cursor when collaboration is disabled', () {
      final snapshot = controller.updateCursor(
        isEnabled: false,
        currentCollaborators: [_user('local')],
        position: 42,
      );

      expect(snapshot, isNull);
      expect(service.updatedCursor, isNull);
    });

    test('updates the first active collaborator cursor', () {
      service.users.add(_user('local'));

      final snapshot = controller.updateCursor(
        isEnabled: true,
        currentCollaborators: [_user('local')],
        position: 42,
      );

      expect(service.updatedCursor, ('local', 42));
      expect(snapshot?.isEnabled, isTrue);
      expect(snapshot?.collaborators.single.cursorPosition, 42);
    });

    test('adds mock collaborators while preserving enabled state', () {
      final snapshot = controller.addMockCollaborator(
        isEnabled: true,
        name: 'Guest',
      );

      expect(service.mockNames, ['Guest']);
      expect(snapshot.isEnabled, isTrue);
      expect(snapshot.collaborators.single.name, 'Guest');
    });
  });
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
}
