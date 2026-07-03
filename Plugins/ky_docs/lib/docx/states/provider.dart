import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/aiassistant_service.dart';
import '../models/cloud_sync_service.dart';
import '../models/collaboration_service.dart';
import '../models/document_metadata.dart';
import '../models/document_state.dart';
import '../models/document_storage_service.dart';
import '../models/folder.dart';
import '../models/spell_check_service.dart';
import '../services/document_import_service.dart';
import '../services/document_statistics.dart';
import '../services/docx_service.dart';
import '../services/pdf_service.dart';
import '../services/waraq_document_import_service_factory.dart';
import 'doc_notifier.dart';

final documentStorageServiceProvider = Provider<DocumentStorageService>((ref) {
  return DocumentStorageService();
});

final docxServiceProvider = Provider<DocxService>((ref) {
  return DocxService();
});

final pdfServiceProvider = Provider<PdfService>((ref) {
  return PdfService();
});

final documentImportServiceProvider = Provider<DocumentImportService>((ref) {
  return const WaraqDocumentImportServiceFactory().createPdfPreferred(
    docxService: ref.watch(docxServiceProvider),
    pdfService: ref.watch(pdfServiceProvider),
  );
});

final aiAssistantServiceProvider = Provider<AIAssistantService>((ref) {
  return AIAssistantService();
});

final cloudSyncServiceProvider = Provider<CloudSyncService>((ref) {
  final service = CloudSyncService();
  service.initialize();
  return service;
});

final collaborationServiceProvider = Provider<CollaborationService>((ref) {
  return CollaborationService();
});

final spellCheckServiceProvider = Provider<SpellCheckService>((ref) {
  return SpellCheckService();
});

final documentProvider = StateNotifierProvider<DocumentNotifier, DocumentState>(
  (ref) {
    return DocumentNotifier(
      ref.watch(documentStorageServiceProvider),
      ref.watch(docxServiceProvider),
      ref.watch(pdfServiceProvider),
      ref.watch(aiAssistantServiceProvider),
      ref.watch(cloudSyncServiceProvider),
      ref.watch(collaborationServiceProvider),
      ref.watch(spellCheckServiceProvider),
      documentImportService: ref.watch(documentImportServiceProvider),
    );
  },
);

final allDocumentsProvider = FutureProvider<List<DocumentMetadata>>((
  ref,
) async {
  final storage = ref.watch(documentStorageServiceProvider);
  return await storage.getAllDocuments();
});

final foldersProvider = FutureProvider<List<Folder>>((ref) async {
  final storage = ref.watch(documentStorageServiceProvider);
  return await storage.getAllFolders();
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<DocumentMetadata>>((
  ref,
) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return [];

  final storage = ref.watch(documentStorageServiceProvider);
  return await storage.searchDocuments(query);
});

final favoriteDocumentsProvider = Provider<List<DocumentMetadata>>((ref) {
  final docs = ref.watch(allDocumentsProvider);
  return docs.when(
    data: (documents) => documents.where((d) => d.isFavorite).toList(),
    loading: () => [],
    error: (error, stackTrace) => [],
  );
});

final statisticsProvider = Provider<DocumentStatistics>((ref) {
  final docState = ref.watch(documentProvider);
  return DocumentStatistics(docState.controller);
});
