import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../states/attachment_provider.dart';

class AttachmentsPanel extends ConsumerWidget {
  const AttachmentsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attachments = ref.watch(attachmentsProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.attach_file),
                    const SizedBox(width: 12),
                    Text(
                      'Attachments',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        ref
                            .read(attachmentsProvider.notifier)
                            .addAttachment(
                              'new_file_${DateTime.now().millisecondsSinceEpoch}.pdf',
                              'application/pdf',
                              512000,
                            );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: attachments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.attach_file,
                              size: 64,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No attachments yet',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              icon: const Icon(Icons.upload_file),
                              label: const Text('Upload File'),
                              onPressed: () {
                                ref
                                    .read(attachmentsProvider.notifier)
                                    .addAttachment(
                                      'sample_document.pdf',
                                      'application/pdf',
                                      1024576,
                                    );
                              },
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: attachments.length,
                        itemBuilder: (context, index) {
                          final attachment = attachments[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _getFileColor(attachment.type),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _getFileIcon(attachment.type),
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              title: Text(attachment.name),
                              subtitle: Text(
                                '${_formatFileSize(attachment.size)} • ${_formatTime(attachment.uploadedAt)}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.download, size: 20),
                                    onPressed: () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Downloading ${attachment.name}',
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      ref
                                          .read(attachmentsProvider.notifier)
                                          .removeAttachment(attachment.id);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getFileColor(String type) {
    if (type.contains('pdf')) return Colors.red;
    if (type.contains('image')) return Colors.blue;
    if (type.contains('word') || type.contains('document')) {
      return Colors.indigo;
    }
    if (type.contains('excel') || type.contains('spreadsheet')) {
      return Colors.green;
    }
    return Colors.grey;
  }

  IconData _getFileIcon(String type) {
    if (type.contains('pdf')) return Icons.picture_as_pdf;
    if (type.contains('image')) return Icons.image;
    if (type.contains('word') || type.contains('document')) {
      return Icons.description;
    }
    if (type.contains('excel') || type.contains('spreadsheet')) {
      return Icons.table_chart;
    }
    return Icons.insert_drive_file;
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d, yyyy').format(time);
  }
}
