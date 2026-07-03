import 'package:flutter/material.dart';

/// Represents a single page in a print job
class PrintPage {
  /// Unique identifier for the page
  final int pageNumber;

  /// The widget content to be printed
  final Widget content;

  /// Page width in points (72 points = 1 inch)
  final double width;

  /// Page height in points
  final double height;

  /// Page margins in points
  final EdgeInsets margins;

  /// Creates a print page
  const PrintPage({
    required this.pageNumber,
    required this.content,
    this.width = 595.0, // A4 width at 72 DPI
    this.height = 842.0, // A4 height at 72 DPI
    this.margins = const EdgeInsets.all(50.0),
  });

  /// Creates a copy with updated fields
  PrintPage copyWith({
    int? pageNumber,
    Widget? content,
    double? width,
    double? height,
    EdgeInsets? margins,
  }) {
    return PrintPage(
      pageNumber: pageNumber ?? this.pageNumber,
      content: content ?? this.content,
      width: width ?? this.width,
      height: height ?? this.height,
      margins: margins ?? this.margins,
    );
  }

  @override
  String toString() => 'PrintPage(number: $pageNumber, size: ${width}x$height)';
}
