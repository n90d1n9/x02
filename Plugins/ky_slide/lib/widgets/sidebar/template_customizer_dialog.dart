import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../models/slide_template.dart';
import '../../services/slide_template_service.dart';
import '../dialogs/editor_dialog_frame.dart';
import '../dialogs/editor_dialog_form_section.dart';
import 'template_core_copy_editor.dart';
import 'template_customization_fields.dart';

/// Dialog for customizing template copy before creating a designed slide.
class TemplateCustomizerDialog extends StatefulWidget {
  final SlideTemplateRecipe recipe;
  final Color accentColor;
  final ValueChanged<SlideTemplateCustomization> onCreate;

  const TemplateCustomizerDialog({
    super.key,
    required this.recipe,
    required this.accentColor,
    required this.onCreate,
  });

  @override
  State<TemplateCustomizerDialog> createState() =>
      _TemplateCustomizerDialogState();
}

/// Stateful form controller for template draft copy and repeated content blocks.
class _TemplateCustomizerDialogState extends State<TemplateCustomizerDialog> {
  late SlideTemplateCustomization _draft;

  @override
  void initState() {
    super.initState();
    _draft = SlideTemplateCustomization.defaultsFor(widget.recipe.type);
  }

  @override
  Widget build(BuildContext context) {
    return EditorDialogFrame(
      title: widget.recipe.name,
      icon: Icons.tune,
      accentColor: widget.accentColor,
      width: 560,
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TemplateCoreCopyEditor(
              type: widget.recipe.type,
              customization: _draft,
              accentColor: widget.accentColor,
              onChanged: ({eyebrow, headline, subheadline, footer}) {
                _draft = _draft.copyWith(
                  eyebrow: eyebrow,
                  headline: headline,
                  subheadline: subheadline,
                  footer: footer,
                );
              },
            ),
            ..._templateSpecificFields(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: Colors.white70),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () {
            widget.onCreate(_draft);
            Navigator.pop(context);
          },
          style: EditorDialogFrame.accentButtonStyle(widget.accentColor),
          icon: const Icon(Icons.add),
          label: const Text('Create slide'),
        ),
      ],
    );
  }

  List<Widget> _templateSpecificFields() {
    switch (widget.recipe.type) {
      case SlideTemplateType.executiveCover:
        return const [];
      case SlideTemplateType.agenda:
        return [
          const SizedBox(height: 18),
          const EditorDialogSectionLabel(label: 'Agenda items'),
          ...List.generate(_draft.items.length, _itemFields),
        ];
      case SlideTemplateType.metricStory:
        return [
          const SizedBox(height: 18),
          const EditorDialogSectionLabel(label: 'Metric cards'),
          ...List.generate(_draft.metrics.length, _metricFields),
        ];
      case SlideTemplateType.comparison:
        return [
          const SizedBox(height: 18),
          const EditorDialogSectionLabel(label: 'Decision blocks'),
          ...List.generate(_draft.items.length, _itemFields),
        ];
    }
  }

  Widget _itemFields(int index) {
    final item = _draft.items[index];

    return TemplateTextItemEditor(
      item: item,
      accentColor: widget.accentColor,
      onChanged: (updated) => _updateItem(index, updated),
    );
  }

  Widget _metricFields(int index) {
    final metric = _draft.metrics[index];

    return TemplateMetricEditor(
      metric: metric,
      accentColor: widget.accentColor,
      onChanged: (updated) => _updateMetric(index, updated),
    );
  }

  void _updateItem(int index, SlideTemplateTextItem item) {
    final items = [..._draft.items];
    items[index] = item;
    _draft = _draft.copyWith(items: items);
  }

  void _updateMetric(int index, SlideTemplateMetric metric) {
    final metrics = [..._draft.metrics];
    metrics[index] = metric;
    _draft = _draft.copyWith(metrics: metrics);
  }
}

@Preview(name: 'Template customizer dialog', size: Size(680, 640))
Widget templateCustomizerDialogPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: TemplateCustomizerDialog(
          recipe: SlideTemplateService.recipeFor(SlideTemplateType.agenda),
          accentColor: const Color(0xFF38BDF8),
          onCreate: (_) {},
        ),
      ),
    ),
  );
}
