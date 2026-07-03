import '../models/footnote.dart';

class FootnoteInsertion {
  final Footnote footnote;
  final List<Footnote> footnotes;

  const FootnoteInsertion({required this.footnote, required this.footnotes});

  String get reference => '[${footnote.number}]';
}

class DocumentFootnoteService {
  const DocumentFootnoteService();

  FootnoteInsertion addFootnote({
    required List<Footnote> currentFootnotes,
    required String id,
    required String text,
    required int offset,
  }) {
    final footnote = Footnote(
      id: id,
      number: currentFootnotes.length + 1,
      text: text,
      offset: offset,
    );

    return FootnoteInsertion(
      footnote: footnote,
      footnotes: [...currentFootnotes, footnote],
    );
  }

  List<Footnote> updateFootnote({
    required List<Footnote> currentFootnotes,
    required String id,
    required String text,
  }) {
    return currentFootnotes.map((footnote) {
      if (footnote.id != id) return footnote;

      return Footnote(
        id: footnote.id,
        number: footnote.number,
        text: text,
        offset: footnote.offset,
      );
    }).toList();
  }

  List<Footnote> deleteFootnote({
    required List<Footnote> currentFootnotes,
    required String id,
  }) {
    final remaining = currentFootnotes
        .where((footnote) => footnote.id != id)
        .toList();

    return _renumber(remaining);
  }

  List<Footnote> _renumber(List<Footnote> footnotes) {
    return footnotes.asMap().entries.map((entry) {
      final footnote = entry.value;
      return Footnote(
        id: footnote.id,
        number: entry.key + 1,
        text: footnote.text,
        offset: footnote.offset,
      );
    }).toList();
  }
}
