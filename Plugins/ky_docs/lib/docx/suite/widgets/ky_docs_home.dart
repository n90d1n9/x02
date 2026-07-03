import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../docx/models/document_metadata.dart';
import '../../../docx/models/document_template.dart';
import '../../../docx/models/template_library.dart';
import '../../../docx/states/provider.dart';
import '../../../docx/widgets/template_gallery_sheet.dart';
import '../ky_docs_surface.dart';

class KyDocsHome extends ConsumerWidget {
  final ValueChanged<KyDocsSurface> onOpenSurface;

  const KyDocsHome({super.key, required this.onOpenSurface});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentsAsync = ref.watch(allDocumentsProvider);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 8),
              sliver: SliverToBoxAdapter(
                child: _HomeHeader(
                  onCreateBlank: () => _createBlank(context, ref),
                  onOpenLiveDocs: () => onOpenSurface(KyDocsSurface.liveDocs),
                  onImportDocx: () => _importDocx(context, ref),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
              sliver: SliverToBoxAdapter(
                child: documentsAsync.when(
                  data: (documents) => _DocumentMetrics(documents: documents),
                  loading: () => const _MetricSkeleton(),
                  error: (error, stackTrace) => const _MetricSkeleton(),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
              sliver: SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'Templates',
                  actionLabel: 'Browse',
                  onAction: () => _showTemplateGallery(context, ref),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(28, 12, 28, 0),
              sliver: SliverGrid.builder(
                itemCount: TemplateLibrary.templates.take(4).length,
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 270,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.38,
                ),
                itemBuilder: (context, index) {
                  final template = TemplateLibrary.templates[index];
                  return _TemplateTile(
                    template: template,
                    onTap: () => _createFromTemplate(context, ref, template),
                  );
                },
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 0),
              sliver: SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'Recent Documents',
                  actionLabel: 'Open library',
                  onAction: () => onOpenSurface(KyDocsSurface.library),
                ),
              ),
            ),
            documentsAsync.when(
              data: (documents) {
                if (documents.isEmpty) {
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(28, 12, 28, 32),
                    sliver: SliverToBoxAdapter(
                      child: _EmptyRecent(
                        onCreateBlank: () => _createBlank(context, ref),
                      ),
                    ),
                  );
                }
                final recent = [...documents]
                  ..sort((a, b) => b.lastModified.compareTo(a.lastModified));
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(28, 12, 28, 32),
                  sliver: SliverList.separated(
                    itemCount: recent.take(6).length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final document = recent[index];
                      return _RecentDocumentRow(
                        document: document,
                        onOpen: () => _openDocument(context, ref, document),
                      );
                    },
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => SliverPadding(
                padding: const EdgeInsets.fromLTRB(28, 12, 28, 32),
                sliver: SliverToBoxAdapter(
                  child: _ErrorPanel(
                    error: error,
                    onRetry: () => ref.invalidate(allDocumentsProvider),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createBlank(BuildContext context, WidgetRef ref) async {
    await ref.read(documentProvider.notifier).createNewDocument();
    onOpenSurface(KyDocsSurface.wordEditor);
  }

  Future<void> _createFromTemplate(
    BuildContext context,
    WidgetRef ref,
    DocumentTemplate template,
  ) async {
    await ref.read(documentProvider.notifier).createFromTemplate(template);
    if (context.mounted) {
      onOpenSurface(KyDocsSurface.wordEditor);
    }
  }

  Future<void> _openDocument(
    BuildContext context,
    WidgetRef ref,
    DocumentMetadata document,
  ) async {
    await ref.read(documentProvider.notifier).loadDocument(document.id);
    if (context.mounted) {
      onOpenSurface(KyDocsSurface.wordEditor);
    }
  }

  Future<void> _importDocx(BuildContext context, WidgetRef ref) async {
    await ref.read(documentProvider.notifier).importFromDocx();
    if (context.mounted) {
      onOpenSurface(KyDocsSurface.wordEditor);
    }
  }

  void _showTemplateGallery(BuildContext context, WidgetRef ref) {
    final parentContext = context;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.76,
        minChildSize: 0.48,
        maxChildSize: 0.94,
        expand: false,
        builder: (context, scrollController) {
          return TemplateGallerySheet(
            scrollController: scrollController,
            onTemplateSelected: (template) async {
              Navigator.pop(context);
              await _createFromTemplate(parentContext, ref, template);
            },
          );
        },
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  final VoidCallback onCreateBlank;
  final VoidCallback onOpenLiveDocs;
  final VoidCallback onImportDocx;

  const _HomeHeader({
    required this.onCreateBlank,
    required this.onOpenLiveDocs,
    required this.onImportDocx,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 720;
          final title = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kaysir Docs',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'A professional document workspace for drafts, DOCX export, collaboration, comments, and templates.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ],
          );
          final actions = Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: stacked ? WrapAlignment.start : WrapAlignment.end,
            children: [
              FilledButton.icon(
                onPressed: onCreateBlank,
                icon: const Icon(Icons.add),
                label: const Text('New'),
              ),
              OutlinedButton.icon(
                onPressed: onOpenLiveDocs,
                icon: const Icon(Icons.groups_2_outlined),
                label: const Text('Live'),
              ),
              OutlinedButton.icon(
                onPressed: onImportDocx,
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('Import'),
              ),
            ],
          );

          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [title, const SizedBox(height: 18), actions],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: title),
              const SizedBox(width: 24),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _DocumentMetrics extends StatelessWidget {
  final List<DocumentMetadata> documents;

  const _DocumentMetrics({required this.documents});

  @override
  Widget build(BuildContext context) {
    final favoriteCount = documents.where((doc) => doc.isFavorite).length;
    final wordCount = documents.fold<int>(0, (sum, doc) => sum + doc.wordCount);
    return Row(
      children: [
        Expanded(
          child: _MetricTile(
            icon: Icons.description_outlined,
            label: 'Documents',
            value: documents.length.toString(),
            tint: const Color(0xFF2563EB),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricTile(
            icon: Icons.star_border,
            label: 'Favorites',
            value: favoriteCount.toString(),
            tint: const Color(0xFFF59E0B),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricTile(
            icon: Icons.text_fields,
            label: 'Words',
            value: _compactNumber(wordCount),
            tint: const Color(0xFF10B981),
          ),
        ),
      ],
    );
  }

  String _compactNumber(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toString();
  }
}

class _MetricSkeleton extends StatelessWidget {
  const _MetricSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _MetricTile(
            icon: Icons.description_outlined,
            label: 'Documents',
            value: '-',
            tint: Color(0xFF2563EB),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _MetricTile(
            icon: Icons.star_border,
            label: 'Favorites',
            value: '-',
            tint: Color(0xFFF59E0B),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _MetricTile(
            icon: Icons.text_fields,
            label: 'Words',
            value: '-',
            tint: Color(0xFF10B981),
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color tint;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: tint, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: onAction,
          icon: const Icon(Icons.arrow_forward, size: 18),
          label: Text(actionLabel),
        ),
      ],
    );
  }
}

class _TemplateTile extends StatelessWidget {
  final DocumentTemplate template;
  final VoidCallback onTap;

  const _TemplateTile({required this.template, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    template.icon,
                    color: theme.colorScheme.onSecondaryContainer,
                    size: 20,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.add_circle_outline,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ],
            ),
            const Spacer(),
            Text(
              template.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              template.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentDocumentRow extends StatelessWidget {
  final DocumentMetadata document;
  final VoidCallback onOpen;

  const _RecentDocumentRow({required this.document, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.description_outlined,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${document.wordCount} words · Modified ${_formatDate(document.lastModified)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (document.isFavorite)
              const Padding(
                padding: EdgeInsets.only(right: 10),
                child: Icon(Icons.star, color: Color(0xFFF59E0B), size: 19),
              ),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyRecent extends StatelessWidget {
  final VoidCallback onCreateBlank;

  const _EmptyRecent({required this.onCreateBlank});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(
            Icons.note_add_outlined,
            color: theme.colorScheme.primary,
            size: 42,
          ),
          const SizedBox(height: 12),
          Text(
            'No documents yet',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onCreateBlank,
            icon: const Icon(Icons.add),
            label: const Text('Create document'),
          ),
        ],
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ErrorPanel({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error.toString(),
              style: TextStyle(color: theme.colorScheme.onErrorContainer),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);
  if (difference.inDays == 0) {
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
  if (difference.inDays == 1) return 'yesterday';
  if (difference.inDays < 7) return '${difference.inDays} days ago';
  return '${date.day}/${date.month}/${date.year}';
}
