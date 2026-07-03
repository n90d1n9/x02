import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/models/slide_template.dart';
import 'package:ky_slide/services/slide_template_service.dart';
import 'package:ky_slide/widgets/dialogs/editor_dialog_frame.dart';
import 'package:ky_slide/widgets/dialogs/editor_dialog_form_section.dart';
import 'package:ky_slide/widgets/dialogs/editor_dialog_text_field.dart';
import 'package:ky_slide/widgets/sidebar/layer_rename_dialog.dart';
import 'package:ky_slide/widgets/sidebar/template_core_copy_editor.dart';
import 'package:ky_slide/widgets/sidebar/template_customization_fields.dart';
import 'package:ky_slide/widgets/sidebar/template_customizer_dialog.dart';

void main() {
  testWidgets('editor dialog frame renders shared chrome and actions', (
    tester,
  ) async {
    var saved = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EditorDialogFrame(
            title: 'Rename layer',
            icon: Icons.drive_file_rename_outline,
            accentColor: const Color(0xFF38BDF8),
            content: const Text('Layer naming surface'),
            actions: [
              TextButton(onPressed: () {}, child: const Text('Cancel')),
              FilledButton(
                onPressed: () => saved = true,
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Rename layer'), findsOneWidget);
    expect(find.byIcon(Icons.drive_file_rename_outline), findsOneWidget);
    expect(find.text('Layer naming surface'), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(saved, isTrue);
  });

  testWidgets('editor dialog text field submits the edited value', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    String? submitted;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EditorDialogTextField(
            controller: controller,
            labelText: 'Layer name',
            hintText: 'Title block',
            prefixIcon: Icons.layers_outlined,
            accentColor: const Color(0xFF38BDF8),
            textInputAction: TextInputAction.done,
            onSubmitted: (value) => submitted = value,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'Hero title');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(submitted, 'Hero title');
  });

  testWidgets('editor dialog form text field emits changed values', (
    tester,
  ) async {
    String? changed;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EditorDialogFormTextField(
            labelText: 'Headline',
            initialValue: 'Quarterly review',
            accentColor: const Color(0xFF38BDF8),
            onChanged: (value) => changed = value,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField), 'Strategy review');
    await tester.pumpAndSettle();

    expect(changed, 'Strategy review');
  });

  testWidgets('editor dialog form sections render reusable grouping chrome', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              const EditorDialogSectionLabel(label: 'Core copy'),
              EditorDialogFieldGroup(
                title: '01',
                accentColor: const Color(0xFF38BDF8),
                child: const Text('Field group content'),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Core copy'), findsOneWidget);
    expect(find.text('01'), findsOneWidget);
    expect(find.text('Field group content'), findsOneWidget);
  });

  testWidgets('template text item editor emits updated text items', (
    tester,
  ) async {
    SlideTemplateTextItem? changed;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 520,
            child: TemplateTextItemEditor(
              item: const SlideTemplateTextItem(
                label: '01',
                title: 'Context',
                body: 'What changed.',
              ),
              accentColor: const Color(0xFF38BDF8),
              onChanged: (value) => changed = value,
            ),
          ),
        ),
      ),
    );

    await tester.enterText(_formField('Title'), 'Decision');
    await tester.pumpAndSettle();

    expect(changed?.label, '01');
    expect(changed?.title, 'Decision');
    expect(changed?.body, 'What changed.');
  });

  testWidgets('template metric editor emits updated metrics', (tester) async {
    SlideTemplateMetric? changed;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 520,
            child: TemplateMetricEditor(
              metric: const SlideTemplateMetric(
                label: 'Revenue',
                value: '\$2.4M',
                trend: '+18% QoQ',
              ),
              accentColor: const Color(0xFF38BDF8),
              onChanged: (value) => changed = value,
            ),
          ),
        ),
      ),
    );

    await tester.enterText(_formField('Trend'), '+22% QoQ');
    await tester.pumpAndSettle();

    expect(changed?.label, 'Revenue');
    expect(changed?.value, '\$2.4M');
    expect(changed?.trend, '+22% QoQ');
  });

  testWidgets('template core copy editor emits targeted copy updates', (
    tester,
  ) async {
    String? changedHeadline;
    String? changedSubheadline;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 520,
            child: TemplateCoreCopyEditor(
              type: SlideTemplateType.agenda,
              customization: SlideTemplateCustomization.defaultsFor(
                SlideTemplateType.agenda,
              ),
              accentColor: const Color(0xFF38BDF8),
              onChanged: ({eyebrow, headline, subheadline, footer}) {
                changedHeadline = headline;
                changedSubheadline = subheadline;
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('Core copy'), findsOneWidget);
    expect(find.text('Supporting copy'), findsOneWidget);

    await tester.enterText(_formField('Headline'), 'Roadmap Review');
    await tester.pumpAndSettle();

    expect(changedHeadline, 'Roadmap Review');

    await tester.enterText(_formField('Supporting copy'), 'Next month focus.');
    await tester.pumpAndSettle();

    expect(changedSubheadline, 'Next month focus.');
  });

  testWidgets('template core copy editor adapts fields by template type', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 520,
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

    expect(find.text('Eyebrow'), findsOneWidget);
    expect(find.text('Footer'), findsOneWidget);
    expect(find.text('Supporting copy'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 520,
            child: TemplateCoreCopyEditor(
              type: SlideTemplateType.comparison,
              customization: SlideTemplateCustomization.defaultsFor(
                SlideTemplateType.comparison,
              ),
              accentColor: const Color(0xFF38BDF8),
              onChanged: ({eyebrow, headline, subheadline, footer}) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Headline'), findsOneWidget);
    expect(find.text('Eyebrow'), findsNothing);
    expect(find.text('Footer'), findsNothing);
    expect(find.text('Supporting copy'), findsNothing);
  });

  testWidgets('layer rename dialog submits names and clears custom labels', (
    tester,
  ) async {
    String? renamed;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (context) => LayerRenameDialog(
                      initialName: 'Old name',
                      fallbackName: 'Title text',
                      accentColor: const Color(0xFF38BDF8),
                      onRename: (value) => renamed = value,
                    ),
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '  New name  ');
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();

    expect(renamed, '  New name  ');

    renamed = 'unchanged';
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Use content'));
    await tester.pumpAndSettle();

    expect(renamed, isNull);
  });

  testWidgets('template customizer dialog submits customized copy', (
    tester,
  ) async {
    SlideTemplateCustomization? customization;
    final recipe = SlideTemplateService.recipeFor(SlideTemplateType.agenda);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (context) => TemplateCustomizerDialog(
                      recipe: recipe,
                      accentColor: const Color(0xFF38BDF8),
                      onCreate: (value) => customization = value,
                    ),
                  );
                },
                child: const Text('Open template'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open template'));
    await tester.pumpAndSettle();

    expect(find.byType(EditorDialogFrame), findsOneWidget);
    expect(find.text('Agenda Flow'), findsOneWidget);

    await tester.enterText(_formField('Headline'), 'Roadmap Review');
    await tester.enterText(
      _formField('Supporting copy'),
      'Priorities for the next month.',
    );
    await tester.tap(find.text('Create slide'));
    await tester.pumpAndSettle();

    expect(customization?.headline, 'Roadmap Review');
    expect(customization?.subheadline, 'Priorities for the next month.');
    expect(customization?.items, hasLength(4));
  });
}

Finder _formField(String label) {
  return find.ancestor(
    of: find.text(label),
    matching: find.byType(TextFormField),
  );
}
