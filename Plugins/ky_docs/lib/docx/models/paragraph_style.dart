class ParagraphStyle {
  final String alignment;
  final double? lineSpacing;
  final double? paragraphSpacing;
  final double? firstLineIndent;
  final double? leftIndent;
  final double? rightIndent;
  final String? listStyle;
  const ParagraphStyle({
    this.alignment = 'left',
    this.lineSpacing,
    this.paragraphSpacing,
    this.firstLineIndent,
    this.leftIndent,
    this.rightIndent,
    this.listStyle,
  });
}
