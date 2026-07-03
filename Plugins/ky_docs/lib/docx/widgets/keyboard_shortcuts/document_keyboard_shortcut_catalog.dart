import 'package:flutter/material.dart';

import 'document_keyboard_shortcut.dart';

const documentKeyboardShortcutGroups = [
  DocumentKeyboardShortcutGroup(
    title: 'Document',
    icon: Icons.description_outlined,
    shortcuts: [
      DocumentKeyboardShortcut(
        label: 'Save document',
        keys: ['Ctrl', 'S'],
        keywords: ['sync'],
      ),
      DocumentKeyboardShortcut(label: 'New document', keys: ['Ctrl', 'N']),
      DocumentKeyboardShortcut(
        label: 'Command palette',
        keys: ['Ctrl/Cmd', 'K'],
        keywords: ['search', 'commands'],
      ),
      DocumentKeyboardShortcut(
        label: 'Find in document',
        keys: ['Ctrl', 'F'],
        keywords: ['search'],
      ),
      DocumentKeyboardShortcut(
        label: 'Find and replace',
        keys: ['Ctrl', 'H'],
        keywords: ['replace'],
      ),
      DocumentKeyboardShortcut(label: 'Print document', keys: ['Ctrl', 'P']),
    ],
  ),
  DocumentKeyboardShortcutGroup(
    title: 'Formatting',
    icon: Icons.format_bold,
    shortcuts: [
      DocumentKeyboardShortcut(label: 'Bold', keys: ['Ctrl', 'B']),
      DocumentKeyboardShortcut(label: 'Italic', keys: ['Ctrl', 'I']),
      DocumentKeyboardShortcut(label: 'Underline', keys: ['Ctrl', 'U']),
    ],
  ),
  DocumentKeyboardShortcutGroup(
    title: 'Selection',
    icon: Icons.select_all_outlined,
    shortcuts: [
      DocumentKeyboardShortcut(label: 'Select all', keys: ['Ctrl', 'A']),
      DocumentKeyboardShortcut(label: 'Copy', keys: ['Ctrl', 'C']),
      DocumentKeyboardShortcut(label: 'Paste', keys: ['Ctrl', 'V']),
      DocumentKeyboardShortcut(label: 'Cut', keys: ['Ctrl', 'X']),
      DocumentKeyboardShortcut(label: 'Undo', keys: ['Ctrl', 'Z']),
      DocumentKeyboardShortcut(label: 'Redo', keys: ['Ctrl', 'Y']),
    ],
  ),
];
