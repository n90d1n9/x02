import 'package:flutter/material.dart';

/// Opens document sharing controls and displays collaboration state.
class DocumentShareButton extends StatelessWidget {
  final bool collaborationEnabled;
  final int collaboratorCount;
  final bool showLabel;
  final VoidCallback onPressed;

  const DocumentShareButton({
    super.key,
    required this.collaborationEnabled,
    required this.collaboratorCount,
    this.showLabel = true,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final label = collaborationEnabled ? 'Shared' : 'Share';
    final semanticLabel = collaborationEnabled
        ? 'Sharing active, $collaboratorCount collaborators'
        : 'Share document';
    final button = _ShareButtonFrame(
      collaboratorCount: collaboratorCount,
      showBadge: collaborationEnabled && collaboratorCount > 0,
      child: showLabel
          ? FilledButton.tonalIcon(
              onPressed: onPressed,
              icon: Icon(collaborationEnabled ? Icons.group : Icons.lock),
              label: Text(label),
            )
          : IconButton.filledTonal(
              tooltip: label,
              onPressed: onPressed,
              icon: Icon(collaborationEnabled ? Icons.group : Icons.lock),
            ),
    );
    final semanticButton = Semantics(
      button: true,
      label: semanticLabel,
      child: button,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: showLabel
          ? Tooltip(message: label, child: semanticButton)
          : semanticButton,
    );
  }
}

class _ShareButtonFrame extends StatelessWidget {
  final int collaboratorCount;
  final bool showBadge;
  final Widget child;

  const _ShareButtonFrame({
    required this.collaboratorCount,
    required this.showBadge,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!showBadge) return child;

    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -4,
          right: -2,
          child: Container(
            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
            padding: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: colorScheme.surface, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(
              '$collaboratorCount',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
