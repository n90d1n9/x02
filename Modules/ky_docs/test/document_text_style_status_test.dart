import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/widgets/status_bar/document_text_style_status.dart';

void main() {
  group('DocumentTextStyleStatus', () {
    test('describes normal text without inline marks', () {
      final status = DocumentTextStyleStatus.fromAttributes(const {});

      expect(status.paragraphStyle, 'Normal');
      expect(status.inlineMarkLabels, isEmpty);
      expect(status.inlineSummary, 'No inline marks');
      expect(status.label, 'Normal');
      expect(status.tooltip, 'Current style: Normal');
    });

    test('describes heading and inline marks', () {
      final status = DocumentTextStyleStatus.fromAttributes({
        quill.Attribute.header.key: quill.Attribute.h2,
        quill.Attribute.bold.key: quill.Attribute.bold,
        quill.Attribute.italic.key: quill.Attribute.italic,
        quill.Attribute.strikeThrough.key: quill.Attribute.strikeThrough,
        quill.Attribute.inlineCode.key: quill.Attribute.inlineCode,
      });

      expect(status.paragraphStyle, 'Heading 2');
      expect(status.inlineMarkLabels, ['Bold', 'Italic', 'Strike', 'Code']);
      expect(status.inlineSummary, 'Bold, Italic, Strike, Code');
      expect(status.label, 'Heading 2 - Bold, Italic, Strike, Code');
    });

    test('prefers quote and code block paragraph labels', () {
      final quote = DocumentTextStyleStatus.fromAttributes({
        quill.Attribute.blockQuote.key: quill.Attribute.blockQuote,
      });
      final code = DocumentTextStyleStatus.fromAttributes({
        quill.Attribute.codeBlock.key: quill.Attribute.codeBlock,
      });

      expect(quote.label, 'Quote');
      expect(code.label, 'Code block');
    });

    test('describes bullet, numbered, and checklist paragraph labels', () {
      final bullet = DocumentTextStyleStatus.fromAttributes({
        quill.Attribute.list.key: quill.Attribute.ul,
      });
      final numbered = DocumentTextStyleStatus.fromAttributes({
        quill.Attribute.list.key: quill.Attribute.ol,
      });
      final checklist = DocumentTextStyleStatus.fromAttributes({
        quill.Attribute.list.key: quill.Attribute.checked,
      });

      expect(bullet.label, 'Bulleted list');
      expect(numbered.label, 'Numbered list');
      expect(checklist.label, 'Checklist');
    });
  });
}
