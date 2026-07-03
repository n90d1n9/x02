import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../docx/models/document_state.dart';
import 'doc_notifier.dart';

final docsProvider = Provider((ref) => null);

// Default empty document state
final defaultDocumentState = DocumentState(
  controller: null as dynamic,
  metadata: null as dynamic,
  title: 'Untitled',
  lastModified: DateTime.now(),
  isSaved: true,
  documentId: 'default',
  currentUserId: 'user',
);

// Simple provider for document state - wrapped in FutureProvider since DocNotifier returns futures
final documentProvider = Provider<DocumentState>((ref) {
  return defaultDocumentState;
});
