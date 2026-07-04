import 'package:flutter/material.dart';
import 'package:ky_docs/compat/flutter_quill_compat.dart' as quill;

/// Identifies a reusable document style preset in the formatting ribbon.
enum DocumentStylePresetId {
  normal,
  noSpacing,
  title,
  subtitle,
  heading1,
  heading2,
  heading3,
  heading4,
  heading5,
  heading6,
  quote,
  caption,
  code,
  listParagraph,
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
  final bool isCustom;
  final Map<String, dynamic>? customAttributes;

  const DocumentStylePreset({
    required this.id,
    required this.label,
    required this.sampleText,
    required this.description,
    required this.icon,
    this.headerLevel,
    this.blockQuote = false,
    this.isCustom = false,
    this.customAttributes,
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
      id: DocumentStylePresetId.noSpacing,
      label: 'No Spacing',
      sampleText: 'Aa',
      description: 'Compact paragraph',
      icon: Icons.format_line_spacing,
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
      id: DocumentStylePresetId.heading4,
      label: 'Heading 4',
      sampleText: 'H4',
      description: 'Minor section',
      icon: Icons.looks_4,
      headerLevel: 4,
    ),
    DocumentStylePreset(
      id: DocumentStylePresetId.heading5,
      label: 'Heading 5',
      sampleText: 'H5',
      description: 'Detail point',
      icon: Icons.looks_5,
      headerLevel: 5,
    ),
    DocumentStylePreset(
      id: DocumentStylePresetId.heading6,
      label: 'Heading 6',
      sampleText: 'H6',
      description: 'Fine detail',
      icon: Icons.looks_6,
      headerLevel: 6,
    ),
    DocumentStylePreset(
      id: DocumentStylePresetId.quote,
      label: 'Quote',
      sampleText: '"',
      description: 'Quoted block',
      icon: Icons.format_quote,
      blockQuote: true,
    ),
    DocumentStylePreset(
      id: DocumentStylePresetId.caption,
      label: 'Caption',
      sampleText: 'Cap',
      description: 'Image/table caption',
      icon: Icons.subtitles,
    ),
    DocumentStylePreset(
      id: DocumentStylePresetId.code,
      label: 'Code',
      sampleText: '</>',
      description: 'Code snippet',
      icon: Icons.code,
    ),
    DocumentStylePreset(
      id: DocumentStylePresetId.listParagraph,
      label: 'List Paragraph',
      sampleText: '•',
      description: 'Bulleted list item',
      icon: Icons.format_list_bulleted,
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

    // Handle header levels (Heading 1-6)
    if (preset.headerLevel != null) {
      controller.formatSelection(_headerAttribute(preset.headerLevel!));
      return;
    }

    // Handle block quote
    if (preset.blockQuote) {
      controller.formatSelection(quill.Attribute.blockQuote);
      return;
    }

    // Handle special styles
    switch (preset.id) {
      case DocumentStylePresetId.noSpacing:
        _applyNoSpacing(controller);
        break;
      case DocumentStylePresetId.caption:
        _applyCaption(controller);
        break;
      case DocumentStylePresetId.code:
        _applyCode(controller);
        break;
      case DocumentStylePresetId.listParagraph:
        _applyListParagraph(controller);
        break;
      case DocumentStylePresetId.normal:
        // Already cleared block styles, just ensure normal text
        break;
      default:
        break;
    }
  }

  bool isActive({
    required quill.QuillController controller,
    required DocumentStylePreset preset,
  }) {
    final attributes = controller.getSelectionStyle().attributes;
    final header = attributes[quill.Attribute.header.key];
    final hasQuote = attributes.containsKey(quill.Attribute.blockQuote.key);
    final hasCode = attributes.containsKey(quill.Attribute.inlineCode.key);

    if (preset.id == DocumentStylePresetId.normal) {
      return header == null && !hasQuote && !hasCode;
    }

    if (preset.id == DocumentStylePresetId.noSpacing) {
      return _isNoSpacingActive(attributes);
    }

    if (preset.id == DocumentStylePresetId.code) {
      return hasCode;
    }

    if (preset.id == DocumentStylePresetId.caption) {
      return _isCaptionActive(attributes);
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
    final hasCode = attributes.containsKey(quill.Attribute.inlineCode.key);

    // Check for code style first
    if (hasCode) {
      return _matchingPreset(
        presets,
        (preset) => preset.id == DocumentStylePresetId.code,
        fallback: fallbackPreset,
      );
    }

    // Check for quote
    if (hasQuote) {
      return _matchingPreset(
        presets,
        (preset) => preset.blockQuote,
        fallback: fallbackPreset,
      );
    }

    // Check for caption style
    if (_isCaptionActive(attributes)) {
      return _matchingPreset(
        presets,
        (preset) => preset.id == DocumentStylePresetId.caption,
        fallback: fallbackPreset,
      );
    }

    // Check for no spacing style
    if (_isNoSpacingActive(attributes)) {
      return _matchingPreset(
        presets,
        (preset) => preset.id == DocumentStylePresetId.noSpacing,
        fallback: fallbackPreset,
      );
    }

    // Check for header levels
    final headerValue = header?.value;
    if (headerValue is int) {
      final preferredId = switch (headerValue) {
        1 => DocumentStylePresetId.heading1,
        2 => DocumentStylePresetId.heading2,
        3 => DocumentStylePresetId.heading3,
        4 => DocumentStylePresetId.heading4,
        5 => DocumentStylePresetId.heading5,
        6 => DocumentStylePresetId.heading6,
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

  void _applyNoSpacing(quill.QuillController controller) {
    // Apply compact line spacing and remove paragraph spacing
    controller.formatSelection(
      quill.Attribute.clone(quill.Attribute.lineHeight, 1.0),
    );
  }

  bool _isNoSpacingActive(Map<String, dynamic> attributes) {
    final lineHeight = attributes[quill.Attribute.lineHeight.key];
    return lineHeight is num && lineHeight == 1.0;
  }

  void _applyCaption(quill.QuillController controller) {
    // Apply caption style: smaller font, italic, centered
    controller.formatSelection(quill.Attribute.italic);
    controller.formatSelection(
      quill.Attribute.clone(quill.Attribute.size, 12),
    );
  }

  bool _isCaptionActive(Map<String, dynamic> attributes) {
    final hasItalic = attributes.containsKey(quill.Attribute.italic.key);
    final size = attributes[quill.Attribute.size.key];
    return hasItalic && (size is num && size <= 12);
  }

  void _applyCode(quill.QuillController controller) {
    // Apply inline code style
    controller.formatSelection(quill.Attribute.inlineCode);
  }

  void _applyListParagraph(quill.QuillController controller) {
    // Apply bullet list
    controller.formatSelection(quill.Attribute.listBullet);
  }

  quill.Attribute _headerAttribute(int level) {
    return switch (level) {
      1 => quill.Attribute.h1,
      2 => quill.Attribute.h2,
      3 => quill.Attribute.h3,
      4 => quill.Attribute.h4,
      5 => quill.Attribute.h5,
      6 => quill.Attribute.h6,
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
