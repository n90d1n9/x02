import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/widgets/blank_document/blank_document_starter_panel.dart';
import 'package:ky_docs/docx/widgets/blank_document/document_starter_template.dart';

void main() {
  group('BlankDocumentStarterPanel', () {
    testWidgets('renders starter options and dismiss action', (tester) async {
      await _pumpPanel(tester);

      expect(find.byKey(BlankDocumentStarterPanel.panelKey), findsOneWidget);
      expect(find.text('Start with structure'), findsOneWidget);
      expect(find.text('Title page'), findsOneWidget);
      expect(find.text('Meeting notes'), findsOneWidget);
      expect(find.text('Project brief'), findsOneWidget);
      expect(find.byKey(BlankDocumentStarterPanel.dismissKey), findsOneWidget);
    });

    testWidgets('routes the selected template', (tester) async {
      DocumentStarterTemplate? selectedTemplate;

      await _pumpPanel(
        tester,
        onTemplateSelected: (template) => selectedTemplate = template,
      );

      await tester.tap(
        find.byKey(const Key('blank-document-starter-template-meetingNotes')),
      );
      await tester.pump();

      expect(selectedTemplate?.id, DocumentStarterTemplateId.meetingNotes);
    });
  });
}

Future<void> _pumpPanel(
  WidgetTester tester, {
  ValueChanged<DocumentStarterTemplate>? onTemplateSelected,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 720,
          child: BlankDocumentStarterPanel(
            onTemplateSelected: onTemplateSelected ?? (_) {},
            onDismiss: () {},
          ),
        ),
      ),
    ),
  );
}
