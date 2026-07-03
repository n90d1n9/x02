import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/widgets/command_palette/document_command_tile_registry.dart';

void main() {
  group('DocumentCommandTileRegistry', () {
    test('reuses keys and prunes commands that are no longer visible', () {
      final registry = DocumentCommandTileRegistry();
      final firstKey = registry.keyFor('find');

      expect(registry.keyFor('find'), same(firstKey));

      registry.retainCommandIds(const ['share']);

      expect(registry.keyFor('find'), isNot(same(firstKey)));
    });
  });
}
