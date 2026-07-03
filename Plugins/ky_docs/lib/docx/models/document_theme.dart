import 'package:flutter/material.dart';

import 'text_style.dart' as style;

class DocumentTheme {
  final String name;
  final Color primaryColor;
  final Color accentColor;
  final String defaultFont;
  final double defaultFontSize;
  final Map<int, style.TextStyle> headingStyles;
  DocumentTheme({
    required this.name,
    required this.primaryColor,
    required this.accentColor,
    required this.defaultFont,
    this.defaultFontSize = 12.0,
    this.headingStyles = const {},
  });
  static final List<DocumentTheme> predefinedThemes = [
    DocumentTheme(
      name: 'Default',
      primaryColor: Colors.blue,
      accentColor: Colors.blueAccent,
      defaultFont: 'Roboto',
    ),
    DocumentTheme(
      name: 'Professional',
      primaryColor: Colors.grey,
      accentColor: Colors.blueGrey,
      defaultFont: 'Times New Roman',
    ),
    DocumentTheme(
      name: 'Modern',
      primaryColor: Colors.purple,
      accentColor: Colors.deepPurple,
      defaultFont: 'Arial',
    ),
    DocumentTheme(
      name: 'Elegant',
      primaryColor: Colors.brown,
      accentColor: Colors.amber,
      defaultFont: 'Georgia',
    ),
  ];
}
