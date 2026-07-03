import 'package:flutter_riverpod/legacy.dart';

import '../models/document_version.dart';

final versionHistoryProvider =
    StateNotifierProvider<VersionHistoryNotifier, List<DocumentVersion>>((ref) {
      return VersionHistoryNotifier();
    });

class VersionHistoryNotifier extends StateNotifier<List<DocumentVersion>> {
  VersionHistoryNotifier() : super([]) {
    _loadMockVersions();
  }

  void _loadMockVersions() {
    final now = DateTime.now();
    state = [
      DocumentVersion(
        id: 'v1',
        title: 'Initial Draft',
        timestamp: now.subtract(const Duration(days: 2)),
        author: 'Current User',
        content: '{}',
        description: 'Created document',
      ),
      DocumentVersion(
        id: 'v2',
        title: 'Added Introduction',
        timestamp: now.subtract(const Duration(days: 1)),
        author: 'Current User',
        content: '{}',
        description: 'Added introduction section',
      ),
      DocumentVersion(
        id: 'v3',
        title: 'Major Revision',
        timestamp: now.subtract(const Duration(hours: 3)),
        author: 'Alice Johnson',
        content: '{}',
        description: 'Revised content structure',
      ),
    ];
  }

  void createVersion(
    String title,
    String author,
    String content,
    String description,
  ) {
    final version = DocumentVersion(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      timestamp: DateTime.now(),
      author: author,
      content: content,
      description: description,
    );
    state = [version, ...state];
  }
}
