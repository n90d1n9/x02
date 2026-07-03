import 'ky_office_capability.dart';
import 'ky_office_product_descriptor.dart';
import 'ky_office_product_registry.dart';

abstract final class KyOfficeProducts {
  static const docs = KyOfficeProductDescriptor(
    id: 'docs',
    packageName: 'ky_docs',
    displayName: 'Docs',
    shortName: 'Docs',
    familyName: 'Kaysir',
    kind: KyOfficeProductKind.document,
    routeSegment: 'docs',
    summary: 'Document editor for writing, review, media, and export.',
    capabilities: [
      KyOfficeCapabilities.create,
      KyOfficeCapabilities.edit,
      KyOfficeCapabilities.view,
      KyOfficeCapabilities.import,
      KyOfficeCapabilities.export,
      KyOfficeCapabilities.collaborate,
    ],
  );

  static const sheets = KyOfficeProductDescriptor(
    id: 'sheets',
    packageName: 'ky_sheet',
    displayName: 'Sheets',
    shortName: 'Sheets',
    familyName: 'Kaysir',
    kind: KyOfficeProductKind.spreadsheet,
    routeSegment: 'sheets',
    summary: 'Spreadsheet editor for formulas, data cleanup, and charts.',
    capabilities: [
      KyOfficeCapabilities.create,
      KyOfficeCapabilities.edit,
      KyOfficeCapabilities.view,
      KyOfficeCapabilities.import,
      KyOfficeCapabilities.export,
      KyOfficeCapabilities.analyze,
      KyOfficeCapabilities.automate,
    ],
  );

  static const slides = KyOfficeProductDescriptor(
    id: 'slides',
    packageName: 'ky_slide',
    displayName: 'Slides',
    shortName: 'Slides',
    familyName: 'Kaysir',
    kind: KyOfficeProductKind.presentation,
    routeSegment: 'slides',
    summary: 'Presentation editor for reusable layouts and presenting.',
    capabilities: [
      KyOfficeCapabilities.create,
      KyOfficeCapabilities.edit,
      KyOfficeCapabilities.view,
      KyOfficeCapabilities.import,
      KyOfficeCapabilities.export,
      KyOfficeCapabilities.present,
    ],
  );

  static const pdf = KyOfficeProductDescriptor(
    id: 'pdf',
    packageName: 'ky-of-pdf',
    displayName: 'PDF',
    shortName: 'PDF',
    familyName: 'Kaysir',
    kind: KyOfficeProductKind.pdf,
    routeSegment: 'pdf',
    summary: 'PDF extraction, composition, and export workflows.',
    capabilities: [
      KyOfficeCapabilities.create,
      KyOfficeCapabilities.view,
      KyOfficeCapabilities.import,
      KyOfficeCapabilities.export,
    ],
  );

  static const all = [docs, sheets, slides, pdf];

  static const registry = KyOfficeProductRegistry(all);
}
