import 'comment_reply.dart';

class Comment {
  final String id;
  final String text;
  final String author;
  final List<CommentReply> replies;

  final int offset;
  final String? anchorText;
  final DateTime createdAt;
  final bool resolved;

  Comment({
    required this.id,
    required this.text,
    required this.author,
    this.replies = const [],

    required this.offset,
    required this.createdAt,
    this.anchorText,
    this.resolved = false,
  });

  bool get isOpen => !resolved;

  Comment copyWith({
    String? id,
    String? author,
    String? text,
    int? offset,
    String? anchorText,
    bool clearAnchorText = false,
    DateTime? createdAt,
    bool? resolved,
  }) {
    return Comment(
      id: id ?? this.id,
      author: author ?? this.author,
      text: text ?? this.text,
      offset: offset ?? this.offset,
      anchorText: clearAnchorText ? null : (anchorText ?? this.anchorText),
      createdAt: createdAt ?? this.createdAt,
      resolved: resolved ?? this.resolved,
    );
  }
}
