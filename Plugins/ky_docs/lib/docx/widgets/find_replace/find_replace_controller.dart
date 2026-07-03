import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart';

/// Coordinates document search, replacement, and match navigation for the editor.
class DocxFindReplaceController extends ChangeNotifier {
  final QuillController editorController;
  final findTextController = TextEditingController();
  final replaceTextController = TextEditingController();

  List<int> _matches = [];
  int _currentMatchIndex = -1;
  bool _matchCase = false;
  bool _wholeWord = false;

  DocxFindReplaceController({required this.editorController}) {
    replaceTextController.addListener(_notifyReplacementPreviewChanged);
  }

  List<int> get matches => List.unmodifiable(_matches);
  int get currentMatchIndex => _currentMatchIndex;
  bool get hasMatches => _matches.isNotEmpty;
  bool get hasQuery => findTextController.text.isNotEmpty;
  bool get matchCase => _matchCase;
  bool get wholeWord => _wholeWord;
  int get matchCount => _matches.length;

  String get matchLabel {
    if (!hasQuery) return 'Ready';
    if (!hasMatches) return 'No matches';
    return '${_currentMatchIndex + 1} of ${_matches.length}';
  }

  void performSearch(String query) {
    if (findTextController.text != query) {
      findTextController.value = TextEditingValue(
        text: query,
        selection: TextSelection.collapsed(offset: query.length),
      );
    }

    _runSearch();
  }

  void setMatchCase(bool value) {
    if (_matchCase == value) return;
    _matchCase = value;
    _runSearch();
  }

  void setWholeWord(bool value) {
    if (_wholeWord == value) return;
    _wholeWord = value;
    _runSearch();
  }

  void clearSearch() {
    if (!hasQuery && !hasMatches) return;
    findTextController.clear();
    _clearMatches();
  }

  void _runSearch() {
    final query = findTextController.text;
    if (query.isEmpty) {
      _clearMatches();
      return;
    }

    final text = editorController.document.toPlainText();
    final searchableText = _matchCase ? text : text.toLowerCase();
    final searchableQuery = _matchCase ? query : query.toLowerCase();
    final matches = <int>[];

    var index = searchableText.indexOf(searchableQuery);
    while (index != -1) {
      if (!_wholeWord || _isWholeWordMatch(text, index, query.length)) {
        matches.add(index);
      }
      index = searchableText.indexOf(
        searchableQuery,
        index + searchableQuery.length,
      );
    }

    _matches = matches;
    _currentMatchIndex = matches.isEmpty ? -1 : 0;
    notifyListeners();

    if (matches.isNotEmpty) {
      _highlightMatch(matches.first, query.length);
    }
  }

  void goToNextMatch() {
    if (!hasMatches) return;

    _currentMatchIndex = (_currentMatchIndex + 1) % _matches.length;
    notifyListeners();
    _highlightCurrentMatch();
  }

  void goToPreviousMatch() {
    if (!hasMatches) return;

    _currentMatchIndex =
        (_currentMatchIndex - 1 + _matches.length) % _matches.length;
    notifyListeners();
    _highlightCurrentMatch();
  }

  bool replaceCurrentMatch() {
    if (editorController.readOnly || !hasMatches || _currentMatchIndex == -1) {
      return false;
    }

    final offset = _matches[_currentMatchIndex];
    final replaceText = replaceTextController.text;

    editorController.replaceText(
      offset,
      findTextController.text.length,
      replaceText,
      TextSelection.collapsed(offset: offset + replaceText.length),
    );

    _runSearch();
    return true;
  }

  int replaceAllMatches() {
    if (editorController.readOnly || !hasMatches) return 0;

    final count = _matches.length;
    final findText = findTextController.text;
    final replaceText = replaceTextController.text;
    final sortedMatches = List<int>.from(_matches)
      ..sort((a, b) => b.compareTo(a));

    for (final offset in sortedMatches) {
      editorController.replaceText(offset, findText.length, replaceText, null);
    }

    _clearMatches();
    return count;
  }

  void _highlightCurrentMatch() {
    _highlightMatch(
      _matches[_currentMatchIndex],
      findTextController.text.length,
    );
  }

  void _highlightMatch(int offset, int length) {
    editorController.updateSelection(
      TextSelection(baseOffset: offset, extentOffset: offset + length),
      ChangeSource.local,
    );
  }

  bool _isWholeWordMatch(String text, int offset, int queryLength) {
    final beforeIndex = offset - 1;
    final afterIndex = offset + queryLength;
    final startsAtBoundary =
        beforeIndex < 0 || !_isWordCharacter(text.codeUnitAt(beforeIndex));
    final endsAtBoundary =
        afterIndex >= text.length ||
        !_isWordCharacter(text.codeUnitAt(afterIndex));

    return startsAtBoundary && endsAtBoundary;
  }

  bool _isWordCharacter(int codeUnit) {
    return (codeUnit >= 48 && codeUnit <= 57) ||
        (codeUnit >= 65 && codeUnit <= 90) ||
        (codeUnit >= 97 && codeUnit <= 122) ||
        codeUnit == 95;
  }

  void _clearMatches() {
    _matches = [];
    _currentMatchIndex = -1;
    notifyListeners();
  }

  void _notifyReplacementPreviewChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    replaceTextController.removeListener(_notifyReplacementPreviewChanged);
    findTextController.dispose();
    replaceTextController.dispose();
    super.dispose();
  }
}
