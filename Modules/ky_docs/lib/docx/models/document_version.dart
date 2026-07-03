class DocumentVersion {
  final String id;
  final DateTime timestamp;
  final String content;
  final String description;
  final String title;
  final String author;

  DocumentVersion({
    required this.id,
    required this.timestamp,
    required this.content,
    this.description = '',
    required this.title,
    required this.author,
  });
  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'content': content,
    'description': description,
    'title': title,
    'author': author,
  };

  factory DocumentVersion.fromJson(Map<String, dynamic> json) =>
      DocumentVersion(
        id: json['id'],
        timestamp: DateTime.parse(json['timestamp']),
        content: json['content'],
        description: json['description'] ?? '',
        title: json['title'] ?? '',
        author: json['author'] ?? '',
      );
}
