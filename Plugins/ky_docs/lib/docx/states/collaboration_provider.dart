import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../docx/models/active_user.dart';
import '../../docx/models/collaboration_state.dart';
import '../../docx/models/user_cursor.dart';

final collaborationProvider =
    StateNotifierProvider<CollaborationNotifier, CollaborationState>((ref) {
      return CollaborationNotifier();
    });

class CollaborationNotifier extends StateNotifier<CollaborationState> {
  Timer? _heartbeatTimer;

  CollaborationNotifier() : super(CollaborationState()) {
    _simulateCollaboration();
  }

  void _simulateCollaboration() {
    // Simulate WebSocket connection
    Future.delayed(const Duration(seconds: 2), () {
      connect();
      _addMockUsers();
    });
  }

  void connect() {
    state = state.copyWith(isConnected: true);
    _startHeartbeat();
  }

  void disconnect() {
    state = state.copyWith(isConnected: false, activeUsers: []);
    _heartbeatTimer?.cancel();
  }

  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      // Send heartbeat to server
      debugPrint('Heartbeat sent');
    });
  }

  void _addMockUsers() {
    final users = [
      ActiveUser(
        id: 'user_2',
        name: 'Alice Johnson',
        color: Colors.blue,
        lastSeen: DateTime.now(),
      ),
      ActiveUser(
        id: 'user_3',
        name: 'Bob Smith',
        color: Colors.green,
        lastSeen: DateTime.now(),
      ),
    ];

    state = state.copyWith(activeUsers: users);
  }

  void updateCursor(String userId, int position, Color color) {
    final newCursors = Map<String, UserCursor>.from(state.cursors);
    newCursors[userId] = UserCursor(
      position: position,
      userId: userId,
      color: color,
    );
    state = state.copyWith(cursors: newCursors);
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    super.dispose();
  }
}
