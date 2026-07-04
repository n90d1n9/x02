import 'package:flutter/widgets.dart';
import 'package:ky_docs/compat/flutter_quill_compat.dart';

/// Coordinates document search, replacement, and match navigation for the editor.
class DocxFindReplaceController extends ChangeNotifier {
  final QuillController editorController;
  final findTextController = TextEditingController();
  final replaceTextController = TextEditingController();

  List<int> _matches = [];
  int _currentMatchIndex = -1;
  bool _matchCase = false;
  bool _wholeWord = false;
  bool _useRegex = false;
  RegExp? _cachedRegex;

  DocxFindReplaceController({required this.editorController}) {
    replaceTextController.addListener(_notifyReplacementPreviewChanged);
  }

  List<int> get matches => List.unmodifiable(_matches);
  int get currentMatchIndex => _currentMatchIndex;
  bool get hasMatches => _matches.isNotEmpty;
  bool get hasQuery => findTextController.text.isNotEmpty;
  bool get matchCase => _matchCase;
  bool get wholeWord => _wholeWord;
  bool get useRegex => _useRegex;
  int get matchCount => _matches.length;
  bool get isValidRegex => _cachedRegex != null || !_useRegex;

  String get matchLabel {
    if (!hasQuery) return 'Ready';
    if (!hasMatches) return 'No matches';
    return '${_currentMatchIndex + 1} of ${_matches.length}';
  }

  String get regexError {
    if (!_useRegex) return '';
    if (_cachedRegex != null) return '';
    return 'Invalid regular expression';
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

  void setUseRegex(bool value) {
    if (_useRegex == value) return;
    _useRegex = value;
    _cachedRegex = null; // Clear cached regex when toggling
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
    
    // Handle regex search
    if (_useRegex) {
      try {
        _cachedRegex = RegExp(
          query,
          caseSensitive: _matchCase,
          multiLine: true,
        );
      } catch (e) {
        // Invalid regex - clear matches and notify error state
        _cachedRegex = null;
        _clearMatches();
        notifyListeners();
        return;
      }
      
      final matches = <int>[];
      for (final match in _cachedRegex!.allMatches(text)) {
        if (!_wholeWord || _isWholeWordMatch(text, match.start, match.group(0)!.length)) {
          matches.add(match.start);
        }
      }
      
      _matches = matches;
      _currentMatchIndex = matches.isEmpty ? -1 : 0;
      notifyListeners();
      
      if (matches.isNotEmpty) {
        final firstMatch = _cachedRegex!.firstMatch(text)!;
        _highlightMatch(firstMatch.start, firstMatch.group(0)!.length);
      }
      return;
    }
    
    // Standard text search
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
    
    // Calculate match length based on search mode
    int matchLength;
    if (_useRegex && _cachedRegex != null) {
      final text = editorController.document.toPlainText();
      final regexMatch = _cachedRegex!.firstMatch(text.substring(offset));
      matchLength = regexMatch?.group(0)?.length ?? findTextController.text.length;
    } else {
      matchLength = findTextController.text.length;
    }

    editorController.replaceText(
      offset,
      matchLength,
      replaceText,
      TextSelection.collapsed(offset: offset + replaceText.length),
    );

    _runSearch();
    return true;
  }

  int replaceAllMatches() {
    if (editorController.readOnly || !hasMatches) return 0;

    final count = _matches.length;
    final replaceText = replaceTextController.text;
    final sortedMatches = List<int>.from(_matches)
      ..sort((a, b) => b.compareTo(a));

    for (final offset in sortedMatches) {
      // Calculate match length based on search mode
      int matchLength;
      if (_useRegex && _cachedRegex != null) {
        final text = editorController.document.toPlainText();
        final regexMatch = _cachedRegex!.firstMatch(text.substring(offset));
        matchLength = regexMatch?.group(0)?.length ?? findTextController.text.length;
      } else {
        matchLength = findTextController.text.length;
      }
      
      editorController.replaceText(offset, matchLength, replaceText, null);
    }

    _clearMatches();
    return count;
  }

  void _highlightCurrentMatch() {
    if (_currentMatchIndex < 0 || _currentMatchIndex >= _matches.length) return;
    
    int matchLength;
    if (_useRegex && _cachedRegex != null) {
      final text = editorController.document.toPlainText();
      final offset = _matches[_currentMatchIndex];
      final regexMatch = _cachedRegex!.firstMatch(text.substring(offset));
      matchLength = regexMatch?.group(0)?.length ?? 0;
    } else {
      matchLength = findTextController.text.length;
    }
    
    _highlightMatch(_matches[_currentMatchIndex], matchLength);
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
