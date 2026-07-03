import 'package:flutter/material.dart';

import '../../models/page_settings.dart';
import '../panel/document_panel_text_field.dart';

/// Identifies the page chrome region being edited from the document surface.
enum DocumentHeaderFooterRegion {
  header(
    title: 'Edit header',
    fieldLabel: 'Header text',
    fallbackText: 'Header',
    icon: Icons.vertical_align_top,
  ),
  footer(
    title: 'Edit footer',
    fieldLabel: 'Footer text',
    fallbackText: 'Footer',
    icon: Icons.vertical_align_bottom,
  );

  final String title;
  final String fieldLabel;
  final String fallbackText;
  final IconData icon;

  const DocumentHeaderFooterRegion({
    required this.title,
    required this.fieldLabel,
    required this.fallbackText,
    required this.icon,
  });
}

/// Provides a focused editor for one page header or footer band.
class DocumentHeaderFooterQuickEditDialog extends StatefulWidget {
  static const textFieldKey = ValueKey('document-header-footer-edit-field');
  static const saveButtonKey = ValueKey('document-header-footer-save');
  static const removeButtonKey = ValueKey('document-header-footer-remove');

  final DocumentHeaderFooterRegion region;
  final PageSettings pageSettings;

  const DocumentHeaderFooterQuickEditDialog({
    super.key,
    required this.region,
    required this.pageSettings,
  });

  static Future<PageSettings?> show(
    BuildContext context, {
    required DocumentHeaderFooterRegion region,
    required PageSettings pageSettings,
  }) {
    return showDialog<PageSettings>(
      context: context,
      builder: (context) => DocumentHeaderFooterQuickEditDialog(
        region: region,
        pageSettings: pageSettings,
      ),
    );
  }

  @override
  State<DocumentHeaderFooterQuickEditDialog> createState() =>
      _DocumentHeaderFooterQuickEditDialogState();
}

/// Coordinates quick-edit text state and produces updated page settings.
class _DocumentHeaderFooterQuickEditDialogState
    extends State<DocumentHeaderFooterQuickEditDialog> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: _initialText);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(widget.region.icon, size: 20),
          const SizedBox(width: 8),
          Text(widget.region.title),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: DocumentPanelTextField(
          fieldKey: DocumentHeaderFooterQuickEditDialog.textFieldKey,
          controller: _textController,
          labelText: widget.region.fieldLabel,
          hintText: widget.region.fallbackText,
          prefixIcon: Icons.short_text,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _save(),
        ),
      ),
      actions: [
        TextButton(
          key: DocumentHeaderFooterQuickEditDialog.removeButtonKey,
          onPressed: _remove,
          child: const Text('Remove'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: DocumentHeaderFooterQuickEditDialog.saveButtonKey,
          onPressed: _save,
          child: const Text('Apply'),
        ),
      ],
    );
  }

  String get _initialText {
    return switch (widget.region) {
      DocumentHeaderFooterRegion.header => widget.pageSettings.header ?? '',
      DocumentHeaderFooterRegion.footer => widget.pageSettings.footer ?? '',
    };
  }

  void _save() {
    final text = _textController.text.trim();
    Navigator.pop(context, _settingsForText(text));
  }

  void _remove() {
    Navigator.pop(context, _settingsForText(null, visible: false));
  }

  PageSettings _settingsForText(String? text, {bool visible = true}) {
    final normalizedText = text?.trim();
    final storedText = normalizedText == null || normalizedText.isEmpty
        ? null
        : normalizedText;

    return PageSettings(
      pageSize: widget.pageSettings.pageSize,
      orientation: widget.pageSettings.orientation,
      margins: widget.pageSettings.margins,
      showPageNumbers: widget.pageSettings.showPageNumbers,
      pageNumberFormat: widget.pageSettings.pageNumberFormat,
      pageNumberStart: widget.pageSettings.pageNumberStart,
      showHeader: widget.region == DocumentHeaderFooterRegion.header
          ? visible
          : widget.pageSettings.showHeader,
      header: widget.region == DocumentHeaderFooterRegion.header
          ? storedText
          : widget.pageSettings.header,
      showFooter: widget.region == DocumentHeaderFooterRegion.footer
          ? visible
          : widget.pageSettings.showFooter,
      footer: widget.region == DocumentHeaderFooterRegion.footer
          ? storedText
          : widget.pageSettings.footer,
    );
  }
}
