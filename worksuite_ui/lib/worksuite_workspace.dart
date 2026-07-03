import 'package:flutter/material.dart';
import 'package:ky_docs/ky_docs.dart';
import 'package:ky_office/ky_office.dart';
import 'package:ky_sheet/ky_sheet.dart';
import 'package:ky_slide/ky_slide.dart';

/// Root workspace widget.
///
/// Renders the [OfficeHomeSurface] product grid by default and switches to the
/// correct product screen when the user selects one.  All products registered
/// in [KyOfficeProducts.all] are supported; unknown products fall back to the
/// home surface with a "coming soon" snack bar.
class WorksuiteWorkspace extends StatefulWidget {
  const WorksuiteWorkspace({super.key});

  @override
  State<WorksuiteWorkspace> createState() => _WorksuiteWorkspaceState();
}

class _WorksuiteWorkspaceState extends State<WorksuiteWorkspace> {
  KyOfficeProductDescriptor? _activeProduct;

  void _selectProduct(KyOfficeProductDescriptor product) {
    setState(() => _activeProduct = product);
  }

  void _goHome() {
    setState(() => _activeProduct = null);
  }

  @override
  Widget build(BuildContext context) {
    final product = _activeProduct;

    if (product == null) {
      return OfficeHomeSurface(
        products: KyOfficeProducts.all,
        onProductSelected: _selectProduct,
        onCreatePressed: () {
          // Default to opening the docs editor on "Create".
          _selectProduct(KyOfficeProducts.docs);
        },
      );
    }

    return OfficeFamilyShell(
      activeProductId: product.id,
      products: KyOfficeProducts.all,
      onProductSelected: _selectProduct,
      trailing: IconButton(
        icon: const Icon(Icons.home_outlined, size: 20),
        tooltip: 'Home',
        onPressed: _goHome,
      ),
      child: _ProductScreen(product: product, onGoHome: _goHome),
    );
  }
}

// ---------------------------------------------------------------------------
// Product screen switcher
// ---------------------------------------------------------------------------

class _ProductScreen extends StatelessWidget {
  const _ProductScreen({
    required this.product,
    required this.onGoHome,
  });

  final KyOfficeProductDescriptor product;
  final VoidCallback onGoHome;

  @override
  Widget build(BuildContext context) {
    return switch (product.id) {
      'docs' => const DocumentEditorScreen(),
      'sheets' => const SpreadsheetScreen(),
      'slides' => const PresentationEditor(),
      _ => _ComingSoonScreen(product: product, onGoHome: onGoHome),
    };
  }
}

// ---------------------------------------------------------------------------
// Placeholder for products without a screen yet
// ---------------------------------------------------------------------------

class _ComingSoonScreen extends StatelessWidget {
  const _ComingSoonScreen({required this.product, required this.onGoHome});

  final KyOfficeProductDescriptor product;
  final VoidCallback onGoHome;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.construction_outlined,
              size: 56,
              color: colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              '${product.displayName} — coming soon',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              product.summary,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onGoHome,
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
