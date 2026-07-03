import '../../models/presentation_file_format.dart';

class PresentationFileCapabilityService {
  const PresentationFileCapabilityService();

  static const List<PresentationFileCapability> capabilities = [
    PresentationFileCapability(
      format: PresentationFileFormat.pptx,
      operation: PresentationFileOperation.import,
      support: PresentationFileSupport.native,
      title: 'Import PPTX',
      description:
          'OpenXML import for slides, text, images, shapes, notes, and order.',
      actionLabel: 'Import',
    ),
    PresentationFileCapability(
      format: PresentationFileFormat.pptx,
      operation: PresentationFileOperation.export,
      support: PresentationFileSupport.native,
      title: 'Export PPTX',
      description: 'Native OpenXML export for text, images, shapes, and notes.',
      actionLabel: 'Export',
    ),
    PresentationFileCapability(
      format: PresentationFileFormat.ppt,
      operation: PresentationFileOperation.import,
      support: PresentationFileSupport.converterRequired,
      title: 'Import PPT',
      description: 'Legacy binary decks need a converter bridge.',
      actionLabel: 'Convert',
    ),
    PresentationFileCapability(
      format: PresentationFileFormat.ppt,
      operation: PresentationFileOperation.export,
      support: PresentationFileSupport.converterRequired,
      title: 'Export PPT',
      description: 'Legacy binary export should route through conversion.',
      actionLabel: 'Convert',
    ),
    PresentationFileCapability(
      format: PresentationFileFormat.pdf,
      operation: PresentationFileOperation.export,
      support: PresentationFileSupport.planned,
      title: 'Export PDF',
      description: 'Print-ready static export for review and handoff.',
      actionLabel: 'Export',
    ),
  ];

  List<PresentationFileCapability> forOperation(
    PresentationFileOperation operation,
  ) {
    return capabilities
        .where((capability) => capability.operation == operation)
        .toList(growable: false);
  }

  PresentationFileCapability capabilityFor(
    PresentationFileOperation operation,
    PresentationFileFormat format,
  ) {
    return capabilities.firstWhere(
      (capability) =>
          capability.operation == operation && capability.format == format,
    );
  }
}
