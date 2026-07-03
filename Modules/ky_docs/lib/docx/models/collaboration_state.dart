import 'active_user.dart';
import 'user_cursor.dart';

class CollaborationState {
  final bool isConnected;
  final List<ActiveUser> activeUsers;
  final Map<String, UserCursor> cursors;

  CollaborationState({
    this.isConnected = false,
    this.activeUsers = const [],
    this.cursors = const {},
  });

  CollaborationState copyWith({
    bool? isConnected,
    List<ActiveUser>? activeUsers,
    Map<String, UserCursor>? cursors,
  }) {
    return CollaborationState(
      isConnected: isConnected ?? this.isConnected,
      activeUsers: activeUsers ?? this.activeUsers,
      cursors: cursors ?? this.cursors,
    );
  }
}
