import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/states/command_palette_provider.dart';

void main() {
  test('recent command notifier deduplicates and caps command history', () {
    final notifier = CommandPaletteRecentCommandsNotifier();

    for (final id in [
      'open',
      'duplicate',
      'delete',
      'present',
      'theme',
      'files',
      'layers',
    ]) {
      notifier.record(id);
    }

    expect(notifier.state, [
      'layers',
      'files',
      'theme',
      'present',
      'delete',
      'duplicate',
    ]);

    notifier.record('theme');

    expect(notifier.state, [
      'theme',
      'layers',
      'files',
      'present',
      'delete',
      'duplicate',
    ]);

    notifier.clear();

    expect(notifier.state, isEmpty);
  });
}
