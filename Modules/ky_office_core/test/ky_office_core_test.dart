import 'package:ky_office_core/ky_office_core.dart';
import 'package:test/test.dart';

void main() {
  group('KyOfficeProductDescriptor', () {
    test('describes product identity and capabilities', () {
      const descriptor = KyOfficeProductDescriptor(
        id: 'sheet',
        packageName: 'ky_sheet',
        displayName: 'Sheet',
        shortName: 'Sheet',
        familyName: 'Kaysir Office',
        kind: KyOfficeProductKind.spreadsheet,
        routeSegment: 'sheet',
        summary: 'Spreadsheet editor',
        capabilities: [
          KyOfficeCapabilities.create,
          KyOfficeCapabilities.edit,
          KyOfficeCapabilities.import,
        ],
      );

      expect(descriptor.qualifiedName, 'Kaysir Office Sheet');
      expect(descriptor.supports('edit'), isTrue);
      expect(descriptor.supports('present'), isFalse);
    });
  });

  group('KyOfficeProductRegistry', () {
    test('looks up products and shared capabilities', () {
      const sheet = KyOfficeProductDescriptor(
        id: 'sheet',
        packageName: 'ky_sheet',
        displayName: 'Sheet',
        shortName: 'Sheet',
        familyName: 'Kaysir Office',
        kind: KyOfficeProductKind.spreadsheet,
        routeSegment: 'sheet',
        summary: 'Spreadsheet editor',
        capabilities: [
          KyOfficeCapabilities.create,
          KyOfficeCapabilities.edit,
          KyOfficeCapabilities.import,
        ],
      );
      const slides = KyOfficeProductDescriptor(
        id: 'slides',
        packageName: 'ky_slide',
        displayName: 'Slides',
        shortName: 'Slides',
        familyName: 'Kaysir Office',
        kind: KyOfficeProductKind.presentation,
        routeSegment: 'slides',
        summary: 'Presentation editor',
        capabilities: [
          KyOfficeCapabilities.create,
          KyOfficeCapabilities.edit,
          KyOfficeCapabilities.present,
        ],
      );

      const registry = KyOfficeProductRegistry([sheet, slides]);

      expect(registry.byId('sheet'), sheet);
      expect(registry.byKind(KyOfficeProductKind.presentation), [slides]);
      expect(registry.sharedCapabilities, [
        KyOfficeCapabilities.create,
        KyOfficeCapabilities.edit,
      ]);
    });
  });

  group('KyOfficeProducts', () {
    test('provides the default Office product family catalog', () {
      expect(KyOfficeProducts.all.map((product) => product.id), [
        'docs',
        'sheets',
        'slides',
        'pdf',
      ]);
      expect(KyOfficeProducts.sheets.supports('analyze'), isTrue);
      expect(KyOfficeProducts.registry.byId('slides'), KyOfficeProducts.slides);
      expect(KyOfficeProducts.pdf.kind, KyOfficeProductKind.pdf);
    });
  });

  group('KyOfficeRecentFile', () {
    test('formats relative updated labels', () {
      final now = DateTime(2026, 6, 9, 10);

      expect(
        KyOfficeRecentFile(
          id: 'today',
          title: 'Today',
          productId: 'docs',
          updatedAt: DateTime(2026, 6, 9),
        ).updatedLabel(now: now),
        'Today',
      );
      expect(
        KyOfficeRecentFile(
          id: 'yesterday',
          title: 'Yesterday',
          productId: 'sheets',
          updatedAt: DateTime(2026, 6, 8),
        ).updatedLabel(now: now),
        'Yesterday',
      );
      expect(
        KyOfficeRecentFile(
          id: 'old',
          title: 'Older',
          productId: 'slides',
          updatedAt: DateTime(2026, 4, 12),
        ).updatedLabel(now: now),
        'Apr 12, 2026',
      );
    });
  });
}
