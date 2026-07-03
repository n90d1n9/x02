import 'package:flutter/material.dart';

import '../../models/page_orientation.dart';
import '../../models/page_settings.dart';
import '../../models/page_size.dart';
import '../panel/document_panel_section_header.dart';
import '../panel/document_panel_switch_tile.dart';
import '../panel/document_panel_text_field.dart';
import 'document_page_margin_controls.dart';
import 'document_page_preview_card.dart';

/// Edits print/export page settings for the active document.
class DocumentPageSettingsForm extends StatefulWidget {
  final PageSettings settings;
  final ValueChanged<PageSettings> onChanged;

  const DocumentPageSettingsForm({
    super.key,
    required this.settings,
    required this.onChanged,
  });

  @override
  State<DocumentPageSettingsForm> createState() =>
      _DocumentPageSettingsFormState();
}

class _DocumentPageSettingsFormState extends State<DocumentPageSettingsForm> {
  late PageSize _pageSize;
  late DocumentPageOrientation _orientation;
  late EdgeInsets _margins;
  late bool _showPageNumbers;
  late bool _showHeader;
  late bool _showFooter;
  late final TextEditingController _pageNumberFormatController;
  late final TextEditingController _headerController;
  late final TextEditingController _footerController;

  @override
  void initState() {
    super.initState();
    _applySettings(widget.settings);
    _pageNumberFormatController = TextEditingController(
      text: widget.settings.pageNumberFormat,
    )..addListener(_emitChange);
    _headerController = TextEditingController(
      text: widget.settings.header ?? '',
    )..addListener(_emitChange);
    _footerController = TextEditingController(
      text: widget.settings.footer ?? '',
    )..addListener(_emitChange);
  }

  @override
  void didUpdateWidget(covariant DocumentPageSettingsForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings == widget.settings) return;

    _applySettings(widget.settings);
    _pageNumberFormatController.text = widget.settings.pageNumberFormat;
    _headerController.text = widget.settings.header ?? '';
    _footerController.text = widget.settings.footer ?? '';
  }

  @override
  void dispose() {
    _pageNumberFormatController.dispose();
    _headerController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DocumentPagePreviewCard(settings: _draftSettings),
        const SizedBox(height: 18),
        const DocumentPanelSectionHeader(
          icon: Icons.description_outlined,
          title: 'Page size',
          description: 'Choose the target paper format for printing/export.',
        ),
        const SizedBox(height: 10),
        SegmentedButton<PageSize>(
          segments: const [
            ButtonSegment(value: PageSize.a4, label: Text('A4')),
            ButtonSegment(value: PageSize.letter, label: Text('Letter')),
            ButtonSegment(value: PageSize.legal, label: Text('Legal')),
          ],
          selected: {_pageSize},
          onSelectionChanged: (selection) {
            setState(() => _pageSize = selection.first);
            _emitChange();
          },
        ),
        const SizedBox(height: 14),
        SegmentedButton<DocumentPageOrientation>(
          segments: [
            for (final orientation in DocumentPageOrientation.values)
              ButtonSegment<DocumentPageOrientation>(
                value: orientation,
                icon: Icon(orientation.icon),
                label: Text(orientation.label),
              ),
          ],
          selected: {_orientation},
          onSelectionChanged: (selection) {
            setState(() => _orientation = selection.first);
            _emitChange();
          },
        ),
        const SizedBox(height: 18),
        const Divider(height: 1),
        const SizedBox(height: 18),
        const DocumentPanelSectionHeader(
          icon: Icons.space_dashboard_outlined,
          title: 'Margins',
          description: 'Choose a preset or enter exact page margins.',
        ),
        const SizedBox(height: 10),
        DocumentPageMarginControls(
          margins: _margins,
          onChanged: (margins) {
            setState(() => _margins = margins);
            _emitChange();
          },
        ),
        const SizedBox(height: 18),
        const Divider(height: 1),
        DocumentPanelSwitchTile(
          icon: Icons.pin_outlined,
          title: 'Page numbers',
          subtitle: 'Show a generated page number in the document chrome.',
          value: _showPageNumbers,
          onChanged: (value) {
            setState(() => _showPageNumbers = value);
            _emitChange();
          },
        ),
        if (_showPageNumbers)
          DocumentPanelTextField(
            controller: _pageNumberFormatController,
            labelText: 'Page number format',
            hintText: 'Page {n}',
            helperText: 'Use {n} for the current page number.',
            prefixIcon: Icons.tag_outlined,
            textInputAction: TextInputAction.done,
            padding: const EdgeInsets.only(left: 48, right: 4, bottom: 8),
          ),
        const SizedBox(height: 8),
        const Divider(height: 1),
        DocumentPanelSwitchTile(
          icon: Icons.vertical_align_top,
          title: 'Header',
          subtitle: 'Add repeated text above each page.',
          value: _showHeader,
          onChanged: (value) {
            setState(() => _showHeader = value);
            _emitChange();
          },
        ),
        if (_showHeader)
          DocumentPanelTextField(
            controller: _headerController,
            labelText: 'Header text',
            prefixIcon: Icons.short_text,
            textInputAction: TextInputAction.done,
            padding: const EdgeInsets.only(left: 48, right: 4, bottom: 8),
          ),
        const SizedBox(height: 8),
        const Divider(height: 1),
        DocumentPanelSwitchTile(
          icon: Icons.vertical_align_bottom,
          title: 'Footer',
          subtitle: 'Add repeated text below each page.',
          value: _showFooter,
          onChanged: (value) {
            setState(() => _showFooter = value);
            _emitChange();
          },
        ),
        if (_showFooter)
          DocumentPanelTextField(
            controller: _footerController,
            labelText: 'Footer text',
            prefixIcon: Icons.short_text,
            textInputAction: TextInputAction.done,
            padding: const EdgeInsets.only(left: 48, right: 4, bottom: 8),
          ),
      ],
    );
  }

  PageSettings get _draftSettings {
    final headerText = _headerController.text.trim();
    final footerText = _footerController.text.trim();

    return PageSettings(
      pageSize: _pageSize,
      orientation: _orientation,
      margins: _margins,
      showPageNumbers: _showPageNumbers,
      pageNumberFormat: _pageNumberFormatController.text.trim().isEmpty
          ? 'Page {n}'
          : _pageNumberFormatController.text.trim(),
      pageNumberStart: widget.settings.pageNumberStart,
      showHeader: _showHeader,
      header: _showHeader && headerText.isNotEmpty ? headerText : null,
      showFooter: _showFooter,
      footer: _showFooter && footerText.isNotEmpty ? footerText : null,
    );
  }

  void _applySettings(PageSettings settings) {
    _pageSize = settings.pageSize;
    _orientation = settings.orientation;
    _margins = settings.margins;
    _showPageNumbers = settings.showPageNumbers;
    _showHeader = settings.showHeader;
    _showFooter = settings.showFooter;
  }

  void _emitChange() {
    widget.onChanged(_draftSettings);
  }
}
