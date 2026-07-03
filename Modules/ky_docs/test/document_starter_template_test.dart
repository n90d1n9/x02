import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/widgets/blank_document/document_starter_template.dart';

void main() {
  group('DocumentStarterTemplateApplier', () {
    test('routes the selected starter template content', () {
      const applier = DocumentStarterTemplateApplier();
      final template = DocumentStarterTemplateCatalog.templates.firstWhere(
        (template) => template.id == DocumentStarterTemplateId.projectBrief,
      );
      String? insertedContent;

      applier.apply(
        insertContent: (content) => insertedContent = content,
        template: template,
      );

      expect(insertedContent, template.content);
      expect(insertedContent, contains('# Project brief'));
    });
  });
}
