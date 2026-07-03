import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/widgets/command_palette/document_command.dart';
import 'package:ky_docs/docx/widgets/command_palette/document_command_section.dart';

void main() {
  group('DocumentCommandSection', () {
    test('groups commands by category while preserving first-seen order', () {
      final sections = DocumentCommandSection.fromCommands([
        _command(id: 'save', category: 'File'),
        _command(id: 'find', category: 'Edit'),
        _command(id: 'print', category: 'File'),
      ]);

      expect(sections.map((section) => section.category), ['File', 'Edit']);
      expect(sections.first.commands.map((command) => command.id), [
        'save',
        'print',
      ]);
    });

    test('falls back to general for blank categories', () {
      final sections = DocumentCommandSection.fromCommands([
        _command(id: 'misc', category: '   '),
      ]);

      expect(sections.single.category, 'General');
    });
  });
}

DocumentCommand _command({required String id, required String category}) {
  return DocumentCommand(
    id: id,
    title: id,
    subtitle: id,
    icon: Icons.bolt_outlined,
    category: category,
    onSelected: () {},
  );
}
