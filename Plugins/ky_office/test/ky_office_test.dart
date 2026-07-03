import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_office/ky_office.dart';

void main() {
  group('OfficeProductVisuals', () {
    test('resolves visuals for core product descriptors', () {
      expect(
        OfficeProductVisuals.forProduct(KyOfficeProducts.sheets).icon,
        Icons.grid_on_outlined,
      );
      expect(
        OfficeProductVisuals.forProduct(KyOfficeProducts.slides).accentColor,
        const Color(0xFFEA580C),
      );
    });
  });

  group('OfficeProductCard', () {
    testWidgets('renders product metadata and handles selection', (
      tester,
    ) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: KyOfficeTheme.light(),
          home: Scaffold(
            body: OfficeProductCard(
              product: KyOfficeProducts.sheets,
              selected: true,
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Kaysir Sheets'), findsOneWidget);
      expect(find.text('View'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      await tester.tap(find.byType(OfficeProductCard));
      expect(tapped, isTrue);
    });
  });

  group('OfficeFamilyShell', () {
    testWidgets('renders product navigation and publishes selection', (
      tester,
    ) async {
      KyOfficeProductDescriptor? selected;

      await tester.pumpWidget(
        MaterialApp(
          theme: KyOfficeTheme.light(),
          home: Scaffold(
            body: OfficeFamilyShell(
              activeProductId: KyOfficeProducts.docs.id,
              onProductSelected: (product) => selected = product,
              child: const Text('Workspace'),
            ),
          ),
        ),
      );

      expect(find.text('Kaysir Office'), findsOneWidget);
      expect(find.text('Workspace'), findsOneWidget);
      expect(find.text('Kaysir Slides'), findsOneWidget);

      await tester.tap(find.text('Kaysir Slides'));
      expect(selected, KyOfficeProducts.slides);
    });
  });

  group('OfficeRecentFileCard', () {
    testWidgets('renders recent file metadata and opens files', (tester) async {
      var opened = false;
      final file = KyOfficeRecentFile(
        id: 'file-1',
        title: 'Quarterly Plan',
        productId: KyOfficeProducts.docs.id,
        location: 'Shared',
        owner: 'Amina',
        starred: true,
        updatedAt: DateTime(2026, 6, 8),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: KyOfficeTheme.light(),
          home: Scaffold(
            body: OfficeRecentFileCard(
              file: file,
              now: DateTime(2026, 6, 9),
              onPressed: () => opened = true,
            ),
          ),
        ),
      );

      expect(find.text('Quarterly Plan'), findsOneWidget);
      expect(find.text('Docs • Shared • Amina • Yesterday'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);

      await tester.tap(find.byType(OfficeRecentFileCard));
      expect(opened, isTrue);
    });
  });

  group('OfficeHomeSurface', () {
    testWidgets('renders products and recent files with callbacks', (
      tester,
    ) async {
      KyOfficeProductDescriptor? selectedProduct;
      KyOfficeRecentFile? openedFile;
      var created = false;
      final file = KyOfficeRecentFile(
        id: 'sheet-1',
        title: 'Budget Model',
        productId: KyOfficeProducts.sheets.id,
        updatedAt: DateTime(2026, 6, 9),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: KyOfficeTheme.light(),
          home: Scaffold(
            body: OfficeHomeSurface(
              recentFiles: [file],
              now: DateTime(2026, 6, 9),
              onCreatePressed: () => created = true,
              onProductSelected: (product) => selectedProduct = product,
              onRecentFilePressed: (recentFile) => openedFile = recentFile,
            ),
          ),
        ),
      );

      expect(find.text('Kaysir Office'), findsOneWidget);
      expect(find.text('Kaysir Sheets'), findsOneWidget);
      expect(find.text('Budget Model'), findsOneWidget);
      expect(find.text('4 apps'), findsOneWidget);
      expect(find.text('1 files'), findsOneWidget);

      await tester.tap(find.text('Kaysir Slides'));
      expect(selectedProduct, KyOfficeProducts.slides);

      await tester.tap(find.text('Budget Model'));
      expect(openedFile, file);

      await tester.tap(find.byType(FilledButton));
      expect(created, isTrue);
    });
  });
}
