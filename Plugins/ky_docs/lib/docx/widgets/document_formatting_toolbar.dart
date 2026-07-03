import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

import 'formatting/document_formatting_ribbon_shell.dart';
import 'formatting/document_style_gallery.dart';
import 'formatting/document_style_preset_picker.dart';

/// Hosts the Quill formatting controls inside the document ribbon shell.
class DocumentFormattingToolbar extends StatelessWidget {
  static const surfaceKey = ValueKey('document-formatting-toolbar-surface');
  static const toolbarKey = ValueKey('document-formatting-toolbar');

  final quill.QuillController controller;

  const DocumentFormattingToolbar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;

        return DocumentFormattingRibbonShell(
          key: surfaceKey,
          compact: compact,
          sections: _sections(compact: compact),
          child: _ToolbarContent(
            controller: controller,
            compact: compact,
            toolbarConfig: _toolbarConfig(compact: compact),
          ),
        );
      },
    );
  }

  List<DocumentFormattingRibbonSection> _sections({required bool compact}) {
    if (compact) return const [];

    return const [
      DocumentFormattingRibbonSection(icon: Icons.text_fields, label: 'Text'),
      DocumentFormattingRibbonSection(
        icon: Icons.format_align_left,
        label: 'Paragraph',
      ),
      DocumentFormattingRibbonSection(icon: Icons.link, label: 'Insert'),
      DocumentFormattingRibbonSection(
        icon: Icons.rule_folder_outlined,
        label: 'Review',
      ),
    ];
  }

  quill.QuillSimpleToolbarConfig _toolbarConfig({required bool compact}) {
    return quill.QuillSimpleToolbarConfig(
      multiRowsDisplay: false,
      showAlignmentButtons: !compact,
      showBackgroundColorButton: !compact,
      showCenterAlignment: !compact,
      showCodeBlock: !compact,
      showColorButton: true,
      showDirection: !compact,
      showFontSize: true,
      showHeaderStyle: !compact,
      showIndent: !compact,
      showInlineCode: !compact,
      showLink: true,
      showListCheck: !compact,
      showQuote: true,
      showSearchButton: true,
      showStrikeThrough: true,
      showSubscript: !compact,
      showSuperscript: !compact,
    );
  }
}

class _ToolbarContent extends StatelessWidget {
  final quill.QuillController controller;
  final bool compact;
  final quill.QuillSimpleToolbarConfig toolbarConfig;

  const _ToolbarContent({
    required this.controller,
    required this.compact,
    required this.toolbarConfig,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (compact) ...[
          DocumentStylePresetPicker(controller: controller, expanded: true),
          const SizedBox(height: 5),
        ] else ...[
          DocumentStyleGallery(controller: controller),
          const SizedBox(height: 6),
        ],
        quill.QuillSimpleToolbar(
          key: DocumentFormattingToolbar.toolbarKey,
          controller: controller,
          config: toolbarConfig,
        ),
      ],
    );
  }
}
