import 'spell_check_error.dart';

class SpellCheckService {
  final Set<String> _dictionary = {
    'the',
    'be',
    'to',
    'of',
    'and',
    'a',
    'in',
    'that',
    'have',
    'i',
    'it',
    'for',
    'not',
    'on',
    'with',
    'he',
    'as',
    'you',
    'do',
    'at',
    'this',
    'but',
    'his',
    'by',
    'from',
    'they',
    'we',
    'say',
    'her',
    'she',
    'or',
    'an',
    'will',
    'my',
    'one',
    'all',
    'would',
    'there',
    'their',
    'what',
    'so',
    'up',
    'out',
    'if',
    'about',
    'who',
    'get',
    'which',
    'go',
    'me',
    'when',
    'make',
    'can',
    'like',
    'time',
    'no',
    'just',
    'him',
    'know',
    'take',
    'people',
    'into',
    'year',
    'your',
    'good',
    'some',
    'could',
    'them',
    'see',
    'other',
    'than',
    'then',
    'now',
    'look',
    'only',
    'come',
    'its',
    'over',
    'think',
    'also',
    'back',
    'after',
    'use',
    'two',
    'how',
    'our',
    'work',
    'first',
    'well',
    'way',
    'even',
    'new',
    'want',
    'because',
    'any',
    'these',
    'give',
    'day',
    'most',
    'us',
    'is',
    'was',
    'are',
    'been',
    'has',
    'had',
    'were',
    'said',
    'did',
    'document',
    'editor',
    'text',
    'write',
    'save',
    'export',
    'import',
    'file',
  };
  final Set<String> _ignoredWords = {};
  List<SpellCheckError> checkText(String text) {
    final errors = <SpellCheckError>[];
    final words = _extractWords(text);
    int offset = 0;
    for (final word in words) {
      final cleanWord = word.toLowerCase().replaceAll(RegExp(r'[^\w]'), '');
      if (cleanWord.isNotEmpty &&
          !_dictionary.contains(cleanWord) &&
          !_ignoredWords.contains(cleanWord) &&
          !_isNumber(cleanWord)) {
        final suggestions = _generateSuggestions(cleanWord);
        errors.add(
          SpellCheckError(word: word, offset: offset, suggestions: suggestions),
        );
      }
      offset += word.length + 1;
    }
    return errors;
  }

  List<String> _extractWords(String text) {
    return text.split(RegExp(r'\s+'));
  }

  bool _isNumber(String word) {
    return double.tryParse(word) != null;
  }

  List<String> _generateSuggestions(String word) {
    final suggestions = <String>[];
    for (final dictWord in _dictionary) {
      if (_calculateLevenshteinDistance(word, dictWord) <= 2) {
        suggestions.add(dictWord);
      }
      if (suggestions.length >= 5) {
        break;
      }
    }
    return suggestions;
  }

  int _calculateLevenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;
    final len1 = s1.length;
    final len2 = s2.length;
    final matrix = List.generate(
      len1 + 1,
      (_) => List<int>.filled(len2 + 1, 0),
    );
    for (int i = 0; i <= len1; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= len2; j++) {
      matrix[0][j] = j;
    }
    for (int i = 1; i <= len1; i++) {
      for (int j = 1; j <= len2; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }
    return matrix[len1][len2];
  }

  void addToDictionary(String word) {
    _dictionary.add(word.toLowerCase());
  }

  void ignoreWord(String word) {
    _ignoredWords.add(word.toLowerCase());
  }

  void clearIgnored() {
    _ignoredWords.clear();
  }
}
