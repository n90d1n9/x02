import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../states/provider.dart';
import 'collaboration/document_collaboration_controls.dart';

class CollaborationDialog extends ConsumerWidget {
  const CollaborationDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docState = ref.watch(documentProvider);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 10, 8),
              child: Row(
                children: [
                  Icon(
                    Icons.groups_2_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Collaboration',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: DocumentCollaborationControls(
                  isEnabled: docState.isCollaborationEnabled,
                  collaborators: docState.collaborators,
                  onEnable: () => _enableCollaboration(context, ref),
                  onDisable: () => _disableCollaboration(context, ref),
                  onAddCollaborator: () => _addSampleCollaborator(ref),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 14),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _enableCollaboration(BuildContext context, WidgetRef ref) {
    final messenger = ScaffoldMessenger.of(context);
    ref
        .read(documentProvider.notifier)
        .enableCollaboration('local_user', 'You');
    Navigator.pop(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Collaboration enabled')),
    );
  }

  void _disableCollaboration(BuildContext context, WidgetRef ref) {
    ref.read(documentProvider.notifier).disableCollaboration();
    Navigator.pop(context);
  }

  void _addSampleCollaborator(WidgetRef ref) {
    final count = ref.read(documentProvider).collaborators.length;
    ref
        .read(documentProvider.notifier)
        .addMockCollaborator('Guest ${count + 1}');
  }
}
