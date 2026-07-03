import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

/// Compact label used to separate groups inside editor dialog forms.
class EditorDialogSectionLabel extends StatelessWidget {
  final String label;
  final EdgeInsetsGeometry padding;

  const EditorDialogSectionLabel({
    super.key,
    required this.label,
    this.padding = const EdgeInsets.only(bottom: 10),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Framed block for related controls inside dense editor dialog forms.
class EditorDialogFieldGroup extends StatelessWidget {
  final String title;
  final Color accentColor;
  final Widget child;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;

  const EditorDialogFieldGroup({
    super.key,
    required this.title,
    required this.accentColor,
    required this.child,
    this.margin = const EdgeInsets.only(bottom: 12),
    this.padding = const EdgeInsets.all(12),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: accentColor,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

@Preview(name: 'Editor dialog section label', size: Size(320, 80))
Widget editorDialogSectionLabelPreview() {
  return const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: Color(0xFF0F172A),
      body: Center(child: EditorDialogSectionLabel(label: 'Core copy')),
    ),
  );
}

@Preview(name: 'Editor dialog field group', size: Size(420, 180))
Widget editorDialogFieldGroupPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: SizedBox(
          width: 340,
          child: EditorDialogFieldGroup(
            title: '01',
            accentColor: const Color(0xFF38BDF8),
            child: Text(
              'Grouped controls preview',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
            ),
          ),
        ),
      ),
    ),
  );
}
