import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';

import '../models/document_template.dart';

final templateProvider =
    StateNotifierProvider<TemplateNotifier, List<DocumentTemplate>>((ref) {
      return TemplateNotifier();
    });

class TemplateNotifier extends StateNotifier<List<DocumentTemplate>> {
  TemplateNotifier() : super([]) {
    _loadTemplates();
  }

  void _loadTemplates() {
    state = [
      DocumentTemplate(
        id: 'blank',
        name: 'Blank Document',
        description: 'Start with an empty document',
        icon: Icons.description_outlined,
        content: '{}',
        tags: ['basic'],
        category: 'basic',
      ),
      DocumentTemplate(
        id: 'meeting_notes',
        name: 'Meeting Notes',
        description: 'Template for meeting minutes',
        icon: Icons.event_note,
        content: jsonEncode(<Map<String, dynamic>>[
          {
            'insert': 'Meeting Notes\n',
            'attributes': {'header': 1},
          },
          {'insert': '\nDate: '},
          {'insert': DateFormat('yyyy-MM-dd').format(DateTime.now())},
          {
            'insert':
                '\nAttendees:\n• \n\nAgenda:\n1. \n\nNotes:\n\n\nAction Items:\n☐ \n',
          },
        ]),
        tags: ['productivity', 'business'],
        category: 'productivity',
      ),
      DocumentTemplate(
        id: 'project_brief',
        name: 'Project Brief',
        description: 'Outline your project goals and requirements',
        icon: Icons.work_outline,
        content: jsonEncode([
          {
            'insert': 'Project Brief\n',
            'attributes': {'header': 1},
          },
          {'insert': '\nProject Name: \n\n'},
          {
            'insert': 'Overview\n',
            'attributes': {'header': 2},
          },
          {'insert': '\n\n'},
          {
            'insert': 'Objectives\n',
            'attributes': {'header': 2},
          },
          {'insert': '\n1. \n\n'},
          {
            'insert': 'Timeline\n',
            'attributes': {'header': 2},
          },
          {'insert': '\n\n'},
          {
            'insert': 'Team\n',
            'attributes': {'header': 2},
          },
          {'insert': '\n• '},
        ]),
        tags: ['productivity', 'business', 'project'],
        category: '',
      ),
      DocumentTemplate(
        id: 'blog_post',
        name: 'Blog Post',
        description: 'Structure for a blog article',
        icon: Icons.article_outlined,
        content: jsonEncode([
          {
            'insert': 'Blog Post Title\n',
            'attributes': {'header': 1},
          },
          {'insert': '\n'},
          {
            'insert': 'Introduction\n',
            'attributes': {'header': 2},
          },
          {'insert': '\n\n'},
          {
            'insert': 'Main Content\n',
            'attributes': {'header': 2},
          },
          {'insert': '\n\n'},
          {
            'insert': 'Conclusion\n',
            'attributes': {'header': 2},
          },
          {'insert': '\n'},
        ]),
        tags: ['writing', 'content'],
        category: '',
      ),
      DocumentTemplate(
        id: 'todo_list',
        name: 'To-Do List',
        description: 'Simple task checklist',
        icon: Icons.checklist,
        content: jsonEncode([
          {
            'insert': 'To-Do List\n',
            'attributes': {'header': 1},
          },
          {'insert': '\n☐ Task 1\n☐ Task 2\n☐ Task 3\n'},
        ]),
        tags: ['productivity', 'personal'],
      ),
      DocumentTemplate(
        id: 'brainstorm',
        name: 'Brainstorming',
        description: 'Capture and organize ideas',
        icon: Icons.lightbulb_outline,
        content: jsonEncode([
          {
            'insert': 'Brainstorming Session\n',
            'attributes': {'header': 1},
          },
          {'insert': '\n'},
          {
            'insert': 'Topic: \n\n',
            'attributes': {'bold': true},
          },
          {'insert': 'Ideas:\n• \n'},
        ]),
        tags: ['creative', 'planning'],
      ),
    ];
  }
}
