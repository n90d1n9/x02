import 'package:flutter/material.dart';
import 'package:ky_office_core/ky_office_core.dart';

import '../theme/ky_office_theme.dart';
import '../theme/office_product_visuals.dart';

class OfficeProductCard extends StatelessWidget {
  const OfficeProductCard({
    required this.product,
    this.visuals,
    this.onPressed,
    this.selected = false,
    this.compact = false,
    super.key,
  });

  final KyOfficeProductDescriptor product;
  final OfficeProductVisuals? visuals;
  final VoidCallback? onPressed;
  final bool selected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final resolvedVisuals = visuals ?? OfficeProductVisuals.forProduct(product);
    final background = selected
        ? resolvedVisuals.accentColor.withValues(alpha: 0.08)
        : KyOfficeColors.surface;
    final borderColor = selected
        ? resolvedVisuals.accentColor
        : KyOfficeColors.border;

    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KyOfficeRadius.medium),
        side: BorderSide(color: borderColor),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(KyOfficeRadius.medium),
        child: Padding(
          padding: EdgeInsets.all(
            compact ? KyOfficeSpacing.md : KyOfficeSpacing.lg,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProductIcon(visuals: resolvedVisuals, selected: selected),
              const SizedBox(width: KyOfficeSpacing.md),
              Expanded(
                child: _ProductContent(product: product, compact: compact),
              ),
              if (selected) ...[
                const SizedBox(width: KyOfficeSpacing.sm),
                Icon(
                  Icons.check_circle,
                  size: 18,
                  color: resolvedVisuals.accentColor,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductIcon extends StatelessWidget {
  const _ProductIcon({required this.visuals, required this.selected});

  final OfficeProductVisuals visuals;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: visuals.accentColor.withValues(alpha: selected ? 0.16 : 0.1),
        borderRadius: BorderRadius.circular(KyOfficeRadius.medium),
      ),
      child: Icon(visuals.icon, color: visuals.accentColor, size: 21),
    );
  }
}

class _ProductContent extends StatelessWidget {
  const _ProductContent({required this.product, required this.compact});

  final KyOfficeProductDescriptor product;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.qualifiedName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: KyOfficeColors.ink,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (!compact) ...[
          const SizedBox(height: KyOfficeSpacing.xs),
          Text(
            product.summary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: KyOfficeColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        const SizedBox(height: KyOfficeSpacing.sm),
        Wrap(
          spacing: KyOfficeSpacing.xs,
          runSpacing: KyOfficeSpacing.xs,
          children: [
            for (final capability in product.capabilities.take(compact ? 2 : 3))
              _CapabilityPill(label: capability.label),
          ],
        ),
      ],
    );
  }
}

class _CapabilityPill extends StatelessWidget {
  const _CapabilityPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: KyOfficeColors.surfaceMuted,
        borderRadius: BorderRadius.circular(KyOfficeRadius.small),
        border: Border.all(color: KyOfficeColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        child: Text(
          label,
          style: const TextStyle(
            color: KyOfficeColors.muted,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
