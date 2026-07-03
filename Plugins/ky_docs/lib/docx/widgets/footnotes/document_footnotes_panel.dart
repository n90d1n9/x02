import 'package:flutter/material.dart';

import '../../models/footnote.dart';
import '../panel/document_panel_empty_state.dart';
import '../panel/document_panel_item_card.dart';
import '../panel/document_panel_summary_card.dart';

/// Displays document footnotes with summary, empty, edit, and delete states.
class DocumentFootnotesPanel extends StatelessWidget {
  final List<Footnote> footnotes;
  final VoidCallback onAddFootnote;
  final ValueChanged<Footnote> onEditFootnote;
  final ValueChanged<Footnote> onDeleteFootnote;

  const DocumentFootnotesPanel({
    super.key,
    required this.footnotes,
    required this.onAddFootnote,
    required this.onEditFootnote,
    required this.onDeleteFootnote,
  });

  @override
  Widget build(BuildContext context) {
    if (footnotes.isEmpty) {
      return _EmptyFootnotesState(onAddFootnote: onAddFootnote);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _FootnotesSummaryCard(
          count: footnotes.length,
          onAddFootnote: onAddFootnote,
        ),
        const SizedBox(height: 14),
        for (var index = 0; index < footnotes.length; index++) ...[
          _FootnoteCard(
            footnote: footnotes[index],
            onEdit: () => onEditFootnote(footnotes[index]),
            onDelete: () => onDeleteFootnote(footnotes[index]),
          ),
          if (index < footnotes.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _EmptyFootnotesState extends StatelessWidget {
  final VoidCallback onAddFootnote;

  const _EmptyFootnotesState({required this.onAddFootnote});

  @override
  Widget build(BuildContext context) {
    return DocumentPanelEmptyState(
      icon: Icons.notes_outlined,
      title: 'No footnotes yet',
      message: 'Add references without interrupting the document flow.',
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 42),
      iconSize: 46,
      action: FilledButton.icon(
        onPressed: onAddFootnote,
        icon: const Icon(Icons.add),
        label: const Text('Add footnote'),
      ),
    );
  }
}

class _FootnotesSummaryCard extends StatelessWidget {
  final int count;
  final VoidCallback onAddFootnote;

  const _FootnotesSummaryCard({
    required this.count,
    required this.onAddFootnote,
  });

  @override
  Widget build(BuildContext context) {
    return DocumentPanelSummaryCard(
      icon: Icons.format_list_numbered,
      title: '$count ${count == 1 ? 'footnote' : 'footnotes'}',
      subtitle: 'References are numbered in reading order.',
      trailing: IconButton.filledTonal(
        tooltip: 'Add footnote',
        onPressed: onAddFootnote,
        icon: const Icon(Icons.add),
      ),
    );
  }
}

class _FootnoteCard extends StatelessWidget {
  final Footnote footnote;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FootnoteCard({
    required this.footnote,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DocumentPanelItemCard(
      leading: DocumentPanelNumberBadge(label: '${footnote.number}'),
      title: Text(
        footnote.text,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        'Anchor position ${footnote.offset}',
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Edit footnote ${footnote.number}',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Delete footnote ${footnote.number}',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}
