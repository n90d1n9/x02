import 'package:flutter/material.dart';

import '../../models/document_stats.dart';

class StatusBar extends StatelessWidget {
  final DocumentStats stats;
  final DateTime lastModified;

  const StatusBar({super.key, required this.stats, required this.lastModified});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          _StatusItem(
            icon: Icons.article_outlined,
            label: '${stats.words} words',
          ),
          const SizedBox(width: 16),
          _StatusItem(
            icon: Icons.text_fields,
            label: '${stats.characters} chars',
          ),
          const SizedBox(width: 16),
          _StatusItem(
            icon: Icons.schedule,
            label: '${stats.readingTime} min read',
          ),
          const Spacer(),
          _StatusItem(
            icon: Icons.update,
            label: 'Modified ${_formatTime(lastModified)}',
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${time.day}/${time.month}/${time.year}';
  }
}

class _StatusItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatusItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
