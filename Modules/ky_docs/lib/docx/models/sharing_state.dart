import 'share_user.dart';

class SharingState {
  final List<SharedUser> sharedUsers;
  final bool isPublic;
  final String? publicLink;
  final DocumentPermission defaultPermission;

  SharingState({
    this.sharedUsers = const [],
    this.isPublic = false,
    this.publicLink,
    this.defaultPermission = DocumentPermission.view,
  });

  SharingState copyWith({
    List<SharedUser>? sharedUsers,
    bool? isPublic,
    String? publicLink,
    DocumentPermission? defaultPermission,
  }) {
    return SharingState(
      sharedUsers: sharedUsers ?? this.sharedUsers,
      isPublic: isPublic ?? this.isPublic,
      publicLink: publicLink ?? this.publicLink,
      defaultPermission: defaultPermission ?? this.defaultPermission,
    );
  }
}
