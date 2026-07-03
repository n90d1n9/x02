import 'package:flutter/material.dart';

import '../models/export_options.dart';
import 'panel/document_panel_slider_control.dart';
import 'panel/document_panel_switch_tile.dart';
import 'panel/document_panel_text_field.dart';

/// Captures layout and metadata options before exporting a document to PDF.
class PdfExportOptionsDialog extends StatefulWidget {
  static const fontSizeSliderKey = ValueKey('pdf-export-font-size-slider');
  static const lineSpacingSliderKey = ValueKey(
    'pdf-export-line-spacing-slider',
  );

  const PdfExportOptionsDialog({super.key});

  static Future<ExportOptions?> show(BuildContext context) {
    return showDialog<ExportOptions>(
      context: context,
      builder: (context) => const PdfExportOptionsDialog(),
    );
  }

  @override
  State<PdfExportOptionsDialog> createState() => _PdfExportOptionsDialogState();
}

class _PdfExportOptionsDialogState extends State<PdfExportOptionsDialog> {
  final _headerController = TextEditingController();
  final _footerController = TextEditingController();

  bool _includePageNumbers = true;
  bool _includeMetadata = true;
  bool _includeHeader = false;
  bool _includeFooter = false;
  double _fontSize = 12.0;
  double _lineSpacing = 1.5;

  @override
  void dispose() {
    _headerController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('PDF Export Options'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DocumentPanelSwitchTile(
              icon: Icons.pin_outlined,
              title: 'Include Page Numbers',
              subtitle: 'Add generated numbers to each exported page.',
              value: _includePageNumbers,
              onChanged: (value) {
                setState(() => _includePageNumbers = value);
              },
            ),
            DocumentPanelSwitchTile(
              icon: Icons.badge_outlined,
              title: 'Include Metadata',
              subtitle: 'Author, title, and dates in PDF properties.',
              value: _includeMetadata,
              onChanged: (value) {
                setState(() => _includeMetadata = value);
              },
            ),
            DocumentPanelSwitchTile(
              icon: Icons.vertical_align_top,
              title: 'Include Header',
              subtitle: 'Repeat custom text above exported content.',
              value: _includeHeader,
              onChanged: (value) {
                setState(() => _includeHeader = value);
              },
            ),
            if (_includeHeader)
              DocumentPanelTextField(
                controller: _headerController,
                labelText: 'Header Text',
                prefixIcon: Icons.short_text,
                textInputAction: TextInputAction.done,
                padding: const EdgeInsets.fromLTRB(56, 0, 4, 0),
              ),
            const SizedBox(height: 8),
            DocumentPanelSwitchTile(
              icon: Icons.vertical_align_bottom,
              title: 'Include Footer',
              subtitle: 'Repeat custom text below exported content.',
              value: _includeFooter,
              onChanged: (value) {
                setState(() => _includeFooter = value);
              },
            ),
            if (_includeFooter)
              DocumentPanelTextField(
                controller: _footerController,
                labelText: 'Footer Text',
                prefixIcon: Icons.short_text,
                textInputAction: TextInputAction.done,
                padding: const EdgeInsets.fromLTRB(56, 0, 4, 0),
              ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            DocumentPanelSliderControl(
              sliderKey: PdfExportOptionsDialog.fontSizeSliderKey,
              icon: Icons.format_size,
              label: 'Font size',
              valueLabel: '${_fontSize.toInt()} pt',
              description: 'Tune exported body text for print readability.',
              value: _fontSize,
              min: 8,
              max: 24,
              divisions: 16,
              semanticFormatterSuffix: 'points',
              onChanged: (value) {
                setState(() => _fontSize = value);
              },
            ),
            const SizedBox(height: 8),
            DocumentPanelSliderControl(
              sliderKey: PdfExportOptionsDialog.lineSpacingSliderKey,
              icon: Icons.format_line_spacing,
              label: 'Line spacing',
              valueLabel: _lineSpacing.toStringAsFixed(1),
              description: 'Adjust paragraph rhythm in the exported PDF.',
              value: _lineSpacing,
              min: 1.0,
              max: 3.0,
              divisions: 20,
              semanticFormatterSuffix: 'line spacing',
              onChanged: (value) {
                setState(() => _lineSpacing = value);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _buildOptions()),
          child: const Text('Export'),
        ),
      ],
    );
  }

  ExportOptions _buildOptions() {
    return ExportOptions(
      includePageNumbers: _includePageNumbers,
      includeMetadata: _includeMetadata,
      includeHeader: _includeHeader,
      includeFooter: _includeFooter,
      headerText: _headerController.text.isNotEmpty
          ? _headerController.text
          : null,
      footerText: _footerController.text.isNotEmpty
          ? _footerController.text
          : null,
      fontSize: _fontSize,
      lineSpacing: _lineSpacing,
    );
  }
}
