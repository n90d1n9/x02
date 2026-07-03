import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/widgets/command_palette/document_command.dart';
import 'package:ky_docs/docx/widgets/command_palette/document_command_category_option.dart';

void main() {
  group('DocumentCommandCategoryOption', () {
    test('builds all and first-seen category options with counts', () {
      final options = DocumentCommandCategoryOption.fromCommands([
        _command(id: 'save', category: 'File'),
        _command(id: 'find', category: 'Edit'),
        _command(id: 'print', category: 'File'),
        _command(id: 'misc', category: '   '),
      ]);

      expect(options.map((option) => option.label), [
        'All',
        'File',
        'Edit',
        'General',
      ]);
      expect(options.map((option) => option.count), [4, 2, 1, 1]);
      expect(options.first.isAll, isTrue);
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
