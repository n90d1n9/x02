import 'package:flutter/material.dart';

/// Defines the visual treatment for empty states inside document panels.
enum DocumentPanelEmptyStateTone { neutral, positive, centered }

/// Renders a reusable icon, title, message, and optional action for empty panels.
class DocumentPanelEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final DocumentPanelEmptyStateTone tone;
  final EdgeInsetsGeometry? padding;
  final Widget? action;
  final double? iconSize;

  const DocumentPanelEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.tone = DocumentPanelEmptyStateTone.neutral,
    this.padding,
    this.action,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return switch (tone) {
      DocumentPanelEmptyStateTone.centered => Center(
        child: Padding(
          padding: padding ?? const EdgeInsets.all(24),
          child: _DocumentPanelEmptyStateContent(
            icon: icon,
            title: title,
            message: message,
            tone: tone,
            action: action,
            iconSize: iconSize,
          ),
        ),
      ),
      DocumentPanelEmptyStateTone.neutral ||
      DocumentPanelEmptyStateTone.positive => _FramedPanelEmptyState(
        icon: icon,
        title: title,
        message: message,
        tone: tone,
        padding: padding,
        action: action,
        iconSize: iconSize,
      ),
    };
  }
}

/// Provides the framed card treatment for neutral and positive empty states.
class _FramedPanelEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final DocumentPanelEmptyStateTone tone;
  final EdgeInsetsGeometry? padding;
  final Widget? action;
  final double? iconSize;

  const _FramedPanelEmptyState({
    required this.icon,
    required this.title,
    required this.message,
    required this.tone,
    required this.padding,
    required this.action,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: padding ?? _defaultPadding,
      decoration: BoxDecoration(
        color: _backgroundColor(colorScheme),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor(colorScheme)),
      ),
      child: _DocumentPanelEmptyStateContent(
        icon: icon,
        title: title,
        message: message,
        tone: tone,
        action: action,
        iconSize: iconSize,
      ),
    );
  }

  EdgeInsetsGeometry get _defaultPadding {
    return switch (tone) {
      DocumentPanelEmptyStateTone.positive => const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 42,
      ),
      _ => const EdgeInsets.all(18),
    };
  }

  Color _backgroundColor(ColorScheme colorScheme) {
    return switch (tone) {
      DocumentPanelEmptyStateTone.positive => colorScheme.primary.withValues(
        alpha: 0.07,
      ),
      _ => colorScheme.surfaceContainerHighest.withValues(alpha: 0.36),
    };
  }

  Color _borderColor(ColorScheme colorScheme) {
    return switch (tone) {
      DocumentPanelEmptyStateTone.positive => colorScheme.primary.withValues(
        alpha: 0.14,
      ),
      _ => colorScheme.outlineVariant,
    };
  }
}

/// Lays out the common empty-state iconography and text stack.
class _DocumentPanelEmptyStateContent extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final DocumentPanelEmptyStateTone tone;
  final Widget? action;
  final double? iconSize;

  const _DocumentPanelEmptyStateContent({
    required this.icon,
    required this.title,
    required this.message,
    required this.tone,
    required this.action,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: tone == DocumentPanelEmptyStateTone.centered
          ? MainAxisSize.min
          : MainAxisSize.max,
      children: [
        _EmptyStateIcon(icon: icon, tone: tone, iconSize: iconSize),
        SizedBox(height: tone == DocumentPanelEmptyStateTone.neutral ? 8 : 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style:
              (tone == DocumentPanelEmptyStateTone.positive
                      ? textTheme.titleMedium
                      : textTheme.titleSmall)
                  ?.copyWith(fontWeight: FontWeight.w800),
        ),
        SizedBox(height: tone == DocumentPanelEmptyStateTone.centered ? 6 : 4),
        Text(
          message,
          textAlign: TextAlign.center,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        if (action != null) ...[const SizedBox(height: 14), action!],
      ],
    );
  }
}

/// Displays the tone-specific empty-state icon treatment.
class _EmptyStateIcon extends StatelessWidget {
  final IconData icon;
  final DocumentPanelEmptyStateTone tone;
  final double? iconSize;

  const _EmptyStateIcon({
    required this.icon,
    required this.tone,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (tone == DocumentPanelEmptyStateTone.centered) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.72),
          ),
        ),
        child: Icon(icon, size: 24, color: colorScheme.primary),
      );
    }

    return Icon(
      icon,
      size:
          iconSize ?? (tone == DocumentPanelEmptyStateTone.positive ? 46 : 24),
      color: colorScheme.primary,
    );
  }
}
