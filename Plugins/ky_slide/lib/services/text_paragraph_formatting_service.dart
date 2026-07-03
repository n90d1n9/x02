import '../models/text_paragraph_format.dart';

/// Applies paragraph-level formatting to editable plain text blocks.
class TextParagraphFormattingService {
  static final RegExp _numberedPattern = RegExp(r'^(\d+)[.)]\s*');
  static final RegExp _bulletPattern = RegExp(r'^[-*\u2022]\s*');
  static final RegExp _wordPattern = RegExp(r"[A-Za-z0-9]+(?:'[A-Za-z0-9]+)?");

  const TextParagraphFormattingService();

  TextParagraphListStyle activeListStyle(String text) {
    final styles = text
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .map(_lineListStyle)
        .toSet();

    if (styles.length != 1) return TextParagraphListStyle.none;

    return styles.single;
  }

  String applyListStyle({
    required String text,
    required TextParagraphListStyle style,
  }) {
    var nextNumber = 1;

    return text
        .split('\n')
        .map((line) {
          if (line.trim().isEmpty) return line;

          final indent = _leadingWhitespace(line);
          final content = _withoutListPrefix(line).trimLeft();

          return switch (style) {
            TextParagraphListStyle.none => '$indent$content',
            TextParagraphListStyle.bullet => '$indent- $content',
            TextParagraphListStyle.numbered =>
              '$indent${nextNumber++}. $content',
          };
        })
        .join('\n');
  }

  String adjustIndent({
    required String text,
    required TextIndentDirection direction,
  }) {
    return text
        .split('\n')
        .map((line) {
          if (line.trim().isEmpty) return line;

          return switch (direction) {
            TextIndentDirection.increase => '  $line',
            TextIndentDirection.decrease => _decreaseIndent(line),
          };
        })
        .join('\n');
  }

  String applyTextCase({
    required String text,
    required TextCaseTransform transform,
  }) {
    return switch (transform) {
      TextCaseTransform.sentence => _sentenceCase(text),
      TextCaseTransform.lowercase => text.toLowerCase(),
      TextCaseTransform.uppercase => text.toUpperCase(),
      TextCaseTransform.title => _titleCase(text),
    };
  }

  TextParagraphListStyle _lineListStyle(String line) {
    final trimmed = line.trimLeft();
    if (_bulletPattern.hasMatch(trimmed)) return TextParagraphListStyle.bullet;
    if (_numberedPattern.hasMatch(trimmed)) {
      return TextParagraphListStyle.numbered;
    }

    return TextParagraphListStyle.none;
  }

  String _withoutListPrefix(String line) {
    final indent = _leadingWhitespace(line);
    final content = line.substring(indent.length);

    return '$indent${content.replaceFirst(_bulletPattern, '').replaceFirst(_numberedPattern, '')}';
  }

  String _leadingWhitespace(String line) {
    return RegExp(r'^\s*').firstMatch(line)?.group(0) ?? '';
  }

  String _decreaseIndent(String line) {
    if (line.startsWith('  ')) return line.substring(2);
    if (line.startsWith(' ')) return line.substring(1);

    return line;
  }

  String _sentenceCase(String text) {
    final buffer = StringBuffer();
    var capitalizeNext = true;

    for (final codeUnit in text.codeUnits) {
      final char = String.fromCharCode(codeUnit);
      if (_isAsciiLetter(codeUnit)) {
        buffer.write(capitalizeNext ? char.toUpperCase() : char.toLowerCase());
        capitalizeNext = false;
      } else {
        buffer.write(char);
        if (char == '.' || char == '!' || char == '?' || char == '\n') {
          capitalizeNext = true;
        }
      }
    }

    return buffer.toString();
  }

  String _titleCase(String text) {
    return text.replaceAllMapped(_wordPattern, (match) {
      final word = match.group(0) ?? '';
      if (word.isEmpty) return word;

      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    });
  }

  bool _isAsciiLetter(int codeUnit) {
    return (codeUnit >= 65 && codeUnit <= 90) ||
        (codeUnit >= 97 && codeUnit <= 122);
  }
}
