import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/spell_check_error.dart';
import 'package:ky_docs/docx/models/spell_check_service.dart';
import 'package:ky_docs/docx/services/document_spell_check_controller.dart';

void main() {
  group('DocumentSpellCheckController', () {
    late DocumentSpellCheckController controller;
    late List<SpellCheckError> latestErrors;

    void captureErrors(List<SpellCheckError> errors) {
      latestErrors = errors;
    }

    setUp(() {
      controller = DocumentSpellCheckController(
        SpellCheckService(),
        interval: const Duration(hours: 1),
      );
      latestErrors = [];
    });

    tearDown(() {
      controller.dispose();
    });

    test('runs spell check against provided text', () {
      controller.run(readText: () => 'write wrte', onErrors: captureErrors);

      expect(latestErrors, hasLength(1));
      expect(latestErrors.single.word, 'wrte');
      expect(latestErrors.single.offset, 6);
    });

    test('starts with an immediate run and stop clears errors', () {
      var readCount = 0;

      controller.start(
        readText: () {
          readCount++;
          return 'wrte';
        },
        onErrors: captureErrors,
      );

      expect(readCount, 1);
      expect(latestErrors, isNotEmpty);

      controller.stop(onErrors: captureErrors);

      expect(latestErrors, isEmpty);
    });

    test('adding a word to dictionary removes future errors', () {
      controller.run(readText: () => 'wrte', onErrors: captureErrors);
      expect(latestErrors, isNotEmpty);

      controller.addToDictionary('wrte');
      controller.run(readText: () => 'wrte', onErrors: captureErrors);

      expect(latestErrors, isEmpty);
    });

    test('ignored words are excluded from future errors', () {
      controller.run(readText: () => 'wrte', onErrors: captureErrors);
      expect(latestErrors, isNotEmpty);

      controller.ignoreWord('wrte');
      controller.run(readText: () => 'wrte', onErrors: captureErrors);

      expect(latestErrors, isEmpty);
    });
  });
}
