import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/widgets/command_palette/document_command.dart';
import 'package:ky_docs/docx/widgets/command_palette/document_command_preview_model.dart';

void main() {
  group('DocumentCommandPreviewModel', () {
    test('describes enabled commands with category and shortcut metadata', () {
      final model = DocumentCommandPreviewModel(
        command: DocumentCommand(
          id: 'find',
          title: 'Find and replace',
          subtitle: 'Search the document',
          icon: Icons.find_replace,
          category: 'Edit',
          shortcut: 'Ctrl F',
          onSelected: () {},
        ),
      );

      expect(model.isEnabled, isTrue);
      expect(model.categoryLabel, 'Edit');
      expect(model.statusLabel, 'Ready');
      expect(model.statusDescription, 'Runs from Edit commands.');
      expect(model.shortcutLabel, 'Ctrl F');
    });

    test('describes disabled commands with fallback labels', () {
      final model = DocumentCommandPreviewModel(
        command: DocumentCommand(
          id: 'save',
          title: 'Save document',
          subtitle: 'No unsaved changes',
          icon: Icons.save_outlined,
          category: '  ',
          enabled: false,
          onSelected: () {},
        ),
      );

      expect(model.isEnabled, isFalse);
      expect(model.categoryLabel, 'General');
      expect(model.statusLabel, 'Unavailable');
      expect(
        model.statusDescription,
        'This command is not available right now.',
      );
      expect(model.shortcutLabel, isNull);
    });
  });
}
