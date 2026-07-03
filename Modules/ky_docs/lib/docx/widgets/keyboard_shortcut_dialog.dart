import 'package:flutter/material.dart';

import 'keyboard_shortcuts/document_keyboard_shortcut.dart';
import 'keyboard_shortcuts/document_keyboard_shortcut_catalog.dart';

class KeyboardShortcutDialog extends StatefulWidget {
  static const searchFieldKey = ValueKey('keyboard-shortcut-search');

  final List<DocumentKeyboardShortcutGroup> groups;

  const KeyboardShortcutDialog({
    super.key,
    this.groups = documentKeyboardShortcutGroups,
  });

  @override
  State<KeyboardShortcutDialog> createState() => _KeyboardShortcutDialogState();
}

class _KeyboardShortcutDialogState extends State<KeyboardShortcutDialog> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filteredGroups = widget.groups
        .map((group) => group.filtered(_query))
        .where((group) => group.shortcuts.isNotEmpty)
        .toList();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 10, 8),
              child: Row(
                children: [
                  Icon(Icons.keyboard_alt_outlined, color: colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Keyboard shortcuts',
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
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
              child: TextField(
                key: KeyboardShortcutDialog.searchFieldKey,
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search shortcuts',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.close),
                          onPressed: _clearSearch,
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  isDense: true,
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            Divider(height: 1, color: colorScheme.outlineVariant),
            Flexible(
              child: filteredGroups.isEmpty
                  ? const _EmptyShortcutState()
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(14),
                      itemCount: filteredGroups.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _ShortcutGroupCard(group: filteredGroups[index]);
                      },
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

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
  }
}

class _ShortcutGroupCard extends StatelessWidget {
  final DocumentKeyboardShortcutGroup group;

  const _ShortcutGroupCard({required this.group});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
        child: Column(
          children: [
            Row(
              children: [
                Icon(group.icon, size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    group.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '${group.shortcuts.length}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...group.shortcuts.map((shortcut) {
              return _ShortcutRow(shortcut: shortcut);
            }),
          ],
        ),
      ),
    );
  }
}

class _ShortcutRow extends StatelessWidget {
  final DocumentKeyboardShortcut shortcut;

  const _ShortcutRow({required this.shortcut});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              shortcut.label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          _ShortcutChord(keys: shortcut.keys),
        ],
      ),
    );
  }
}

class _ShortcutChord extends StatelessWidget {
  final List<String> keys;

  const _ShortcutChord({required this.keys});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var index = 0; index < keys.length; index++) ...[
          if (index > 0) const Text('+'),
          _ShortcutKeyCap(label: keys[index]),
        ],
      ],
    );
  }
}

class _ShortcutKeyCap extends StatelessWidget {
  final String label;

  const _ShortcutKeyCap({required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(minWidth: 30),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _EmptyShortcutState extends StatelessWidget {
  const _EmptyShortcutState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Text('No shortcuts found', textAlign: TextAlign.center),
      ),
    );
  }
}
