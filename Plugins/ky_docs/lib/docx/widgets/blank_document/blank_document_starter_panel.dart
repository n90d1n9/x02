import 'package:flutter/material.dart';

import 'document_starter_template.dart';

/// Shows starter actions when the active document is still blank.
class BlankDocumentStarterPanel extends StatelessWidget {
  static const panelKey = ValueKey('blank-document-starter-panel');
  static const templatePrefixKey = 'blank-document-starter-template';
  static const dismissKey = ValueKey('blank-document-starter-dismiss');

  final List<DocumentStarterTemplate> templates;
  final ValueChanged<DocumentStarterTemplate> onTemplateSelected;
  final VoidCallback? onDismiss;

  const BlankDocumentStarterPanel({
    super.key,
    this.templates = DocumentStarterTemplateCatalog.templates,
    required this.onTemplateSelected,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      key: panelKey,
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.64),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StarterHeader(onDismiss: onDismiss),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 540;
                if (compact) {
                  return Column(
                    children: [
                      for (final template in templates) ...[
                        _StarterTemplateTile(
                          template: template,
                          onTap: () => onTemplateSelected(template),
                        ),
                        if (template != templates.last)
                          const SizedBox(height: 8),
                      ],
                    ],
                  );
                }

                return Row(
                  children: [
                    for (final template in templates) ...[
                      Expanded(
                        child: _StarterTemplateTile(
                          template: template,
                          onTap: () => onTemplateSelected(template),
                        ),
                      ),
                      if (template != templates.last) const SizedBox(width: 8),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Renders the compact heading and optional dismiss action for starter options.
class _StarterHeader extends StatelessWidget {
  final VoidCallback? onDismiss;

  const _StarterHeader({this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.auto_awesome_outlined,
            size: 18,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Start with structure',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                'Reusable structures for common first drafts.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (onDismiss != null)
          IconButton(
            key: BlankDocumentStarterPanel.dismissKey,
            tooltip: 'Hide starter options',
            icon: const Icon(Icons.close, size: 18),
            onPressed: onDismiss,
          ),
      ],
    );
  }
}

/// Displays one starter template as a selectable document structure tile.
class _StarterTemplateTile extends StatelessWidget {
  final DocumentStarterTemplate template;
  final VoidCallback onTap;

  const _StarterTemplateTile({required this.template, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key(
          '${BlankDocumentStarterPanel.templatePrefixKey}-${template.id.name}',
        ),
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.54),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Icon(template.icon, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        template.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
