import 'package:flutter/material.dart';
import 'package:ky_office_core/ky_office_core.dart';

import '../theme/ky_office_theme.dart';
import '../theme/office_product_visuals.dart';

class OfficeRecentFileCard extends StatelessWidget {
  const OfficeRecentFileCard({
    required this.file,
    this.registry = KyOfficeProducts.registry,
    this.onPressed,
    this.now,
    super.key,
  });

  final KyOfficeRecentFile file;
  final KyOfficeProductRegistry registry;
  final VoidCallback? onPressed;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final product = registry.byId(file.productId) ?? KyOfficeProducts.docs;
    final visuals = OfficeProductVisuals.forProduct(product);

    return Material(
      color: KyOfficeColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KyOfficeRadius.medium),
        side: const BorderSide(color: KyOfficeColors.border),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(KyOfficeRadius.medium),
        child: Padding(
          padding: const EdgeInsets.all(KyOfficeSpacing.md),
          child: Row(
            children: [
              _FileIcon(visuals: visuals),
              const SizedBox(width: KyOfficeSpacing.md),
              Expanded(
                child: _FileDetails(file: file, product: product, now: now),
              ),
              if (file.starred) ...[
                const SizedBox(width: KyOfficeSpacing.sm),
                Icon(Icons.star, size: 18, color: visuals.accentColor),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FileIcon extends StatelessWidget {
  const _FileIcon({required this.visuals});

  final OfficeProductVisuals visuals;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: visuals.accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(KyOfficeRadius.medium),
      ),
      child: Icon(visuals.icon, color: visuals.accentColor, size: 19),
    );
  }
}

class _FileDetails extends StatelessWidget {
  const _FileDetails({
    required this.file,
    required this.product,
    required this.now,
  });

  final KyOfficeRecentFile file;
  final KyOfficeProductDescriptor product;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final location = file.location?.trim();
    final owner = file.owner?.trim();
    final secondary = [
      product.shortName,
      if (location != null && location.isNotEmpty) location,
      if (owner != null && owner.isNotEmpty) owner,
      file.updatedLabel(now: now),
    ].join(' • ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          file.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: KyOfficeColors.ink,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: KyOfficeSpacing.xs),
        Text(
          secondary,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: KyOfficeColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
