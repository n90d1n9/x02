import '../models/document_outline.dart';

/// Creates stable ids for generated document outline entries.
typedef DocumentOutlineIdFactory = String Function();

/// Extracts a lightweight heading outline from plain document text.
class DocumentOutlineService {
  const DocumentOutlineService();

  List<DocumentOutline> generateOutline({
    required String text,
    required DocumentOutlineIdFactory createId,
  }) {
    final outline = <DocumentOutline>[];
    final lines = text.split('\n');

    var offset = 0;
    for (final line in lines) {
      final heading = _parseHeading(line);
      if (heading != null) {
        outline.add(
          DocumentOutline(
            id: createId(),
            title: heading.title,
            level: heading.level,
            offset: offset,
          ),
        );
      }

      offset += line.length + 1;
    }

    return outline;
  }

  _DocumentHeading? _parseHeading(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return null;

    final markdownHeading = _parseMarkdownHeading(trimmed);
    if (markdownHeading != null) return markdownHeading;

    if (trimmed.length > 3 && trimmed == trimmed.toUpperCase()) {
      return _DocumentHeading(title: trimmed, level: 1);
    }

    return null;
  }

  _DocumentHeading? _parseMarkdownHeading(String line) {
    final markerLength = line.indexOf(' ');
    if (markerLength < 1 || markerLength > 6) return null;

    final marker = line.substring(0, markerLength);
    if (!RegExp(r'^#{1,6}$').hasMatch(marker)) return null;

    final title = line.substring(markerLength + 1).trim();
    if (title.isEmpty) return null;

    return _DocumentHeading(title: title, level: markerLength);
  }
}

class _DocumentHeading {
  final String title;
  final int level;

  const _DocumentHeading({required this.title, required this.level});
}
