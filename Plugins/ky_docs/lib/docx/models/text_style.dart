import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';

class TextStyle {
  final String? fontFamily;
  final double? fontSize;
  final Color? color;
  final Color? backgroundColor;
  final bool? bold;
  final bool? italic;
  final bool? underline;
  final bool? strikethrough;
  final double? letterSpacing;
  final double? lineHeight;
  const TextStyle({
    this.fontFamily,
    this.fontSize,
    this.color,
    this.backgroundColor,
    this.bold,
    this.italic,
    this.underline,
    this.strikethrough,
    this.letterSpacing,
    this.lineHeight,
  });
}
