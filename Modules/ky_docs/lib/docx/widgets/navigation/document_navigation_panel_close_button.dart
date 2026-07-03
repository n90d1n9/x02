import 'package:flutter/material.dart';

/// Provides a compact close action for dismissing document navigation rails.
class DocumentNavigationPanelCloseButton extends StatelessWidget {
  final VoidCallback onPressed;

  const DocumentNavigationPanelCloseButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Close navigation panel',
      icon: const Icon(Icons.close, size: 18),
      visualDensity: VisualDensity.compact,
      onPressed: onPressed,
    );
  }
}
