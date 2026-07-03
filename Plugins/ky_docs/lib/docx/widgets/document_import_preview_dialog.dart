import 'package:flutter/material.dart';

import '../models/document_import_status.dart';
import 'document_import_structure_summary_view.dart';

class DocumentImportPreviewDialog extends StatelessWidget {
  final DocumentImportPreview preview;

  const DocumentImportPreviewDialog({super.key, required this.preview});

  static Future<bool> show(
    BuildContext context, {
    required DocumentImportPreview preview,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => DocumentImportPreviewDialog(preview: preview),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AlertDialog(
      icon: Icon(_iconForKind(preview.kind), color: colorScheme.primary),
      title: Text('Review ${preview.kind.label} Import'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                preview.title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ImportBadge(
                    icon: Icons.folder_open_outlined,
                    label: preview.sourceFileName,
                  ),
                  _ImportBadge(
                    icon: _methodIcon(preview.method),
                    label: preview.method.label,
                    emphasized: preview.method.usedFallback,
                  ),
                  _ImportBadge(
                    icon: preview.hasStructuredContent
                        ? Icons.account_tree_outlined
                        : Icons.notes_outlined,
                    label: preview.hasStructuredContent
                        ? 'Structured'
                        : 'Plain text',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _ImportMetric(
                      icon: Icons.text_fields,
                      value: preview.wordCount.toString(),
                      label: 'Words',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ImportMetric(
                      icon: Icons.format_size,
                      value: preview.characterCount.toString(),
                      label: 'Characters',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DocumentImportStructureSummaryView(summary: preview.structure),
              if (preview.warningMessage != null) ...[
                const SizedBox(height: 16),
                _ImportWarning(message: preview.warningMessage!),
              ],
              const SizedBox(height: 16),
              _TextPreview(text: preview.textPreview),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(true),
          icon: const Icon(Icons.check),
          label: const Text('Import'),
        ),
      ],
    );
  }

  IconData _iconForKind(DocumentImportKind kind) {
    return switch (kind) {
      DocumentImportKind.docx => Icons.description_outlined,
      DocumentImportKind.pdf => Icons.picture_as_pdf_outlined,
    };
  }

  IconData _methodIcon(DocumentImportMethod method) {
    return switch (method) {
      DocumentImportMethod.dartExtractor => Icons.code,
      DocumentImportMethod.waraqPdfCore => Icons.bolt_outlined,
      DocumentImportMethod.fallbackExtractor => Icons.alt_route,
      DocumentImportMethod.customExtractor => Icons.extension_outlined,
    };
  }
}

class _ImportBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool emphasized;

  const _ImportBadge({
    required this.icon,
    required this.label,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = emphasized ? colorScheme.error : colorScheme.primary;
    final background = emphasized
        ? colorScheme.errorContainer.withValues(alpha: 0.42)
        : colorScheme.primaryContainer.withValues(alpha: 0.38);

    return Container(
      constraints: const BoxConstraints(maxWidth: 240),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImportMetric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _ImportMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(label, style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _ImportWarning extends StatelessWidget {
  final String message;

  const _ImportWarning({required this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber, size: 18, color: colorScheme.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TextPreview extends StatelessWidget {
  final String text;

  const _TextPreview({required this.text});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final visibleText = text.isEmpty ? 'No readable text detected' : text;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Text(
        visibleText,
        maxLines: 6,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.35),
      ),
    );
  }
}
