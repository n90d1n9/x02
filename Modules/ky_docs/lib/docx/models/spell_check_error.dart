class SpellCheckError {
  final String word;
  final int offset;
  final List<String> suggestions;
  SpellCheckError({
    required this.word,
    required this.offset,
    required this.suggestions,
  });
}
