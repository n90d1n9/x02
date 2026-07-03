import 'package:flutter/material.dart';

/// Provides the standard framed surface used by document side panels.
class DocumentPanelShell extends StatelessWidget {
  final Widget child;
  final bool showFrame;
  final Color? backgroundColor;
  final Color? borderColor;

  const DocumentPanelShell({
    super.key,
    required this.child,
    this.showFrame = true,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    if (!showFrame) return child;

    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor ?? colorScheme.surface,
        border: Border(
          left: BorderSide(
            color:
                borderColor ??
                colorScheme.outlineVariant.withValues(alpha: 0.7),
          ),
        ),
      ),
      child: child,
    );
  }
}
