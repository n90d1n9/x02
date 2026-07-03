import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/widgets/more_options/document_more_option.dart';
import 'package:ky_docs/docx/widgets/more_options/document_more_options_filter.dart';

void main() {
  group('DocumentMoreOptionsFilter', () {
    test('preserves groups when no query is active', () {
      final filter = DocumentMoreOptionsFilter(groups: _groups());

      expect(filter.hasQuery, isFalse);
      expect(filter.visibleGroups.map((group) => group.title), [
        'Create',
        'Layout',
      ]);
      expect(filter.summary, '3 tools across 2 groups');
    });

    test('matches title, subtitle, group, shortcuts, keywords, and locks', () {
      final titleMatch = DocumentMoreOptionsFilter(
        groups: _groups(),
        query: 'insert',
      );
      final subtitleMatch = DocumentMoreOptionsFilter(
        groups: _groups(),
        query: 'headers',
      );
      final groupMatch = DocumentMoreOptionsFilter(
        groups: _groups(),
        query: 'create',
      );
      final disabledReasonMatch = DocumentMoreOptionsFilter(
        groups: _groups(),
        query: 'editing',
      );
      final shortcutMatch = DocumentMoreOptionsFilter(
        groups: _groups(),
        query: 'ctrl alt i',
      );
      final keywordMatch = DocumentMoreOptionsFilter(
        groups: _groups(),
        query: 'embed',
      );

      expect(titleMatch.visibleOptionCount, 1);
      expect(subtitleMatch.visibleOptionCount, 1);
      expect(groupMatch.visibleOptionCount, 2);
      expect(disabledReasonMatch.visibleOptionCount, 1);
      expect(shortcutMatch.visibleOptionCount, 1);
      expect(keywordMatch.visibleOptionCount, 1);
    });

    test('summarizes empty matches', () {
      final filter = DocumentMoreOptionsFilter(groups: _groups(), query: 'zip');

      expect(filter.visibleGroups, isEmpty);
      expect(filter.summary, 'No tools match "zip"');
    });
  });
}

List<DocumentMoreOptionGroup> _groups() {
  return const [
    DocumentMoreOptionGroup(
      title: 'Create',
      icon: Icons.add_box_outlined,
      options: [
        DocumentMoreOption(
          id: DocumentMoreOptionId.insertTools,
          icon: Icons.add_box_outlined,
          title: 'Insert tools',
          subtitle: 'Tables, charts, shapes',
          shortcutLabel: 'Ctrl Alt I',
          keywords: ['embed'],
        ),
        DocumentMoreOption(
          id: DocumentMoreOptionId.aiAssistant,
          icon: Icons.psychology_outlined,
          title: 'AI assistant',
          subtitle: 'Draft faster',
          enabled: false,
          disabledReason: 'Switch to Editing mode',
        ),
      ],
    ),
    DocumentMoreOptionGroup(
      title: 'Layout',
      icon: Icons.view_quilt_outlined,
      options: [
        DocumentMoreOption(
          id: DocumentMoreOptionId.pageSettings,
          icon: Icons.settings_outlined,
          title: 'Page settings',
          subtitle: 'Headers and footers',
        ),
      ],
    ),
  ];
}
