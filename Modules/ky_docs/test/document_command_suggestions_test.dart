import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/widgets/command_palette/document_command.dart';
import 'package:ky_docs/docx/widgets/command_palette/document_command_suggestions.dart';

void main() {
  group('DocumentCommandSuggestions', () {
    test('returns suggested commands by priority and preserves ties', () {
      final suggestions = DocumentCommandSuggestions.fromCommands([
        _command(id: 'save', suggested: false),
        _command(id: 'review', priority: 80),
        _command(id: 'find', priority: 90),
        _command(id: 'comments', priority: 80),
      ]);

      expect(suggestions.map((command) => command.id), [
        'find',
        'review',
        'comments',
      ]);
    });

    test('limits the number of suggestions', () {
      final suggestions = DocumentCommandSuggestions.fromCommands([
        _command(id: 'one', priority: 4),
        _command(id: 'two', priority: 3),
        _command(id: 'three', priority: 2),
      ], limit: 2);

      expect(suggestions.map((command) => command.id), ['one', 'two']);
    });
  });
}

DocumentCommand _command({
  required String id,
  bool suggested = true,
  int priority = 0,
}) {
  return DocumentCommand(
    id: id,
    title: id,
    subtitle: id,
    icon: Icons.bolt_outlined,
    suggested: suggested,
    suggestionPriority: priority,
    onSelected: () {},
  );
}
