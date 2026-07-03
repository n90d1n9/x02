import 'package:ky_office_core/ky_office_core.dart';

const kyDocsOfficeProduct = KyOfficeProductDescriptor(
  id: 'docs',
  packageName: 'ky_docs',
  displayName: 'Docs',
  shortName: 'Docs',
  familyName: 'Kaysir Office',
  kind: KyOfficeProductKind.document,
  routeSegment: 'docs',
  summary: 'Document editor for rich text, DOCX flows, and document review.',
  capabilities: [
    KyOfficeCapabilities.create,
    KyOfficeCapabilities.edit,
    KyOfficeCapabilities.view,
    KyOfficeCapabilities.import,
    KyOfficeCapabilities.export,
    KyOfficeCapabilities.collaborate,
    KyOfficeCapabilities.analyze,
  ],
);
