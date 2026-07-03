import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';

class ExportOptions {
  final PdfPageFormat pageFormat;
  final bool includeMetadata;
  final bool includePageNumbers;
  final bool includeHeader;
  final bool includeFooter;
  final String? headerText;
  final String? footerText;
  final double fontSize;
  final double lineSpacing;
  final EdgeInsets margins;
  const ExportOptions({
    this.pageFormat = PdfPageFormat.a4,
    this.includeMetadata = true,
    this.includePageNumbers = true,
    this.includeHeader = false,
    this.includeFooter = false,
    this.headerText,
    this.footerText,
    this.fontSize = 12.0,
    this.lineSpacing = 1.5,
    this.margins = const EdgeInsets.all(72),
  });
  ExportOptions copyWith({
    PdfPageFormat? pageFormat,
    bool? includeMetadata,
    bool? includePageNumbers,
    bool? includeHeader,
    bool? includeFooter,
    String? headerText,
    String? footerText,
    double? fontSize,
    double? lineSpacing,
    EdgeInsets? margins,
  }) {
    return ExportOptions(
      pageFormat: pageFormat ?? this.pageFormat,
      includeMetadata: includeMetadata ?? this.includeMetadata,
      includePageNumbers: includePageNumbers ?? this.includePageNumbers,
      includeHeader: includeHeader ?? this.includeHeader,
      includeFooter: includeFooter ?? this.includeFooter,
      headerText: headerText ?? this.headerText,
      footerText: footerText ?? this.footerText,
      fontSize: fontSize ?? this.fontSize,
      lineSpacing: lineSpacing ?? this.lineSpacing,
      margins: margins ?? this.margins,
    );
  }
}
