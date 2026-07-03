import 'package:ky_office_core/ky_office_core.dart';

const kyPptOfficeProduct = KyOfficeProductDescriptor(
  id: 'slides',
  packageName: 'ky_slide',
  displayName: 'Slides',
  shortName: 'Slides',
  familyName: 'Kaysir Office',
  kind: KyOfficeProductKind.presentation,
  routeSegment: 'slides',
  summary:
      'Presentation editor for slide decks, templates, and presenter mode.',
  capabilities: [
    KyOfficeCapabilities.create,
    KyOfficeCapabilities.edit,
    KyOfficeCapabilities.view,
    KyOfficeCapabilities.import,
    KyOfficeCapabilities.export,
    KyOfficeCapabilities.collaborate,
    KyOfficeCapabilities.present,
  ],
);
