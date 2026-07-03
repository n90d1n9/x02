class DocumentOutline {
  final String id;
  final String title;
  final int level;
  final int offset;
  final List<DocumentOutline> children;
  const DocumentOutline({
    required this.id,
    required this.title,
    required this.level,
    required this.offset,
    this.children = const [],
  });
}
