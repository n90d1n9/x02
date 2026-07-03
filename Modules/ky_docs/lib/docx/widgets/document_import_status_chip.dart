import 'package:flutter/material.dart';

import '../models/document_import_status.dart';

class DocumentImportStatusChip extends StatelessWidget {
  final DocumentImportStatus status;

  const DocumentImportStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    if (status.isIdle) return const SizedBox.shrink();

    final colors = _colorsFor(context, status.phase);
    return Tooltip(
      message: status.details,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 240),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: colors.foreground.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_iconFor(status.phase), size: 14, color: colors.foreground),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                status.message,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(DocumentImportPhase phase) {
    return switch (phase) {
      DocumentImportPhase.idle => Icons.check_circle_outline,
      DocumentImportPhase.picking => Icons.upload_file,
      DocumentImportPhase.importing => Icons.sync,
      DocumentImportPhase.previewing => Icons.preview,
      DocumentImportPhase.completed => Icons.task_alt,
      DocumentImportPhase.cancelled => Icons.block,
      DocumentImportPhase.failed => Icons.error_outline,
    };
  }

  _ImportChipColors _colorsFor(
    BuildContext context,
    DocumentImportPhase phase,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return switch (phase) {
      DocumentImportPhase.idle => _ImportChipColors(
        foreground: colorScheme.onSurfaceVariant,
        background: colorScheme.surfaceContainerHighest,
      ),
      DocumentImportPhase.picking ||
      DocumentImportPhase.importing => _ImportChipColors(
        foreground: colorScheme.primary,
        background: colorScheme.primaryContainer.withValues(alpha: 0.45),
      ),
      DocumentImportPhase.previewing => _ImportChipColors(
        foreground: colorScheme.secondary,
        background: colorScheme.secondaryContainer.withValues(alpha: 0.45),
      ),
      DocumentImportPhase.completed => _ImportChipColors(
        foreground: colorScheme.tertiary,
        background: colorScheme.tertiaryContainer.withValues(alpha: 0.45),
      ),
      DocumentImportPhase.cancelled => _ImportChipColors(
        foreground: colorScheme.onSurfaceVariant,
        background: colorScheme.surfaceContainerHighest,
      ),
      DocumentImportPhase.failed => _ImportChipColors(
        foreground: colorScheme.error,
        background: colorScheme.errorContainer.withValues(alpha: 0.45),
      ),
    };
  }
}

class _ImportChipColors {
  final Color foreground;
  final Color background;

  const _ImportChipColors({required this.foreground, required this.background});
}
