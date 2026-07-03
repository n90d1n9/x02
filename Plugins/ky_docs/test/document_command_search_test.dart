import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/widgets/command_palette/document_command.dart';
import 'package:ky_docs/docx/widgets/command_palette/document_command_search.dart';

void main() {
  group('DocumentCommandSearch', () {
    test('preserves command order for blank queries', () {
      final results = DocumentCommandSearch.filterAndSort(
        commands: [
          _command(id: 'find', title: 'Find and replace'),
          _command(id: 'share', title: 'Share document'),
        ],
        query: '   ',
      );

      expect(results.map((command) => command.id), ['find', 'share']);
    });

    test('prioritizes title matches before loose keyword matches', () {
      final results = DocumentCommandSearch.search(
        commands: [
          _command(
            id: 'review',
            title: 'Open review panel',
            keywords: const ['find'],
          ),
          _command(id: 'find', title: 'Find and replace'),
        ],
        query: 'find',
      );

      expect(results.map((result) => result.command.id), ['find', 'review']);
      expect(results.first.source, DocumentCommandMatchSource.title);
    });

    test('matches categories and compact shortcuts', () {
      final results = DocumentCommandSearch.search(
        commands: [
          _command(id: 'save', title: 'Save document', shortcut: 'Ctrl S'),
          _command(
            id: 'share',
            title: 'Share document',
            category: 'Collaborate',
          ),
        ],
        query: 'ctrls',
      );

      expect(results.single.command.id, 'save');
      expect(results.single.source, DocumentCommandMatchSource.shortcut);

      final categoryResults = DocumentCommandSearch.search(
        commands: [
          _command(id: 'save', title: 'Save document'),
          _command(
            id: 'share',
            title: 'Share document',
            category: 'Collaborate',
          ),
        ],
        query: 'collab',
      );

      expect(categoryResults.single.command.id, 'share');
      expect(
        categoryResults.single.source,
        DocumentCommandMatchSource.category,
      );
    });
  });
}

DocumentCommand _command({
  required String id,
  required String title,
  String subtitle = 'Command subtitle',
  String category = 'General',
  String? shortcut,
  List<String> keywords = const [],
}) {
  return DocumentCommand(
    id: id,
    title: title,
    subtitle: subtitle,
    icon: Icons.bolt_outlined,
    category: category,
    shortcut: shortcut,
    keywords: keywords,
    onSelected: () {},
  );
}
