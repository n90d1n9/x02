import 'ky_office_capability.dart';
import 'ky_office_product_descriptor.dart';

class KyOfficeProductRegistry {
  const KyOfficeProductRegistry(this.products);

  final List<KyOfficeProductDescriptor> products;

  KyOfficeProductDescriptor? byId(String id) {
    for (final product in products) {
      if (product.id == id) return product;
    }
    return null;
  }

  List<KyOfficeProductDescriptor> byKind(KyOfficeProductKind kind) {
    return [
      for (final product in products)
        if (product.kind == kind) product,
    ];
  }

  List<KyOfficeCapability> get sharedCapabilities {
    final shared = <KyOfficeCapability>[];
    for (final product in products) {
      for (final capability in product.capabilities) {
        if (_allProductsSupport(capability.id) &&
            !shared.any((existing) => existing.id == capability.id)) {
          shared.add(capability);
        }
      }
    }
    return shared;
  }

  bool _allProductsSupport(String capabilityId) {
    if (products.isEmpty) return false;
    return products.every((product) => product.supports(capabilityId));
  }
}
