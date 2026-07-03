import '../models/document_metadata.dart';
import '../models/page_settings.dart';
import 'document_pagination_service.dart';
import 'document_statistics.dart';

typedef DocumentChangeClock = DateTime Function();

class DocumentChangeResult {
  final DocumentMetadata metadata;
  final int totalPages;
  final DocumentTextStatistics statistics;

  const DocumentChangeResult({
    required this.metadata,
    required this.totalPages,
    required this.statistics,
  });
}

class DocumentChangeService {
  final DocumentPaginationService paginationService;
  final DocumentChangeClock now;

  const DocumentChangeService({
    this.paginationService = const DocumentPaginationService(),
    this.now = DateTime.now,
  });

  DocumentChangeResult applyDocumentChange({
    required String text,
    required DocumentMetadata metadata,
    required PageSettings pageSettings,
  }) {
    final statistics = DocumentTextStatistics.fromText(text);

    return DocumentChangeResult(
      statistics: statistics,
      metadata: metadata.copyWith(
        wordCount: statistics.wordCount,
        characterCount: statistics.characterCount,
        lastModified: now(),
      ),
      totalPages: estimateTotalPages(text: text, pageSettings: pageSettings),
    );
  }

  int estimateTotalPages({
    required String text,
    required PageSettings pageSettings,
  }) {
    return paginationService.estimateTotalPages(
      text: text,
      pageSettings: pageSettings,
    );
  }
}
