class DocumentMetadata {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime lastModified;
  final String author;
  final int wordCount;
  final int characterCount;
  final List<String> tags;
  final String? folderId;
  final bool isFavorite;
  DocumentMetadata({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.lastModified,
    this.author = 'Unknown',
    this.wordCount = 0,
    this.characterCount = 0,
    this.tags = const [],
    this.folderId,
    this.isFavorite = false,
  });
  DocumentMetadata copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? lastModified,
    String? author,
    int? wordCount,
    int? characterCount,
    List<String>? tags,
    String? folderId,
    bool clearFolder = false,
    bool? isFavorite,
  }) {
    return DocumentMetadata(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      author: author ?? this.author,
      wordCount: wordCount ?? this.wordCount,
      characterCount: characterCount ?? this.characterCount,
      tags: tags ?? this.tags,
      folderId: clearFolder ? null : (folderId ?? this.folderId),
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'lastModified': lastModified.toIso8601String(),
    'author': author,
    'wordCount': wordCount,
    'characterCount': characterCount,
    'tags': tags,
    'folderId': folderId,
    'isFavorite': isFavorite,
  };
  factory DocumentMetadata.fromJson(Map<String, dynamic> json) =>
      DocumentMetadata(
        id: json['id'],
        title: json['title'],
        createdAt: DateTime.parse(json['createdAt']),
        lastModified: DateTime.parse(json['lastModified']),
        author: json['author'] ?? 'Unknown',
        wordCount: json['wordCount'] ?? 0,
        characterCount: json['characterCount'] ?? 0,
        tags: List<String>.from(json['tags'] ?? []),
        folderId: json['folderId'],
        isFavorite: json['isFavorite'] ?? false,
      );
}
