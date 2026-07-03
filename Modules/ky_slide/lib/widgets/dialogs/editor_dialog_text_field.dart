import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

/// Text field styled for compact editor dialogs and modal workflows.
class EditorDialogTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final Color accentColor;
  final IconData? prefixIcon;
  final bool autofocus;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  const EditorDialogTextField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.accentColor,
    this.hintText,
    this.prefixIcon,
    this.autofocus = true,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      cursorColor: accentColor,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        labelStyle: const TextStyle(color: Colors.white60),
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: prefixIcon == null
            ? null
            : Icon(prefixIcon, color: accentColor, size: 18),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.055),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: accentColor),
        ),
      ),
      onSubmitted: onSubmitted,
    );
  }
}

/// Form text field variant for dialog forms that manage draft values externally.
class EditorDialogFormTextField extends StatelessWidget {
  final String labelText;
  final String initialValue;
  final Color accentColor;
  final ValueChanged<String> onChanged;
  final int minLines;
  final int maxLines;

  const EditorDialogFormTextField({
    super.key,
    required this.labelText,
    required this.initialValue,
    required this.accentColor,
    required this.onChanged,
    this.minLines = 1,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: ValueKey('$labelText-$initialValue'),
      initialValue: initialValue,
      minLines: minLines,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      cursorColor: accentColor,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: Colors.white60),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.055),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: accentColor),
        ),
      ),
      onChanged: onChanged,
    );
  }
}

@Preview(name: 'Editor dialog text field', size: Size(420, 120))
Widget editorDialogTextFieldPreview() {
  final controller = TextEditingController(text: 'Quarterly review');

  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: SizedBox(
          width: 340,
          child: EditorDialogTextField(
            controller: controller,
            labelText: 'Layer name',
            hintText: 'Title block',
            prefixIcon: Icons.layers_outlined,
            accentColor: const Color(0xFF38BDF8),
          ),
        ),
      ),
    ),
  );
}

@Preview(name: 'Editor dialog form field', size: Size(420, 140))
Widget editorDialogFormTextFieldPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: SizedBox(
          width: 340,
          child: EditorDialogFormTextField(
            labelText: 'Headline',
            initialValue: 'Quarterly review',
            accentColor: const Color(0xFF38BDF8),
            onChanged: (_) {},
          ),
        ),
      ),
    ),
  );
}
