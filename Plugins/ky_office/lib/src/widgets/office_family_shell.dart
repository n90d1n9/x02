import 'package:flutter/material.dart';
import 'package:ky_office_core/ky_office_core.dart';

import '../theme/ky_office_theme.dart';
import 'office_product_card.dart';

class OfficeFamilyShell extends StatelessWidget {
  const OfficeFamilyShell({
    required this.activeProductId,
    required this.child,
    this.products = KyOfficeProducts.all,
    this.onProductSelected,
    this.title = 'Kaysir Office',
    this.trailing,
    super.key,
  });

  final String activeProductId;
  final Widget child;
  final List<KyOfficeProductDescriptor> products;
  final ValueChanged<KyOfficeProductDescriptor>? onProductSelected;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 286,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: KyOfficeColors.surface,
              border: Border(right: BorderSide(color: KyOfficeColors.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ShellHeader(title: title, trailing: trailing),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(KyOfficeSpacing.md),
                    itemCount: products.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: KyOfficeSpacing.sm),
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return OfficeProductCard(
                        product: product,
                        compact: true,
                        selected: product.id == activeProductId,
                        onPressed: onProductSelected == null
                            ? null
                            : () => onProductSelected!(product),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _ShellHeader extends StatelessWidget {
  const _ShellHeader({required this.title, required this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(KyOfficeSpacing.lg),
      child: Row(
        children: [
          const Icon(
            Icons.apps_outlined,
            color: KyOfficeColors.focus,
            size: 22,
          ),
          const SizedBox(width: KyOfficeSpacing.sm),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: KyOfficeColors.ink,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
