import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

/// Identifies a reusable document style preset in the formatting ribbon.
enum DocumentStylePresetId {
  normal,
  title,
  subtitle,
  heading1,
  heading2,
  heading3,
  quote,
}

/// Describes one quick style option in the document formatting gallery.
class DocumentStylePreset {
  final DocumentStylePresetId id;
  final String label;
  final String sampleText;
  final String description;
  final IconData icon;
  final int? headerLevel;
  final bool blockQuote;

  const DocumentStylePreset({
    required this.id,
    required this.label,
    required this.sampleText,
    required this.description,
    required this.icon,
    this.headerLevel,
    this.blockQuote = false,
  });
}

/// Provides the default Word-like style presets for the editor ribbon.
class DocumentStylePresetCatalog {
  const DocumentStylePresetCatalog._();

  static const presets = [
    DocumentStylePreset(
      id: DocumentStylePresetId.normal,
      label: 'Normal',
      sampleText: 'Aa',
      description: 'Body paragraph',
      icon: Icons.notes_outlined,
    ),
    DocumentStylePreset(
      id: DocumentStylePresetId.title,
      label: 'Title',
      sampleText: 'Tt',
      description: 'Document title',
      icon: Icons.title,
      headerLevel: 1,
    ),
    DocumentStylePreset(
      id: DocumentStylePresetId.subtitle,
      label: 'Subtitle',
      sampleText: 'St',
      description: 'Supporting title',
      icon: Icons.short_text,
      headerLevel: 2,
    ),
    DocumentStylePreset(
      id: DocumentStylePresetId.heading1,
      label: 'Heading 1',
      sampleText: 'H1',
      description: 'Major section',
      icon: Icons.filter_1,
      headerLevel: 1,
    ),
    DocumentStylePreset(
      id: DocumentStylePresetId.heading2,
      label: 'Heading 2',
      sampleText: 'H2',
      description: 'Subsection',
      icon: Icons.filter_2,
      headerLevel: 2,
    ),
    DocumentStylePreset(
      id: DocumentStylePresetId.heading3,
      label: 'Heading 3',
      sampleText: 'H3',
      description: 'Nested point',
      icon: Icons.filter_3,
      headerLevel: 3,
    ),
    DocumentStylePreset(
      id: DocumentStylePresetId.quote,
      label: 'Quote',
      sampleText: '"',
      description: 'Quoted block',
      icon: Icons.format_quote,
      blockQuote: true,
    ),
  ];
}

/// Applies document style presets to the current editor selection.
class DocumentStylePresetApplier {
  const DocumentStylePresetApplier();

  void apply({
    required quill.QuillController controller,
    required DocumentStylePreset preset,
  }) {
    _clearBlockStyle(controller);

    if (preset.headerLevel != null) {
      controller.formatSelection(_headerAttribute(preset.headerLevel!));
      return;
    }

    if (preset.blockQuote) {
      controller.formatSelection(quill.Attribute.blockQuote);
    }
  }

  bool isActive({
    required quill.QuillController controller,
    required DocumentStylePreset preset,
  }) {
    final attributes = controller.getSelectionStyle().attributes;
    final header = attributes[quill.Attribute.header.key];
    final hasQuote = attributes.containsKey(quill.Attribute.blockQuote.key);

    if (preset.id == DocumentStylePresetId.normal) {
      return header == null && !hasQuote;
    }

    if (preset.headerLevel != null) {
      return header?.value == preset.headerLevel;
    }

    return preset.blockQuote && hasQuote;
  }

  /// Resolves one display preset that best describes the current selection.
  DocumentStylePreset activePreset({
    required quill.QuillController controller,
    List<DocumentStylePreset> presets = DocumentStylePresetCatalog.presets,
  }) {
    final fallbackPreset = presets.isEmpty
        ? DocumentStylePresetCatalog.presets.first
        : presets.first;
    final attributes = controller.getSelectionStyle().attributes;
    final header = attributes[quill.Attribute.header.key];
    final hasQuote = attributes.containsKey(quill.Attribute.blockQuote.key);

    if (hasQuote) {
      return _matchingPreset(
        presets,
        (preset) => preset.blockQuote,
        fallback: fallbackPreset,
      );
    }

    final headerValue = header?.value;
    if (headerValue is int) {
      final preferredId = switch (headerValue) {
        1 => DocumentStylePresetId.heading1,
        2 => DocumentStylePresetId.heading2,
        3 => DocumentStylePresetId.heading3,
        _ => null,
      };

      if (preferredId != null) {
        return _matchingPreset(
          presets,
          (preset) => preset.id == preferredId,
          fallback: _firstHeaderPreset(presets, headerValue),
        );
      }

      return _firstHeaderPreset(presets, headerValue);
    }

    return _matchingPreset(
      presets,
      (preset) => preset.id == DocumentStylePresetId.normal,
      fallback: fallbackPreset,
    );
  }

  void _clearBlockStyle(quill.QuillController controller) {
    controller
      ..formatSelection(quill.Attribute.clone(quill.Attribute.header, null))
      ..formatSelection(
        quill.Attribute.clone(quill.Attribute.blockQuote, null),
      );
  }

  quill.Attribute _headerAttribute(int level) {
    return switch (level) {
      1 => quill.Attribute.h1,
      2 => quill.Attribute.h2,
      3 => quill.Attribute.h3,
      _ => quill.Attribute.header,
    };
  }

  DocumentStylePreset _firstHeaderPreset(
    List<DocumentStylePreset> presets,
    int headerLevel,
  ) {
    return _matchingPreset(
      presets,
      (preset) => preset.headerLevel == headerLevel,
      fallback: presets.isEmpty
          ? DocumentStylePresetCatalog.presets.first
          : presets.first,
    );
  }

  DocumentStylePreset _matchingPreset(
    List<DocumentStylePreset> presets,
    bool Function(DocumentStylePreset preset) test, {
    required DocumentStylePreset fallback,
  }) {
    for (final preset in presets) {
      if (test(preset)) return preset;
    }
    return fallback;
  }
}
