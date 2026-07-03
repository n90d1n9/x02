import 'package:flutter/material.dart';

/// Opens the editor command palette from the document app bar.
class DocumentCommandPaletteButton extends StatelessWidget {
  final VoidCallback onPressed;

  const DocumentCommandPaletteButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Command palette',
      icon: const Icon(Icons.manage_search),
      onPressed: onPressed,
    );
  }
}
