class SharedUser {
  final String id;
  final String name;
  final String email;
  final DocumentPermission permission;
  final DateTime sharedAt;

  SharedUser({
    required this.id,
    required this.name,
    required this.email,
    required this.permission,
    required this.sharedAt,
  });
}

enum DocumentPermission { view, comment, edit, admin }
