// Print configuration helper
class PrintConfig {
  final double pageWidth;
  final double pageHeight;
  final double marginTop;
  final double marginBottom;
  final double marginLeft;
  final double marginRight;

  const PrintConfig({
    this.pageWidth = 816, // 8.5 inches at 96 DPI
    this.pageHeight = 1056, // 11 inches at 96 DPI
    this.marginTop = 72, // 0.75 inch
    this.marginBottom = 72,
    this.marginLeft = 72,
    this.marginRight = 72,
  });

  double get contentWidth => pageWidth - marginLeft - marginRight;
  double get contentHeight => pageHeight - marginTop - marginBottom;
}
