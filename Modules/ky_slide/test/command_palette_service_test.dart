import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/models/command_palette_action.dart';
import 'package:ky_slide/services/command_palette_service.dart';

void main() {
  test('filter matches command title, category, description, and keywords', () {
    final actions = [
      _action(
        id: 'slide-board',
        title: 'Open Slide Board',
        description: 'Organize and batch edit slides',
        category: 'View',
        keywords: const ['sorter', 'grid'],
      ),
      _action(
        id: 'files',
        title: 'Open Import / Export',
        description: 'Show presentation file actions',
        category: 'Files',
        keywords: const ['pptx', 'office'],
      ),
      _action(
        id: 'present',
        title: 'Start Presenting',
        description: 'Open presenter mode',
        category: 'Present',
        keywords: const ['slideshow'],
      ),
    ];

    expect(
      CommandPaletteService.filter(
        actions: actions,
        query: 'slide board',
      ).map((action) => action.id),
      ['slide-board'],
    );
    expect(
      CommandPaletteService.filter(
        actions: actions,
        query: 'files pptx',
      ).map((action) => action.id),
      ['files'],
    );
    expect(
      CommandPaletteService.filter(
        actions: actions,
        query: 'presenter mode',
      ).map((action) => action.id),
      ['present'],
    );
    expect(
      CommandPaletteService.filter(actions: actions, query: 'missing'),
      isEmpty,
    );
  });

  test('filter matches command shortcut and metadata labels', () {
    final actions = [
      _action(
        id: 'undo',
        title: 'Undo',
        description: 'Revert the latest change',
        category: 'Edit',
        keywords: const ['history'],
        shortcutLabel: 'Cmd/Ctrl+Z',
      ),
      _action(
        id: 'files',
        title: 'Open Import / Export',
        description: 'Show file actions',
        category: 'Files',
        keywords: const ['office'],
        metadataLabels: const ['Panel', 'PPTX'],
      ),
    ];

    expect(
      CommandPaletteService.filter(
        actions: actions,
        query: 'cmd ctrl z',
      ).map((action) => action.id),
      ['undo'],
    );
    expect(
      CommandPaletteService.filter(
        actions: actions,
        query: 'panel pptx',
      ).map((action) => action.id),
      ['files'],
    );
  });

  test('sections place recent commands first and group remaining commands', () {
    final actions = [
      _action(
        id: 'slide-board',
        title: 'Open Slide Board',
        description: 'Organize and batch edit slides',
        category: 'View',
        keywords: const ['sorter', 'grid'],
      ),
      _action(
        id: 'files',
        title: 'Open Import / Export',
        description: 'Show presentation file actions',
        category: 'Files',
        keywords: const ['pptx', 'office'],
      ),
      _action(
        id: 'present',
        title: 'Start Presenting',
        description: 'Open presenter mode',
        category: 'Present',
        keywords: const ['slideshow'],
      ),
    ];

    final sections = CommandPaletteService.sections(
      actions: actions,
      query: '',
      recentCommandIds: const ['files', 'missing', 'files'],
    );

    expect(sections.map((section) => section.title), [
      'Recent',
      'View',
      'Present',
    ]);
    expect(sections.first.actions.map((action) => action.id), ['files']);
    expect(
      CommandPaletteService.flattenSections(
        sections,
      ).map((action) => action.id),
      ['files', 'slide-board', 'present'],
    );
  });

  test('sections ignore recent commands while actively searching', () {
    final actions = [
      _action(
        id: 'files',
        title: 'Open Import / Export',
        description: 'Show presentation file actions',
        category: 'Files',
        keywords: const ['pptx', 'office'],
      ),
    ];

    final sections = CommandPaletteService.sections(
      actions: actions,
      query: 'files',
      recentCommandIds: const ['files'],
    );

    expect(sections.map((section) => section.title), ['Files']);
  });
}

CommandPaletteAction _action({
  required String id,
  required String title,
  required String description,
  required String category,
  required List<String> keywords,
  String? shortcutLabel,
  List<String> metadataLabels = const [],
}) {
  return CommandPaletteAction(
    id: id,
    title: title,
    description: description,
    category: category,
    icon: Icons.search,
    keywords: keywords,
    shortcutLabel: shortcutLabel,
    metadataLabels: metadataLabels,
    onInvoke: () {},
  );
}
