import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../models/slide_template.dart';
import '../dialogs/editor_dialog_form_section.dart';
import '../dialogs/editor_dialog_text_field.dart';

typedef TemplateCoreCopyChanged =
    void Function({
      String? eyebrow,
      String? headline,
      String? subheadline,
      String? footer,
    });

/// Editor for headline-level copy shared by slide template customizers.
class TemplateCoreCopyEditor extends StatelessWidget {
  final SlideTemplateType type;
  final SlideTemplateCustomization customization;
  final Color accentColor;
  final TemplateCoreCopyChanged onChanged;

  const TemplateCoreCopyEditor({
    super.key,
    required this.type,
    required this.customization,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const EditorDialogSectionLabel(label: 'Core copy'),
        if (type == SlideTemplateType.executiveCover) ...[
          _field(
            label: 'Eyebrow',
            initialValue: customization.eyebrow,
            onChanged: (value) => onChanged(eyebrow: value),
          ),
          const SizedBox(height: 10),
        ],
        _field(
          label: 'Headline',
          initialValue: customization.headline,
          minLines: 2,
          maxLines: 3,
          onChanged: (value) => onChanged(headline: value),
        ),
        if (type != SlideTemplateType.comparison) ...[
          const SizedBox(height: 10),
          _field(
            label: 'Supporting copy',
            initialValue: customization.subheadline,
            minLines: 2,
            maxLines: 4,
            onChanged: (value) => onChanged(subheadline: value),
          ),
        ],
        if (type == SlideTemplateType.executiveCover) ...[
          const SizedBox(height: 10),
          _field(
            label: 'Footer',
            initialValue: customization.footer,
            onChanged: (value) => onChanged(footer: value),
          ),
        ],
      ],
    );
  }

  Widget _field({
    required String label,
    required String initialValue,
    required ValueChanged<String> onChanged,
    int minLines = 1,
    int maxLines = 1,
  }) {
    return EditorDialogFormTextField(
      key: ValueKey('$type-$label-$initialValue'),
      labelText: label,
      initialValue: initialValue,
      accentColor: accentColor,
      minLines: minLines,
      maxLines: maxLines,
      onChanged: onChanged,
    );
  }
}

@Preview(name: 'Template core copy editor', size: Size(560, 300))
Widget templateCoreCopyEditorPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: SizedBox(
          width: 500,
          child: TemplateCoreCopyEditor(
            type: SlideTemplateType.executiveCover,
            customization: SlideTemplateCustomization.defaultsFor(
              SlideTemplateType.executiveCover,
            ),
            accentColor: const Color(0xFF38BDF8),
            onChanged: ({eyebrow, headline, subheadline, footer}) {},
          ),
        ),
      ),
    ),
  );
}
