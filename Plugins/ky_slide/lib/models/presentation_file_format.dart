enum PresentationFileFormat { pptx, ppt, pdf }

enum PresentationFileOperation { import, export }

enum PresentationFileSupport { native, converterRequired, planned }

class PresentationFileCapability {
  final PresentationFileFormat format;
  final PresentationFileOperation operation;
  final PresentationFileSupport support;
  final String title;
  final String description;
  final String actionLabel;

  const PresentationFileCapability({
    required this.format,
    required this.operation,
    required this.support,
    required this.title,
    required this.description,
    required this.actionLabel,
  });

  bool get isNative => support == PresentationFileSupport.native;
}

extension PresentationFileFormatLabel on PresentationFileFormat {
  String get extension {
    switch (this) {
      case PresentationFileFormat.pptx:
        return 'pptx';
      case PresentationFileFormat.ppt:
        return 'ppt';
      case PresentationFileFormat.pdf:
        return 'pdf';
    }
  }

  String get label {
    switch (this) {
      case PresentationFileFormat.pptx:
        return 'PPTX';
      case PresentationFileFormat.ppt:
        return 'PPT';
      case PresentationFileFormat.pdf:
        return 'PDF';
    }
  }
}

extension PresentationFileSupportLabel on PresentationFileSupport {
  String get label {
    switch (this) {
      case PresentationFileSupport.native:
        return 'Native';
      case PresentationFileSupport.converterRequired:
        return 'Converter';
      case PresentationFileSupport.planned:
        return 'Planned';
    }
  }
}
