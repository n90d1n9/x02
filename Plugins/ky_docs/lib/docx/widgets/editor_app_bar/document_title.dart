import 'package:flutter/material.dart';

/// Displays the editable document title in the editor app bar.
class DocumentEditorTitle extends StatelessWidget {
  static const titleKey = ValueKey('document-editor-title');
  static const actionIconKey = ValueKey('document-editor-title-action-icon');

  final String title;
  final VoidCallback? onTap;
  final String? tooltip;

  const DocumentEditorTitle({
    super.key,
    required this.title,
    this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final editable = onTap != null;
    final actionColor = editable
        ? colorScheme.onSurfaceVariant
        : colorScheme.onSurfaceVariant.withValues(alpha: 0.48);

    return Tooltip(
      message: tooltip ?? (editable ? 'Rename document' : 'Title is locked'),
      child: InkWell(
        key: titleKey,
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: Text(title, overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 4),
              Icon(
                editable ? Icons.edit : Icons.lock_outline,
                key: actionIconKey,
                size: 16,
                color: actionColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Marks the document as having local changes that have not been saved.
class DocumentUnsavedBadge extends StatelessWidget {
  const DocumentUnsavedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Unsaved',
            style: TextStyle(color: Colors.orange, fontSize: 12),
          ),
        ),
      ),
    );
  }
}
