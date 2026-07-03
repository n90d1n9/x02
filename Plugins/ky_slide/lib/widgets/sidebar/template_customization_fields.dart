import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../models/slide_template.dart';
import '../dialogs/editor_dialog_form_section.dart';
import '../dialogs/editor_dialog_text_field.dart';

/// Editor block for a template text item used by agenda and decision templates.
class TemplateTextItemEditor extends StatelessWidget {
  final SlideTemplateTextItem item;
  final Color accentColor;
  final ValueChanged<SlideTemplateTextItem> onChanged;

  const TemplateTextItemEditor({
    super.key,
    required this.item,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return EditorDialogFieldGroup(
      title: item.label.isEmpty ? 'Item' : item.label,
      accentColor: accentColor,
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 86,
                child: EditorDialogFormTextField(
                  labelText: 'Label',
                  initialValue: item.label,
                  accentColor: accentColor,
                  onChanged: (value) {
                    onChanged(item.copyWith(label: value));
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: EditorDialogFormTextField(
                  labelText: 'Title',
                  initialValue: item.title,
                  accentColor: accentColor,
                  onChanged: (value) {
                    onChanged(item.copyWith(title: value));
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          EditorDialogFormTextField(
            labelText: 'Body',
            initialValue: item.body,
            accentColor: accentColor,
            minLines: 2,
            maxLines: 3,
            onChanged: (value) {
              onChanged(item.copyWith(body: value));
            },
          ),
        ],
      ),
    );
  }
}

/// Editor block for a metric card used by data-story templates.
class TemplateMetricEditor extends StatelessWidget {
  final SlideTemplateMetric metric;
  final Color accentColor;
  final ValueChanged<SlideTemplateMetric> onChanged;

  const TemplateMetricEditor({
    super.key,
    required this.metric,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return EditorDialogFieldGroup(
      title: metric.label.isEmpty ? 'Metric' : metric.label,
      accentColor: accentColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 420;
          final fields = _fields();

          if (compact) {
            return Column(
              children: [
                fields.metric,
                const SizedBox(height: 10),
                fields.value,
                const SizedBox(height: 10),
                fields.trend,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: fields.metric),
              const SizedBox(width: 10),
              SizedBox(width: 110, child: fields.value),
              const SizedBox(width: 10),
              SizedBox(width: 120, child: fields.trend),
            ],
          );
        },
      ),
    );
  }

  _MetricFieldSet _fields() {
    return _MetricFieldSet(
      metric: EditorDialogFormTextField(
        labelText: 'Metric',
        initialValue: metric.label,
        accentColor: accentColor,
        onChanged: (value) {
          onChanged(metric.copyWith(label: value));
        },
      ),
      value: EditorDialogFormTextField(
        labelText: 'Value',
        initialValue: metric.value,
        accentColor: accentColor,
        onChanged: (value) {
          onChanged(metric.copyWith(value: value));
        },
      ),
      trend: EditorDialogFormTextField(
        labelText: 'Trend',
        initialValue: metric.trend,
        accentColor: accentColor,
        onChanged: (value) {
          onChanged(metric.copyWith(trend: value));
        },
      ),
    );
  }
}

class _MetricFieldSet {
  final Widget metric;
  final Widget value;
  final Widget trend;

  const _MetricFieldSet({
    required this.metric,
    required this.value,
    required this.trend,
  });
}

@Preview(name: 'Template text item editor', size: Size(560, 220))
Widget templateTextItemEditorPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: SizedBox(
          width: 500,
          child: TemplateTextItemEditor(
            item: const SlideTemplateTextItem(
              label: '01',
              title: 'Context',
              body: 'What changed, why it matters, and where the risk sits.',
            ),
            accentColor: const Color(0xFF38BDF8),
            onChanged: (_) {},
          ),
        ),
      ),
    ),
  );
}

@Preview(name: 'Template metric editor', size: Size(560, 170))
Widget templateMetricEditorPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: SizedBox(
          width: 500,
          child: TemplateMetricEditor(
            metric: const SlideTemplateMetric(
              label: 'Revenue',
              value: '\$2.4M',
              trend: '+18% QoQ',
            ),
            accentColor: const Color(0xFF38BDF8),
            onChanged: (_) {},
          ),
        ),
      ),
    ),
  );
}
