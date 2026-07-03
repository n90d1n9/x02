import 'package:flutter/material.dart';

/// Identifies a quick-start document template from the blank editor overlay.
enum DocumentStarterTemplateId { titlePage, meetingNotes, projectBrief }

/// Describes one blank-document starter option and its inserted content.
class DocumentStarterTemplate {
  final DocumentStarterTemplateId id;
  final IconData icon;
  final String title;
  final String subtitle;
  final String content;

  const DocumentStarterTemplate({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.content,
  });
}

/// Provides the default starter templates for new document drafts.
class DocumentStarterTemplateCatalog {
  const DocumentStarterTemplateCatalog._();

  static const templates = [
    DocumentStarterTemplate(
      id: DocumentStarterTemplateId.titlePage,
      icon: Icons.title,
      title: 'Title page',
      subtitle: 'Title, subtitle, and opening section',
      content: '# Document title\nSubtitle or summary\n\n## Overview\n',
    ),
    DocumentStarterTemplate(
      id: DocumentStarterTemplateId.meetingNotes,
      icon: Icons.groups_outlined,
      title: 'Meeting notes',
      subtitle: 'Agenda, decisions, and action items',
      content:
          '# Meeting notes\nDate:\nAttendees:\n\n## Agenda\n- \n\n'
          '## Decisions\n- \n\n## Action items\n- [ ] \n',
    ),
    DocumentStarterTemplate(
      id: DocumentStarterTemplateId.projectBrief,
      icon: Icons.assignment_outlined,
      title: 'Project brief',
      subtitle: 'Goals, scope, timeline, and risks',
      content:
          '# Project brief\n\n## Goals\n- \n\n## Scope\n- \n\n'
          '## Timeline\n- \n\n## Risks\n- \n',
    ),
  ];
}

/// Inserts starter template content into an empty document body.
class DocumentStarterTemplateApplier {
  const DocumentStarterTemplateApplier();

  void apply({
    required void Function(String content) insertContent,
    required DocumentStarterTemplate template,
  }) {
    insertContent(template.content);
  }
}
