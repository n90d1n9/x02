import 'package:flutter/material.dart';

enum KyDocsSurface { home, library, wordEditor, liveDocs }

abstract final class KyDocsSurfaceCatalog {
  static const primary = [
    KyDocsSurface.home,
    KyDocsSurface.library,
    KyDocsSurface.wordEditor,
    KyDocsSurface.liveDocs,
  ];
}

extension KyDocsSurfaceMeta on KyDocsSurface {
  String get label {
    return switch (this) {
      KyDocsSurface.home => 'Home',
      KyDocsSurface.library => 'Documents',
      KyDocsSurface.wordEditor => 'Word Editor',
      KyDocsSurface.liveDocs => 'Live Docs',
    };
  }

  String get eyebrow {
    return switch (this) {
      KyDocsSurface.home => 'Workspace',
      KyDocsSurface.library => 'Files',
      KyDocsSurface.wordEditor => 'DOCX',
      KyDocsSurface.liveDocs => 'Collab',
    };
  }

  String get description {
    return switch (this) {
      KyDocsSurface.home => 'Create, continue, and manage documents.',
      KyDocsSurface.library => 'Browse saved drafts and document metadata.',
      KyDocsSurface.wordEditor =>
        'Edit DOCX-style documents with export tools.',
      KyDocsSurface.liveDocs =>
        'Write with comments, sharing, and live panels.',
    };
  }

  IconData get icon {
    return switch (this) {
      KyDocsSurface.home => Icons.space_dashboard_outlined,
      KyDocsSurface.library => Icons.folder_copy_outlined,
      KyDocsSurface.wordEditor => Icons.description_outlined,
      KyDocsSurface.liveDocs => Icons.edit_note_outlined,
    };
  }

  bool get opensEditor {
    return this == KyDocsSurface.wordEditor || this == KyDocsSurface.liveDocs;
  }
}
