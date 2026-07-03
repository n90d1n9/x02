import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

/// Single-line text that highlights query matches for command palette results.
class CommandPaletteHighlightedText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle style;
  final TextStyle highlightStyle;
  final int maxLines;

  const CommandPaletteHighlightedText({
    super.key,
    required this.text,
    required this.query,
    required this.style,
    required this.highlightStyle,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: style,
        children: segments(text: text, query: query)
            .map((segment) {
              return TextSpan(
                text: segment.text,
                style: segment.isHighlighted ? highlightStyle : null,
              );
            })
            .toList(growable: false),
      ),
    );
  }

  static List<CommandPaletteHighlightSegment> segments({
    required String text,
    required String query,
  }) {
    final terms = _queryTerms(query);
    if (text.isEmpty || terms.isEmpty) {
      return [CommandPaletteHighlightSegment(text: text)];
    }

    final ranges = _highlightRanges(text: text, terms: terms);
    if (ranges.isEmpty) {
      return [CommandPaletteHighlightSegment(text: text)];
    }

    final segments = <CommandPaletteHighlightSegment>[];
    var cursor = 0;

    for (final range in ranges) {
      if (range.start > cursor) {
        segments.add(
          CommandPaletteHighlightSegment(
            text: text.substring(cursor, range.start),
          ),
        );
      }

      segments.add(
        CommandPaletteHighlightSegment(
          text: text.substring(range.start, range.end),
          isHighlighted: true,
        ),
      );
      cursor = range.end;
    }

    if (cursor < text.length) {
      segments.add(
        CommandPaletteHighlightSegment(text: text.substring(cursor)),
      );
    }

    return segments;
  }

  static List<String> _queryTerms(String query) {
    final seen = <String>{};

    return query
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((term) => term.isNotEmpty)
        .where(seen.add)
        .toList(growable: false)
      ..sort((a, b) => b.length.compareTo(a.length));
  }

  static List<_HighlightRange> _highlightRanges({
    required String text,
    required List<String> terms,
  }) {
    final lowerText = text.toLowerCase();
    final foundRanges = <_HighlightRange>[];

    for (final term in terms) {
      var start = lowerText.indexOf(term);
      while (start != -1) {
        final end = start + term.length;
        foundRanges.add(_HighlightRange(start, end));
        start = lowerText.indexOf(term, end);
      }
    }

    foundRanges.sort((a, b) {
      final startComparison = a.start.compareTo(b.start);
      if (startComparison != 0) return startComparison;

      return b.length.compareTo(a.length);
    });

    final ranges = <_HighlightRange>[];
    var coveredUntil = -1;

    for (final range in foundRanges) {
      if (range.start < coveredUntil) continue;

      ranges.add(range);
      coveredUntil = range.end;
    }

    return ranges;
  }
}

/// A plain or highlighted text slice for command palette result text.
class CommandPaletteHighlightSegment {
  final String text;
  final bool isHighlighted;

  const CommandPaletteHighlightSegment({
    required this.text,
    this.isHighlighted = false,
  });
}

/// Internal range used to merge query term matches.
class _HighlightRange {
  final int start;
  final int end;

  const _HighlightRange(this.start, this.end);

  int get length => end - start;
}

@Preview(name: 'Command palette highlighted text', size: Size(420, 100))
Widget commandPaletteHighlightedTextPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: SizedBox(
          width: 340,
          child: CommandPaletteHighlightedText(
            text: 'Open Import / Export',
            query: 'import',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
            highlightStyle: TextStyle(
              color: const Color(0xFF38BDF8),
              backgroundColor: const Color(0xFF38BDF8).withValues(alpha: 0.12),
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    ),
  );
}
