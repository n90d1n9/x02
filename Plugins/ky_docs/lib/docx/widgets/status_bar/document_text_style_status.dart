import 'package:flutter_quill/flutter_quill.dart' as quill;

/// Summarizes the active paragraph and inline formatting near the cursor.
class DocumentTextStyleStatus {
  final String paragraphStyle;
  final bool bold;
  final bool italic;
  final bool underline;
  final bool strikethrough;
  final bool inlineCode;

  const DocumentTextStyleStatus({
    required this.paragraphStyle,
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strikethrough = false,
    this.inlineCode = false,
  });

  List<String> get inlineMarkLabels {
    return [
      if (bold) 'Bold',
      if (italic) 'Italic',
      if (underline) 'Underline',
      if (strikethrough) 'Strike',
      if (inlineCode) 'Code',
    ];
  }

  String get inlineSummary {
    final marks = inlineMarkLabels;
    if (marks.isEmpty) return 'No inline marks';
    return marks.join(', ');
  }

  String get label {
    final marks = inlineMarkLabels;
    if (marks.isEmpty) return paragraphStyle;
    return '$paragraphStyle - ${marks.join(', ')}';
  }

  String get tooltip => 'Current style: $label';

  factory DocumentTextStyleStatus.fromController({
    required quill.QuillController controller,
  }) {
    return DocumentTextStyleStatus.fromAttributes(
      controller.getSelectionStyle().attributes,
    );
  }

  factory DocumentTextStyleStatus.fromAttributes(
    Map<String, quill.Attribute> attributes,
  ) {
    return DocumentTextStyleStatus(
      paragraphStyle: _paragraphStyle(attributes),
      bold: attributes.containsKey(quill.Attribute.bold.key),
      italic: attributes.containsKey(quill.Attribute.italic.key),
      underline: attributes.containsKey(quill.Attribute.underline.key),
      strikethrough: attributes.containsKey(quill.Attribute.strikeThrough.key),
      inlineCode: attributes.containsKey(quill.Attribute.inlineCode.key),
    );
  }

  static String _paragraphStyle(Map<String, quill.Attribute> attributes) {
    final header = attributes[quill.Attribute.header.key]?.value;
    if (header is int && header > 0) return 'Heading $header';

    if (attributes.containsKey(quill.Attribute.blockQuote.key)) {
      return 'Quote';
    }
    if (attributes.containsKey(quill.Attribute.codeBlock.key)) {
      return 'Code block';
    }

    final listStyle = attributes[quill.Attribute.list.key]?.value;
    if (listStyle == quill.Attribute.ol.value) {
      return 'Numbered list';
    }
    if (listStyle == quill.Attribute.ul.value) {
      return 'Bulleted list';
    }
    if (listStyle == quill.Attribute.checked.value ||
        listStyle == quill.Attribute.unchecked.value) {
      return 'Checklist';
    }

    return 'Normal';
  }
}
