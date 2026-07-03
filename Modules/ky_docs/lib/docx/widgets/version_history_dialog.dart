import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../states/provider.dart';

class VersionHistoryDialog extends ConsumerWidget {
  const VersionHistoryDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docState = ref.read(documentProvider);
    return AlertDialog(
      title: const Text('Version History'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child:
            docState.versions.isEmpty
                ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 60, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No versions saved yet'),
                      SizedBox(height: 8),
                      Text(
                        'Versions are created when you save',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                )
                : ListView.builder(
                  shrinkWrap: true,
                  itemCount: docState.versions.length,
                  itemBuilder: (context, index) {
                    final version = docState.versions[index];
                    final isCurrentVersion =
                        index == docState.currentVersionIndex;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(
                          isCurrentVersion ? Icons.check_circle : Icons.history,
                          color: isCurrentVersion ? Colors.green : null,
                        ),
                        title: Text(version.description),
                        subtitle: Text(_formatDateTime(version.timestamp)),
                        trailing:
                            isCurrentVersion
                                ? const Chip(
                                  label: Text(
                                    'Current',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                  backgroundColor: Colors.green,
                                  labelStyle: TextStyle(color: Colors.white),
                                  visualDensity: VisualDensity.compact,
                                )
                                : TextButton(
                                  onPressed: () {
                                    ref
                                        .read(documentProvider.notifier)
                                        .restoreVersion(index);
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Version restored successfully',
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text('Restore'),
                                ),
                      ),
                    );
                  },
                ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
        '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
