import 'package:flutter_riverpod/legacy.dart';

import '../../docx/models/share_user.dart';
import '../../docx/models/sharing_state.dart';

final sharingProvider = StateNotifierProvider<SharingNotifier, SharingState>((
  ref,
) {
  return SharingNotifier();
});

class SharingNotifier extends StateNotifier<SharingState> {
  SharingNotifier() : super(SharingState()) {
    _loadMockSharing();
  }

  void _loadMockSharing() {
    state = state.copyWith(
      sharedUsers: [
        SharedUser(
          id: 'user_2',
          name: 'Alice Johnson',
          email: 'alice@example.com',
          permission: DocumentPermission.edit,
          sharedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        SharedUser(
          id: 'user_3',
          name: 'Bob Smith',
          email: 'bob@example.com',
          permission: DocumentPermission.comment,
          sharedAt: DateTime.now().subtract(const Duration(hours: 3)),
        ),
      ],
    );
  }

  void shareWithUser(String name, String email, DocumentPermission permission) {
    final user = SharedUser(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: email,
      permission: permission,
      sharedAt: DateTime.now(),
    );
    state = state.copyWith(sharedUsers: [...state.sharedUsers, user]);
  }

  void updatePermission(String userId, DocumentPermission newPermission) {
    final updatedUsers = state.sharedUsers.map((user) {
      if (user.id == userId) {
        return SharedUser(
          id: user.id,
          name: user.name,
          email: user.email,
          permission: newPermission,
          sharedAt: user.sharedAt,
        );
      }
      return user;
    }).toList();
    state = state.copyWith(sharedUsers: updatedUsers);
  }

  void removeUser(String userId) {
    state = state.copyWith(
      sharedUsers: state.sharedUsers.where((u) => u.id != userId).toList(),
    );
  }

  void togglePublicAccess() {
    if (state.isPublic) {
      state = state.copyWith(isPublic: false, publicLink: null);
    } else {
      final link =
          'https://docs.app/d/${DateTime.now().millisecondsSinceEpoch}';
      state = state.copyWith(isPublic: true, publicLink: link);
    }
  }
}
