import 'package:flutter/material.dart';
import 'package:ky_office_core/ky_office_core.dart';

import '../theme/ky_office_theme.dart';
import 'office_product_card.dart';
import 'office_recent_file_card.dart';

class OfficeHomeSurface extends StatelessWidget {
  const OfficeHomeSurface({
    this.products = KyOfficeProducts.all,
    this.recentFiles = const [],
    this.onProductSelected,
    this.onRecentFilePressed,
    this.onCreatePressed,
    this.title = 'Kaysir Office',
    this.subtitle =
        'Documents, sheets, slides, and PDF tools in one workspace.',
    this.now,
    super.key,
  });

  final List<KyOfficeProductDescriptor> products;
  final List<KyOfficeRecentFile> recentFiles;
  final ValueChanged<KyOfficeProductDescriptor>? onProductSelected;
  final ValueChanged<KyOfficeRecentFile>? onRecentFilePressed;
  final VoidCallback? onCreatePressed;
  final String title;
  final String subtitle;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: KyOfficeColors.surfaceMuted),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(KyOfficeSpacing.xl),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HomeHeader(
                  title: title,
                  subtitle: subtitle,
                  onCreatePressed: onCreatePressed,
                ),
                const SizedBox(height: KyOfficeSpacing.xl),
                _SectionHeader(
                  title: 'Products',
                  label: '${products.length} apps',
                ),
                const SizedBox(height: KyOfficeSpacing.md),
                _ProductGrid(
                  products: products,
                  onProductSelected: onProductSelected,
                ),
                const SizedBox(height: KyOfficeSpacing.xl),
                _SectionHeader(
                  title: 'Recent',
                  label: recentFiles.isEmpty
                      ? 'No files'
                      : '${recentFiles.length} files',
                ),
                const SizedBox(height: KyOfficeSpacing.md),
                if (recentFiles.isEmpty)
                  const _EmptyRecentFiles()
                else
                  _RecentFileList(
                    files: recentFiles,
                    onFilePressed: onRecentFilePressed,
                    now: now,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.title,
    required this.subtitle,
    required this.onCreatePressed,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onCreatePressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _OfficeMark(),
        const SizedBox(width: KyOfficeSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: KyOfficeColors.ink,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: KyOfficeSpacing.xs),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: KyOfficeColors.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: KyOfficeSpacing.lg),
        FilledButton.icon(
          onPressed: onCreatePressed,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Create'),
        ),
      ],
    );
  }
}

class _OfficeMark extends StatelessWidget {
  const _OfficeMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: KyOfficeColors.focus.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(KyOfficeRadius.medium),
        border: Border.all(color: KyOfficeColors.border),
      ),
      child: const Icon(Icons.apps_outlined, color: KyOfficeColors.focus),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.label});

  final String title;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: KyOfficeColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: KyOfficeColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({required this.products, required this.onProductSelected});

  final List<KyOfficeProductDescriptor> products;
  final ValueChanged<KyOfficeProductDescriptor>? onProductSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 980
            ? 4
            : constraints.maxWidth >= 700
            ? 2
            : 1;
        final spacing = KyOfficeSpacing.md;
        final itemWidth =
            (constraints.maxWidth - (columns - 1) * spacing) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final product in products)
              SizedBox(
                width: itemWidth,
                child: OfficeProductCard(
                  product: product,
                  onPressed: onProductSelected == null
                      ? null
                      : () => onProductSelected!(product),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _RecentFileList extends StatelessWidget {
  const _RecentFileList({
    required this.files,
    required this.onFilePressed,
    required this.now,
  });

  final List<KyOfficeRecentFile> files;
  final ValueChanged<KyOfficeRecentFile>? onFilePressed;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final file in files) ...[
          OfficeRecentFileCard(
            file: file,
            now: now,
            onPressed: onFilePressed == null
                ? null
                : () => onFilePressed!(file),
          ),
          if (file != files.last) const SizedBox(height: KyOfficeSpacing.sm),
        ],
      ],
    );
  }
}

class _EmptyRecentFiles extends StatelessWidget {
  const _EmptyRecentFiles();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: KyOfficeColors.surface,
        borderRadius: BorderRadius.circular(KyOfficeRadius.medium),
        border: Border.all(color: KyOfficeColors.border),
      ),
      child: const Padding(
        padding: EdgeInsets.all(KyOfficeSpacing.xl),
        child: Text(
          'No recent files',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: KyOfficeColors.muted,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
