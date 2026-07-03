import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/folder.dart';
import '../states/provider.dart';

class MoveToFolderDialog extends ConsumerWidget {
  final List<Folder> folders;
  const MoveToFolderDialog({super.key, required this.folders});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docState = ref.read(documentProvider);
    return AlertDialog(
      title: const Text('Move to Folder'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.folder_open),
            title: const Text('No Folder'),
            selected: docState.metadata.folderId == null,
            onTap: () {
              ref.read(documentProvider.notifier).moveToFolder(null);
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Moved to root')));
            },
          ),
          ...folders.map((folder) {
            return ListTile(
              leading: Icon(folder.icon, color: folder.color),
              title: Text(folder.name),
              selected: docState.metadata.folderId == folder.id,
              onTap: () {
                ref.read(documentProvider.notifier).moveToFolder(folder.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Moved to ${folder.name}')),
                );
              },
            );
          }),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
