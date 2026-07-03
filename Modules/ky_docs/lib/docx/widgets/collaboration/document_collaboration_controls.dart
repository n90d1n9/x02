import 'package:flutter/material.dart';

import '../../models/collaboration_user.dart';

class DocumentCollaborationControls extends StatelessWidget {
  final bool isEnabled;
  final List<CollaborationUser> collaborators;
  final VoidCallback onEnable;
  final VoidCallback onDisable;
  final VoidCallback onAddCollaborator;
  final DateTime? now;

  const DocumentCollaborationControls({
    super.key,
    required this.isEnabled,
    required this.collaborators,
    required this.onEnable,
    required this.onDisable,
    required this.onAddCollaborator,
    this.now,
  });

  @override
  Widget build(BuildContext context) {
    if (!isEnabled) {
      return _InactiveCollaborationView(onEnable: onEnable);
    }

    return _ActiveCollaborationView(
      collaborators: collaborators,
      onDisable: onDisable,
      onAddCollaborator: onAddCollaborator,
      now: now ?? DateTime.now(),
    );
  }
}

class _InactiveCollaborationView extends StatelessWidget {
  final VoidCallback onEnable;

  const _InactiveCollaborationView({required this.onEnable});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.people_outline, color: colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shared editing is off',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Turn it on to show live collaborators and cursor presence.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onEnable,
            icon: const Icon(Icons.group_add_outlined),
            label: const Text('Enable collaboration'),
          ),
        ),
      ],
    );
  }
}

class _ActiveCollaborationView extends StatelessWidget {
  final List<CollaborationUser> collaborators;
  final VoidCallback onDisable;
  final VoidCallback onAddCollaborator;
  final DateTime now;

  const _ActiveCollaborationView({
    required this.collaborators,
    required this.onDisable,
    required this.onAddCollaborator,
    required this.now,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _CollaborationStatusCard(collaboratorCount: collaborators.length),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Text(
                'Active collaborators',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            TextButton.icon(
              onPressed: onAddCollaborator,
              icon: const Icon(Icons.person_add_alt_1, size: 18),
              label: const Text('Add sample'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (collaborators.isEmpty)
          _EmptyPresenceCard(onAddCollaborator: onAddCollaborator)
        else
          _CollaboratorList(collaborators: collaborators, now: now),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.errorContainer.withValues(alpha: 0.24),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colorScheme.error.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.link_off, color: colorScheme.error, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Stop sharing to clear collaborator presence from this document.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurface),
                ),
              ),
              const SizedBox(width: 10),
              TextButton(onPressed: onDisable, child: const Text('Disable')),
            ],
          ),
        ),
      ],
    );
  }
}

class _CollaborationStatusCard extends StatelessWidget {
  final int collaboratorCount;

  const _CollaborationStatusCard({required this.collaboratorCount});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_done_outlined, color: colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Collaboration active',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  '$collaboratorCount people connected to this session',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CollaboratorList extends StatelessWidget {
  final List<CollaborationUser> collaborators;
  final DateTime now;

  const _CollaboratorList({required this.collaborators, required this.now});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < collaborators.length; index++) ...[
          _CollaboratorTile(user: collaborators[index], now: now),
          if (index < collaborators.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _CollaboratorTile extends StatelessWidget {
  final CollaborationUser user;
  final DateTime now;

  const _CollaboratorTile({required this.user, required this.now});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: user.color.withValues(alpha: 0.16),
            child: Text(
              _initials(user.name),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: user.color,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  'Cursor ${user.cursorPosition} - ${_activityLabel(user.lastActive, now)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _PresenceDot(color: user.color),
        ],
      ),
    );
  }

  String _initials(String name) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) return words.first.characters.first.toUpperCase();
    return '${words.first.characters.first}${words.last.characters.first}'
        .toUpperCase();
  }

  String _activityLabel(DateTime lastActive, DateTime now) {
    final elapsed = now.difference(lastActive);
    if (elapsed.inSeconds < 60) return 'active now';
    if (elapsed.inMinutes < 60) return '${elapsed.inMinutes} min ago';
    return '${elapsed.inHours} hr ago';
  }
}

class _PresenceDot extends StatelessWidget {
  final Color color;

  const _PresenceDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).colorScheme.surface),
      ),
    );
  }
}

class _EmptyPresenceCard extends StatelessWidget {
  final VoidCallback onAddCollaborator;

  const _EmptyPresenceCard({required this.onAddCollaborator});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(Icons.person_search_outlined, color: colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            'No collaborators yet',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Add a sample collaborator to preview the shared editing roster.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onAddCollaborator,
            icon: const Icon(Icons.person_add_alt_1, size: 18),
            label: const Text('Add sample'),
          ),
        ],
      ),
    );
  }
}
