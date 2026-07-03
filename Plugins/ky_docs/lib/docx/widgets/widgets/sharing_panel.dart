import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/share_user.dart';
import '../../states/sharing_provider.dart';

class SharingPanel extends ConsumerStatefulWidget {
  const SharingPanel({super.key});

  @override
  ConsumerState<SharingPanel> createState() => _SharingPanelState();
}

class _SharingPanelState extends ConsumerState<SharingPanel> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  DocumentPermission _selectedPermission = DocumentPermission.view;

  @override
  Widget build(BuildContext context) {
    final sharingState = ref.watch(sharingProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
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
                    Text(
                      'Share Document',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Add people section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add People',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Name',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child:
                                      DropdownButtonFormField<
                                        DocumentPermission
                                      >(
                                        initialValue: _selectedPermission,
                                        decoration: const InputDecoration(
                                          labelText: 'Permission',
                                          border: OutlineInputBorder(),
                                        ),
                                        items: DocumentPermission.values.map((
                                          perm,
                                        ) {
                                          return DropdownMenuItem(
                                            value: perm,
                                            child: Text(_permissionName(perm)),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          if (value != null) {
                                            setState(() {
                                              _selectedPermission = value;
                                            });
                                          }
                                        },
                                      ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    if (_nameController.text.isNotEmpty &&
                                        _emailController.text.isNotEmpty) {
                                      ref
                                          .read(sharingProvider.notifier)
                                          .shareWithUser(
                                            _nameController.text,
                                            _emailController.text,
                                            _selectedPermission,
                                          );
                                      _nameController.clear();
                                      _emailController.clear();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('User added'),
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text('Add'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Public link
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Public Link',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const Spacer(),
                                Switch(
                                  value: sharingState.isPublic,
                                  onChanged: (_) {
                                    ref
                                        .read(sharingProvider.notifier)
                                        .togglePublicAccess();
                                  },
                                ),
                              ],
                            ),
                            if (sharingState.isPublic &&
                                sharingState.publicLink != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        sharingState.publicLink!,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.copy, size: 18),
                                      onPressed: () {
                                        Clipboard.setData(
                                          ClipboardData(
                                            text: sharingState.publicLink!,
                                          ),
                                        );
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Link copied'),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Shared users
                    Text(
                      'People with access',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ...sharingState.sharedUsers.map((user) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(child: Text(user.name[0])),
                          title: Text(user.name),
                          subtitle: Text(user.email),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              DropdownButton<DocumentPermission>(
                                value: user.permission,
                                underline: const SizedBox(),
                                items: DocumentPermission.values.map((perm) {
                                  return DropdownMenuItem(
                                    value: perm,
                                    child: Text(_permissionName(perm)),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    ref
                                        .read(sharingProvider.notifier)
                                        .updatePermission(user.id, value);
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                ),
                                onPressed: () {
                                  ref
                                      .read(sharingProvider.notifier)
                                      .removeUser(user.id);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _permissionName(DocumentPermission perm) {
    switch (perm) {
      case DocumentPermission.view:
        return 'View';
      case DocumentPermission.comment:
        return 'Comment';
      case DocumentPermission.edit:
        return 'Edit';
      case DocumentPermission.admin:
        return 'Admin';
    }
  }
}
