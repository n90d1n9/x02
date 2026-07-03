import 'package:flutter/material.dart';

import '../../models/document_editing_mode.dart';

/// Displays a compact workspace cue for non-default document editing modes.
class DocumentEditingModeBanner extends StatelessWidget {
  static const bannerKey = ValueKey('document-editing-mode-banner');
  static const primaryActionKey = ValueKey(
    'document-editing-mode-banner-primary-action',
  );

  final DocumentEditingMode mode;
  final VoidCallback? onPrimaryAction;

  const DocumentEditingModeBanner({
    super.key,
    required this.mode,
    this.onPrimaryAction,
  });

  @override
  Widget build(BuildContext context) {
    if (!mode.showsWorkspaceBanner) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final accent = _accentColor(colorScheme);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;

        return Container(
          key: bannerKey,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 16,
            vertical: compact ? 8 : 10,
          ),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.08),
            border: Border(
              bottom: BorderSide(color: accent.withValues(alpha: 0.22)),
            ),
          ),
          child: Row(
            children: [
              Icon(mode.icon, size: 18, color: accent),
              const SizedBox(width: 10),
              Expanded(
                child: compact
                    ? Text(
                        _title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w800,
                            ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _title,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(width: 12),
              TextButton.icon(
                key: primaryActionKey,
                onPressed: onPrimaryAction,
                icon: Icon(_actionIcon, size: 17),
                label: Text(_actionLabel),
                style: TextButton.styleFrom(
                  foregroundColor: accent,
                  textStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String get _title {
    return switch (mode) {
      DocumentEditingMode.editing => 'Editing',
      DocumentEditingMode.suggesting => 'Suggesting mode',
      DocumentEditingMode.viewing => 'Viewing only',
    };
  }

  String get _subtitle {
    return switch (mode) {
      DocumentEditingMode.editing => 'Direct editing active',
      DocumentEditingMode.suggesting => 'Review suggestions active',
      DocumentEditingMode.viewing => 'Document changes are locked',
    };
  }

  String get _actionLabel {
    return switch (mode) {
      DocumentEditingMode.editing => 'Edit',
      DocumentEditingMode.suggesting => 'Review',
      DocumentEditingMode.viewing => 'Edit',
    };
  }

  IconData get _actionIcon {
    return switch (mode) {
      DocumentEditingMode.editing => Icons.edit_outlined,
      DocumentEditingMode.suggesting => Icons.rule_folder_outlined,
      DocumentEditingMode.viewing => Icons.edit_outlined,
    };
  }

  Color _accentColor(ColorScheme colorScheme) {
    return switch (mode) {
      DocumentEditingMode.editing => colorScheme.onSurfaceVariant,
      DocumentEditingMode.suggesting => colorScheme.primary,
      DocumentEditingMode.viewing => colorScheme.secondary,
    };
  }
}
