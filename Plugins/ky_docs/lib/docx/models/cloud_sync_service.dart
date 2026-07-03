import 'dart:async';

import 'document_metadata.dart';

class CloudSyncService {
  bool _isOnline = true;
  Timer? _syncTimer;
  final _syncQueue = <String, Map<String, dynamic>>{};
  bool get isOnline => _isOnline;
  bool get isSyncing => _syncQueue.isNotEmpty;
  int get pendingSyncCount => _syncQueue.length;
  void initialize() {
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _processSyncQueue();
    });
  }

  void dispose() {
    _syncTimer?.cancel();
  }

  Future<void> syncDocument(
    String docId,
    String content,
    DocumentMetadata metadata,
  ) async {
    _syncQueue[docId] = {
      'content': content,
      'metadata': metadata.toJson(),
      'timestamp': DateTime.now().toIso8601String(),
    };
    await _processSyncQueue();
  }

  Future<void> _processSyncQueue() async {
    if (_syncQueue.isEmpty || !_isOnline) return;
    await Future.delayed(const Duration(seconds: 1));
    _syncQueue.clear();
  }

  Future<Map<String, dynamic>?> fetchDocument(String docId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return null;
  }

  Future<List<String>> getCloudDocumentIds() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [];
  }

  void setOnlineStatus(bool online) {
    _isOnline = online;
  }
}
