import 'package:flutter/material.dart';

import '../../models/document_state.dart';

class DocumentSyncIndicator extends StatelessWidget {
  final DocumentState documentState;

  const DocumentSyncIndicator({super.key, required this.documentState});

  @override
  Widget build(BuildContext context) {
    if (documentState.isSyncing) {
      return const Padding(
        padding: EdgeInsets.only(right: 8.0),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final lastSyncTime = documentState.lastSyncTime;
    if (lastSyncTime == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Tooltip(
        message: 'Last synced: ${_formatRelativeTime(lastSyncTime)}',
        child: const Icon(Icons.cloud_done, size: 20, color: Colors.green),
      ),
    );
  }
}

String _formatRelativeTime(DateTime time) {
  final now = DateTime.now();
  final diff = now.difference(time);

  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}
