import 'package:flutter_riverpod/legacy.dart';

import '../models/document_metadata.dart';

final recentDocumentsProvider =
    StateNotifierProvider<RecentDocsNotifier, List<DocumentMetadata>>((ref) {
      return RecentDocsNotifier();
    });

class RecentDocsNotifier extends StateNotifier<List<DocumentMetadata>> {
  RecentDocsNotifier() : super([]);

  void addDocument(DocumentMetadata doc) {
    state = [doc, ...state.where((d) => d.id != doc.id).take(9)];
  }
}
