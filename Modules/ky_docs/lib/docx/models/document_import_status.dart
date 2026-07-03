import 'document_import_structure.dart';

enum DocumentImportKind {
  docx,
  pdf;

  String get label {
    return switch (this) {
      DocumentImportKind.docx => 'DOCX',
      DocumentImportKind.pdf => 'PDF',
    };
  }
}

enum DocumentImportMethod {
  dartExtractor,
  waraqPdfCore,
  fallbackExtractor,
  customExtractor;

  String get label {
    return switch (this) {
      DocumentImportMethod.dartExtractor => 'Dart extractor',
      DocumentImportMethod.waraqPdfCore => 'Waraq pdf-core',
      DocumentImportMethod.fallbackExtractor => 'Dart fallback',
      DocumentImportMethod.customExtractor => 'Custom extractor',
    };
  }

  bool get usedFallback => this == DocumentImportMethod.fallbackExtractor;
}

enum DocumentImportPhase {
  idle,
  picking,
  importing,
  previewing,
  completed,
  cancelled,
  failed,
}

class DocumentImportPreview {
  final DocumentImportKind kind;
  final String title;
  final String sourceFileName;
  final DocumentImportMethod method;
  final int wordCount;
  final int characterCount;
  final bool hasStructuredContent;
  final String textPreview;
  final DocumentImportStructureSummary structure;
  final String? warningMessage;

  const DocumentImportPreview({
    required this.kind,
    required this.title,
    required this.sourceFileName,
    required this.method,
    required this.wordCount,
    required this.characterCount,
    required this.hasStructuredContent,
    required this.textPreview,
    this.structure = const DocumentImportStructureSummary.empty(),
    this.warningMessage,
  });

  factory DocumentImportPreview.fromText({
    required DocumentImportKind kind,
    required String title,
    required String sourceFileName,
    required String text,
    required DocumentImportMethod method,
    required bool hasStructuredContent,
    DocumentImportStructureSummary structure =
        const DocumentImportStructureSummary.empty(),
    String? warningMessage,
  }) {
    return DocumentImportPreview(
      kind: kind,
      title: title,
      sourceFileName: sourceFileName,
      method: method,
      wordCount: _wordCount(text),
      characterCount: text.runes.length,
      hasStructuredContent: hasStructuredContent,
      textPreview: _textPreview(text),
      structure: structure,
      warningMessage: warningMessage,
    );
  }

  String get summaryLabel {
    final structure = hasStructuredContent ? 'structured' : 'plain text';
    return '$wordCount words, $structure, ${this.structure.pageLabel}';
  }

  static int _wordCount(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 0;
    return trimmed.split(RegExp(r'\s+')).length;
  }

  static String _textPreview(String text) {
    final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= 240) return normalized;
    return '${normalized.substring(0, 240).trimRight()}...';
  }
}

class DocumentImportStatus {
  final DocumentImportPhase phase;
  final DocumentImportKind? kind;
  final DocumentImportPreview? preview;
  final String? errorMessage;

  const DocumentImportStatus._({
    required this.phase,
    this.kind,
    this.preview,
    this.errorMessage,
  });

  const DocumentImportStatus.idle() : this._(phase: DocumentImportPhase.idle);

  const DocumentImportStatus.picking(DocumentImportKind kind)
    : this._(phase: DocumentImportPhase.picking, kind: kind);

  const DocumentImportStatus.importing(DocumentImportKind kind)
    : this._(phase: DocumentImportPhase.importing, kind: kind);

  DocumentImportStatus.previewing(DocumentImportPreview preview)
    : this._(
        phase: DocumentImportPhase.previewing,
        kind: preview.kind,
        preview: preview,
      );

  DocumentImportStatus.completed(DocumentImportPreview preview)
    : this._(
        phase: DocumentImportPhase.completed,
        kind: preview.kind,
        preview: preview,
      );

  const DocumentImportStatus.cancelled(DocumentImportKind kind)
    : this._(phase: DocumentImportPhase.cancelled, kind: kind);

  const DocumentImportStatus.failed({
    required DocumentImportKind kind,
    required String errorMessage,
  }) : this._(
         phase: DocumentImportPhase.failed,
         kind: kind,
         errorMessage: errorMessage,
       );

  bool get isActive {
    return phase == DocumentImportPhase.picking ||
        phase == DocumentImportPhase.importing;
  }

  bool get isIdle => phase == DocumentImportPhase.idle;

  String get message {
    return switch (phase) {
      DocumentImportPhase.idle => 'Ready',
      DocumentImportPhase.picking => 'Choose ${kind?.label ?? 'document'} file',
      DocumentImportPhase.importing =>
        'Importing ${kind?.label ?? 'document'}...',
      DocumentImportPhase.previewing =>
        'Review ${kind?.label ?? 'document'} import',
      DocumentImportPhase.completed => _completedMessage,
      DocumentImportPhase.cancelled =>
        '${kind?.label ?? 'Document'} import cancelled',
      DocumentImportPhase.failed =>
        'Failed to import ${kind?.label ?? 'document'}',
    };
  }

  String get details {
    final activePreview = preview;
    if (activePreview == null) return errorMessage ?? message;

    final warning = activePreview.warningMessage;
    final details = [
      activePreview.sourceFileName,
      activePreview.method.label,
      activePreview.summaryLabel,
      if (warning != null && warning.trim().isNotEmpty) warning.trim(),
    ];
    return details.join(' | ');
  }

  String get _completedMessage {
    final activePreview = preview;
    if (activePreview == null) {
      return '${kind?.label ?? 'Document'} imported';
    }

    final fallbackLabel = activePreview.method.usedFallback
        ? ' with fallback'
        : '';
    return '${activePreview.kind.label} imported$fallbackLabel';
  }
}
