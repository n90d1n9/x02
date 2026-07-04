import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/widgets/find_replace/find_replace_controller.dart';
import 'package:ky_docs/compat/flutter_quill_compat.dart';

void main() {
  group('DocxFindReplaceController - Regex Support', () {
    late QuillController editorController;
    late DocxFindReplaceController findReplaceController;

    setUp(() {
      editorController = QuillController.basic();
      findReplaceController = DocxFindReplaceController(
        editorController: editorController,
      );
    });

    tearDown(() {
      findReplaceController.dispose();
      editorController.dispose();
    });

    test('should enable regex mode', () {
      expect(findReplaceController.useRegex, false);
      findReplaceController.setUseRegex(true);
      expect(findReplaceController.useRegex, true);
    });

    test('should find matches using simple regex pattern', () {
      editorController.document.insert(0, 'The quick brown fox jumps over the lazy dog');
      
      findReplaceController.setUseRegex(true);
      findReplaceController.performSearch(r'\b\w+o\w+\b'); // Words containing 'o'
      
      expect(findReplaceController.hasMatches, true);
      expect(findReplaceController.matchCount, greaterThan(0));
    });

    test('should find matches using digit regex pattern', () {
      editorController.document.insert(0, 'Price: \$100, Quantity: 50, Total: \$5000');
      
      findReplaceController.setUseRegex(true);
      findReplaceController.performSearch(r'\d+'); // Find all numbers
      
      expect(findReplaceController.hasMatches, true);
      expect(findReplaceController.matchCount, 3); // 100, 50, 5000
    });

    test('should handle invalid regex gracefully', () {
      findReplaceController.setUseRegex(true);
      findReplaceController.performSearch('[invalid(regex'); // Invalid regex
      
      expect(findReplaceController.isValidRegex, false);
      expect(findReplaceController.regexError, isNotEmpty);
      expect(findReplaceController.hasMatches, false);
    });

    test('should toggle between regex and normal search', () {
      editorController.document.insert(0, 'Hello world. Hello everyone.');
      
      // Normal search
      findReplaceController.performSearch('Hello');
      final normalMatchCount = findReplaceController.matchCount;
      
      // Regex search
      findReplaceController.setUseRegex(true);
      findReplaceController.performSearch(r'H.*?o');
      final regexMatchCount = findReplaceController.matchCount;
      
      expect(normalMatchCount, 2);
      expect(regexMatchCount, greaterThanOrEqualTo(2));
    });

    test('should respect match case in regex mode', () {
      editorController.document.insert(0, 'Hello hello HELLO');
      
      findReplaceController.setUseRegex(true);
      findReplaceController.setMatchCase(true);
      findReplaceController.performSearch(r'^Hello');
      
      expect(findReplaceController.hasMatches, true);
      expect(findReplaceController.matchCount, 1); // Only "Hello" at start
    });

    test('should replace regex matches correctly', () {
      editorController.document.insert(0, 'cat bat rat');
      
      findReplaceController.setUseRegex(true);
      findReplaceController.performSearch(r'[cbr]at');
      
      expect(findReplaceController.hasMatches, true);
      expect(findReplaceController.matchCount, 3);
      
      findReplaceController.replaceTextController.text = 'mat';
      final replaced = findReplaceController.replaceAllMatches();
      
      expect(replaced, 3);
      expect(editorController.document.toPlainText(), 'mat mat mat');
    });

    test('should clear regex cache when toggling regex mode', () {
      findReplaceController.setUseRegex(true);
      findReplaceController.performSearch(r'\d+');
      expect(findReplaceController.isValidRegex, true);
      
      findReplaceController.setUseRegex(false);
      // After disabling, the regex should be cleared
      findReplaceController.performSearch('test');
      expect(findReplaceController.isValidRegex, true); // Valid because not in regex mode
    });

    test('should support whole word matching with regex', () {
      editorController.document.insert(0, 'test testing tester contest');
      
      findReplaceController.setUseRegex(true);
      findReplaceController.setWholeWord(true);
      findReplaceController.performSearch(r'test');
      
      // Should only match standalone "test", not "testing", "tester", or "contest"
      expect(findReplaceController.hasMatches, true);
      expect(findReplaceController.matchCount, 1);
    });

    test('should provide accurate match label for regex', () {
      editorController.document.insert(0, 'one two three four five');
      
      findReplaceController.setUseRegex(true);
      findReplaceController.performSearch(r'\w{4}'); // 4-letter words
      
      expect(findReplaceController.matchLabel, contains('of'));
      expect(findReplaceController.matchLabel, isNot(equals('No matches')));
    });

    test('should handle empty query in regex mode', () {
      findReplaceController.setUseRegex(true);
      findReplaceController.performSearch('');
      
      expect(findReplaceController.hasQuery, false);
      expect(findReplaceController.hasMatches, false);
      expect(findReplaceController.matchLabel, equals('Ready'));
    });
  });
}
