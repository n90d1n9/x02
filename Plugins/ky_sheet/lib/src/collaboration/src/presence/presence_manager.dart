import 'user_cursor.dart';

/// Manages user presence in collaborative editing sessions.
/// 
/// Tracks which users are currently editing a document, their cursors,
/// selections, and other presence information.
class PresenceManager {
  /// Unique identifier for this session
  final String sessionId;
  
  /// Map of user IDs to their presence information
  final Map<String, UserPresence> _users = {};
  
  /// Callback when users join/leave
  Function(UserPresence)? onUserJoin;
  Function(UserPresence)? onUserLeave;
  Function(String userId, UserCursor)? onCursorUpdate;
  Function(String userId, CellRange)? onSelectionUpdate;
  
  PresenceManager({required this.sessionId});
  
  /// Add or update a user's presence
  void updateUserPresence(UserPresence user) {
    final isNewUser = !_users.containsKey(user.userId);
    _users[user.userId] = user;
    
    if (isNewUser && onUserJoin != null) {
      onUserJoin!(user);
    }
  }
  
  /// Remove a user from the session
  void removeUser(String userId) {
    if (_users.containsKey(userId)) {
      final user = _users.remove(userId)!;
      if (onUserLeave != null) {
        onUserLeave!(user);
      }
    }
  }
  
  /// Update a user's cursor position
  void updateCursor(String userId, UserCursor cursor) {
    if (_users.containsKey(userId)) {
      _users[userId]!.cursor = cursor;
      _users[userId]!.lastActivity = DateTime.now();
      
      if (onCursorUpdate != null) {
        onCursorUpdate!(userId, cursor);
      }
    }
  }
  
  /// Update a user's cell selection
  void updateSelection(String userId, CellRange range) {
    if (_users.containsKey(userId)) {
      _users[userId]!.selection = range;
      _users[userId]!.lastActivity = DateTime.now();
      
      if (onSelectionUpdate != null) {
        onSelectionUpdate!(userId, range);
      }
    }
  }
  
  /// Get all active users
  List<UserPresence> get activeUsers => _users.values.toList();
  
  /// Get a specific user's presence
  UserPresence? getUser(String userId) => _users[userId];
  
  /// Get user count
  int get userCount => _users.length;
  
  /// Clean up inactive users (no activity for specified duration)
  void cleanupInactiveUsers(Duration timeout) {
    final now = DateTime.now();
    final inactiveUsers = <String>[];
    
    for (final entry in _users.entries) {
      final lastActivity = entry.value.lastActivity;
      if (now.difference(lastActivity) > timeout) {
        inactiveUsers.add(entry.key);
      }
    }
    
    for (final userId in inactiveUsers) {
      removeUser(userId);
    }
  }
  
  /// Serialize presence state
  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'users': _users.values.map((u) => u.toJson()).toList(),
    };
  }
  
  /// Deserialize presence state
  factory PresenceManager.fromJson(Map<String, dynamic> json) {
    final manager = PresenceManager(sessionId: json['sessionId'] as String);
    
    if (json['users'] != null) {
      for (final userJson in json['users'] as List) {
        final user = UserPresence.fromJson(userJson as Map<String, dynamic>);
        manager._users[user.userId] = user;
      }
    }
    
    return manager;
  }
}

/// Represents a user's presence in a collaborative session
class UserPresence {
  final String userId;
  final String userName;
  final String? color; // Unique color for cursor/selection highlighting
  final DateTime joinedAt;
  DateTime lastActivity;
  UserCursor? cursor;
  CellRange? selection;
  bool isEditing;
  
  UserPresence({
    required this.userId,
    required this.userName,
    this.color,
    DateTime? joinedAt,
    DateTime? lastActivity,
    this.cursor,
    this.selection,
    this.isEditing = false,
  })  : joinedAt = joinedAt ?? DateTime.now(),
        lastActivity = lastActivity ?? DateTime.now();
  
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'color': color,
      'joinedAt': joinedAt.toIso8601String(),
      'lastActivity': lastActivity.toIso8601String(),
      'cursor': cursor?.toJson(),
      'selection': selection?.toJson(),
      'isEditing': isEditing,
    };
  }
  
  factory UserPresence.fromJson(Map<String, dynamic> json) {
    return UserPresence(
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      color: json['color'] as String?,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      lastActivity: DateTime.parse(json['lastActivity'] as String),
      cursor: json['cursor'] != null 
          ? UserCursor.fromJson(json['cursor'] as Map<String, dynamic>)
          : null,
      selection: json['selection'] != null
          ? CellRange.fromJson(json['selection'] as Map<String, dynamic>)
          : null,
      isEditing: json['isEditing'] as bool? ?? false,
    );
  }
}

/// Represents a range of cells (e.g., A1:B2)
class CellRange {
  final String startCell;
  final String endCell;
  
  CellRange({required this.startCell, required this.endCell});
  
  Map<String, dynamic> toJson() {
    return {
      'startCell': startCell,
      'endCell': endCell,
    };
  }
  
  factory CellRange.fromJson(Map<String, dynamic> json) {
    return CellRange(
      startCell: json['startCell'] as String,
      endCell: json['endCell'] as String,
    );
  }
  
  @override
  String toString() => '$startCell:$endCell';
}
