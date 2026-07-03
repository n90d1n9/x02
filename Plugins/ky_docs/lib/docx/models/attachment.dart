class Attachment {
  final String id;
  final String name;
  final String type;
  final int size;
  final DateTime uploadedAt;
  final String? url;

  Attachment({
    required this.id,
    required this.name,
    required this.type,
    required this.size,
    required this.uploadedAt,
    this.url,
  });
}
