import 'dart:async';
import 'package:flutter/material.dart';

import 'collaboration_user.dart';
import 'document_change.dart';

class CollaborationService {
  final List<CollaborationUser> _activeUsers = [];
  final List<DocumentChange> _changeHistory = [];
  Timer? _presenceTimer;
  bool _isCollaborationEnabled = false;
  List<CollaborationUser> get activeUsers => _activeUsers;
  bool get isEnabled => _isCollaborationEnabled;
  void initialize(String userId, String userName) {
    _isCollaborationEnabled = true;
    _activeUsers.add(
      CollaborationUser(
        id: userId,
        name: userName,
        color: Colors.blue,
        cursorPosition: 0,
        lastActive: DateTime.now(),
      ),
    );
    _presenceTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _updatePresence(userId);
    });
  }

  void disable() {
    _isCollaborationEnabled = false;
    _presenceTimer?.cancel();
    _activeUsers.clear();
    _changeHistory.clear();
  }

  void _updatePresence(String userId) {
    final index = _activeUsers.indexWhere((u) => u.id == userId);
    if (index != -1) {
      final user = _activeUsers[index];
      _activeUsers[index] = CollaborationUser(
        id: user.id,
        name: user.name,
        color: user.color,
        cursorPosition: user.cursorPosition,
        lastActive: DateTime.now(),
      );
    }
    _activeUsers.removeWhere((user) {
      return DateTime.now().difference(user.lastActive).inSeconds > 30;
    });
  }

  void updateCursorPosition(String userId, int position) {
    final index = _activeUsers.indexWhere((u) => u.id == userId);
    if (index != -1) {
      final user = _activeUsers[index];
      _activeUsers[index] = CollaborationUser(
        id: user.id,
        name: user.name,
        color: user.color,
        cursorPosition: position,
        lastActive: DateTime.now(),
      );
    }
  }

  void recordChange(DocumentChange change) {
    _changeHistory.add(change);
    if (_changeHistory.length > 100) {
      _changeHistory.removeAt(0);
    }
  }

  void addMockUser(String name) {
    final colors = [Colors.green, Colors.orange, Colors.purple, Colors.pink];
    _activeUsers.add(
      CollaborationUser(
        id: 'user_${_activeUsers.length}',
        name: name,
        color: colors[_activeUsers.length % colors.length],
        cursorPosition: 0,
        lastActive: DateTime.now(),
      ),
    );
  }

  void dispose() {
    _presenceTimer?.cancel();
  }
}
