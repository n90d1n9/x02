import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/widgets/command_palette/document_command.dart';
import 'package:ky_docs/docx/widgets/command_palette/document_command_active_result.dart';

void main() {
  group('DocumentCommandActiveResult', () {
    test('uses the first visible command as the active command', () {
      final command = _command(id: 'find');
      final result = DocumentCommandActiveResult.fromCommands([
        command,
        _command(id: 'share'),
      ]);

      expect(result.hasCommand, isTrue);
      expect(result.command, same(command));
      expect(result.index, 0);
      expect(result.totalCount, 2);
      expect(result.commandId, 'find');
      expect(result.canRun, isTrue);
      expect(result.runnableCommand, same(command));
      expect(result.nextIndex, 1);
      expect(result.previousIndex, 1);
    });

    test('normalizes preferred indexes and wraps movement', () {
      final commands = [
        _command(id: 'find'),
        _command(id: 'share'),
        _command(id: 'review'),
      ];

      final middle = DocumentCommandActiveResult.fromCommands(
        commands,
        preferredIndex: 1,
      );
      final overflow = DocumentCommandActiveResult.fromCommands(
        commands,
        preferredIndex: 99,
      );

      expect(middle.commandId, 'share');
      expect(middle.nextIndex, 2);
      expect(middle.previousIndex, 0);
      expect(overflow.commandId, 'review');
      expect(overflow.nextIndex, 0);
      expect(overflow.previousIndex, 1);
    });

    test(
      'does not expose a runnable command for empty or disabled results',
      () {
        final empty = DocumentCommandActiveResult.fromCommands(const []);
        final disabled = DocumentCommandActiveResult.fromCommands([
          _command(id: 'save', enabled: false),
        ]);

        expect(empty.hasCommand, isFalse);
        expect(empty.canRun, isFalse);
        expect(empty.runnableCommand, isNull);
        expect(disabled.hasCommand, isTrue);
        expect(disabled.canRun, isFalse);
        expect(disabled.runnableCommand, isNull);
      },
    );
  });
}

DocumentCommand _command({required String id, bool enabled = true}) {
  return DocumentCommand(
    id: id,
    title: id,
    subtitle: 'Command $id',
    icon: Icons.bolt_outlined,
    enabled: enabled,
    onSelected: () {},
  );
}
