import 'package:flutter/material.dart';

import '../border_style.dart' as bd;

class CellStyle {
  final bool bold;
  final bool italic;
  final bool underline;
  final Color? backgroundColor;
  final Color textColor;
  final TextAlign align;
  final double fontSize;
  final String fontFamily;
  final bd.BorderStyle? borders;
  final bool wrapText;
  final String? numberFormat;
  final bool borderTop;
  final bool borderBottom;
  final bool borderLeft;
  final bool borderRight;

  const CellStyle({
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.backgroundColor,
    this.textColor = Colors.black87,
    this.align = TextAlign.left,
    this.fontSize = 14,
    this.fontFamily = 'Roboto',
    this.borders,
    this.wrapText = false,
    this.numberFormat,
    this.borderBottom = false,
    this.borderLeft = false,
    this.borderRight = false,
    this.borderTop = false,
  });

  CellStyle copyWith({
    bool? bold,
    bool? italic,
    bool? underline,
    Color? backgroundColor,
    Color? textColor,
    TextAlign? align,
    double? fontSize,
    String? fontFamily,
    bd.BorderStyle? borders,
    bool? wrapText,
    String? numberFormat,
    bool? borderTop,
    bool? borderBottom,
    bool? borderLeft,
    bool? borderRight,
  }) {
    return CellStyle(
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      underline: underline ?? this.underline,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      align: align ?? this.align,
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      borders: borders ?? this.borders,
      wrapText: wrapText ?? this.wrapText,
      numberFormat: numberFormat ?? this.numberFormat,
      borderTop: borderTop ?? this.borderTop,
      borderBottom: borderBottom ?? this.borderBottom,
      borderLeft: borderLeft ?? this.borderLeft,
      borderRight: borderRight ?? this.borderRight,
    );
  }

  Map<String, dynamic> toJson() => {
    'bold': bold,
    'italic': italic,
    'underline': underline,
    if (backgroundColor != null) 'bgColor': backgroundColor!.toARGB32(),
    'textColor': textColor.toARGB32(),
    'align': align.index,
    'fontSize': fontSize,
    'fontFamily': fontFamily,
    if (borders != null) 'borders': borders!.toJson(),
    'wrapText': wrapText,
    if (numberFormat != null) 'numberFormat': numberFormat,
    'borderTop': borderTop,
    'borderBottom': borderBottom,
    'borderLeft': borderLeft,
    'borderRight': borderRight,
  };

  factory CellStyle.fromJson(Map<String, dynamic> json) => CellStyle(
    bold: json['bold'] ?? false,
    italic: json['italic'] ?? false,
    underline: json['underline'] ?? false,
    backgroundColor: json['bgColor'] != null ? Color(json['bgColor']) : null,
    textColor: Color(json['textColor'] ?? Colors.black87.toARGB32()),
    align: TextAlign.values[json['align'] ?? 0],
    fontSize: json['fontSize']?.toDouble() ?? 14.0,
    fontFamily: json['fontFamily'] ?? 'Roboto',
    borders: json['borders'] != null
        ? bd.BorderStyle.fromJson(json['borders'])
        : null,
    wrapText: json['wrapText'] ?? false,
    numberFormat: json['numberFormat'],
    borderTop: json['borderTop'] ?? false,
    borderBottom: json['borderBottom'] ?? false,
    borderLeft: json['borderLeft'] ?? false,
    borderRight: json['borderRight'] ?? false,
  );
}
