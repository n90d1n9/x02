import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/page_margin_preset.dart';
import '../panel/document_panel_text_field.dart';

/// Lets users choose page margin presets or enter exact point values.
class DocumentPageMarginControls extends StatefulWidget {
  static const topFieldKey = ValueKey('document-page-margin-top-field');
  static const rightFieldKey = ValueKey('document-page-margin-right-field');
  static const bottomFieldKey = ValueKey('document-page-margin-bottom-field');
  static const leftFieldKey = ValueKey('document-page-margin-left-field');

  final EdgeInsets margins;
  final ValueChanged<EdgeInsets> onChanged;

  const DocumentPageMarginControls({
    super.key,
    required this.margins,
    required this.onChanged,
  });

  @override
  State<DocumentPageMarginControls> createState() =>
      _DocumentPageMarginControlsState();
}

/// Coordinates page margin preset and exact-value editing state.
class _DocumentPageMarginControlsState
    extends State<DocumentPageMarginControls> {
  late final TextEditingController _topController;
  late final TextEditingController _rightController;
  late final TextEditingController _bottomController;
  late final TextEditingController _leftController;
  bool _syncingControllers = false;

  @override
  void initState() {
    super.initState();
    _topController = TextEditingController();
    _rightController = TextEditingController();
    _bottomController = TextEditingController();
    _leftController = TextEditingController();
    _syncTextFields(widget.margins);
    _topController.addListener(_emitFromTextFields);
    _rightController.addListener(_emitFromTextFields);
    _bottomController.addListener(_emitFromTextFields);
    _leftController.addListener(_emitFromTextFields);
  }

  @override
  void didUpdateWidget(covariant DocumentPageMarginControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.margins == widget.margins) return;

    _syncTextFields(widget.margins);
  }

  @override
  void dispose() {
    _topController.dispose();
    _rightController.dispose();
    _bottomController.dispose();
    _leftController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedPreset = DocumentPageMarginPresetMatcher.match(
      widget.margins,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<DocumentPageMarginPreset>(
          emptySelectionAllowed: true,
          showSelectedIcon: false,
          selected: selectedPreset == null ? {} : {selectedPreset},
          segments: [
            for (final preset in DocumentPageMarginPreset.values)
              ButtonSegment<DocumentPageMarginPreset>(
                value: preset,
                label: Text(preset.label),
                tooltip: preset.description,
              ),
          ],
          onSelectionChanged: (selection) {
            if (selection.isEmpty) return;
            widget.onChanged(selection.first.margins);
          },
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 420;

            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _marginNumberField(
                  fieldKey: DocumentPageMarginControls.topFieldKey,
                  controller: _topController,
                  label: 'Top',
                  width: isNarrow ? 132 : 112,
                ),
                _marginNumberField(
                  fieldKey: DocumentPageMarginControls.rightFieldKey,
                  controller: _rightController,
                  label: 'Right',
                  width: isNarrow ? 132 : 112,
                ),
                _marginNumberField(
                  fieldKey: DocumentPageMarginControls.bottomFieldKey,
                  controller: _bottomController,
                  label: 'Bottom',
                  width: isNarrow ? 132 : 112,
                ),
                _marginNumberField(
                  fieldKey: DocumentPageMarginControls.leftFieldKey,
                  controller: _leftController,
                  label: 'Left',
                  width: isNarrow ? 132 : 112,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  void _syncTextFields(EdgeInsets margins) {
    _syncingControllers = true;
    _topController.text = _formatMargin(margins.top);
    _rightController.text = _formatMargin(margins.right);
    _bottomController.text = _formatMargin(margins.bottom);
    _leftController.text = _formatMargin(margins.left);
    _syncingControllers = false;
  }

  void _emitFromTextFields() {
    if (_syncingControllers) return;

    widget.onChanged(
      EdgeInsets.fromLTRB(
        _parseMargin(_leftController.text, widget.margins.left),
        _parseMargin(_topController.text, widget.margins.top),
        _parseMargin(_rightController.text, widget.margins.right),
        _parseMargin(_bottomController.text, widget.margins.bottom),
      ),
    );
  }

  String _formatMargin(double value) {
    if (value == value.roundToDouble()) return value.round().toString();
    return value.toStringAsFixed(1);
  }

  double _parseMargin(String value, double fallback) {
    final parsed = double.tryParse(value.trim());
    if (parsed == null) return fallback;
    return parsed.clamp(0, 720).toDouble();
  }

  Widget _marginNumberField({
    required Key fieldKey,
    required TextEditingController controller,
    required String label,
    required double width,
  }) {
    return SizedBox(
      width: width,
      child: DocumentPanelTextField(
        fieldKey: fieldKey,
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')),
        ],
        labelText: label,
        suffixText: 'pt',
        textInputAction: TextInputAction.next,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
      ),
    );
  }
}
