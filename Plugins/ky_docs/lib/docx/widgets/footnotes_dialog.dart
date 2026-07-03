import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/footnote.dart';
import '../states/provider.dart';
import 'footnotes/document_footnotes_panel.dart';
import 'footnotes/footnote_text_dialog.dart';

class FootnotesDialog extends ConsumerWidget {
  const FootnotesDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final footnotes = ref.watch(documentProvider).footnotes;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 10, 8),
              child: Row(
                children: [
                  Icon(
                    Icons.notes_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Footnotes',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Add footnote',
                    icon: const Icon(Icons.add),
                    onPressed: () => _addFootnote(context, ref),
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
                child: DocumentFootnotesPanel(
                  footnotes: footnotes,
                  onAddFootnote: () => _addFootnote(context, ref),
                  onEditFootnote: (footnote) {
                    _editFootnote(context, ref, footnote);
                  },
                  onDeleteFootnote: (footnote) {
                    ref
                        .read(documentProvider.notifier)
                        .deleteFootnote(footnote.id);
                  },
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

  Future<void> _addFootnote(BuildContext context, WidgetRef ref) async {
    final text = await FootnoteTextDialog.show(
      context,
      title: 'Add footnote',
      actionLabel: 'Add',
    );
    if (text == null) return;

    ref.read(documentProvider.notifier).addFootnote(text);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Footnote added')));
  }

  Future<void> _editFootnote(
    BuildContext context,
    WidgetRef ref,
    Footnote footnote,
  ) async {
    final text = await FootnoteTextDialog.show(
      context,
      title: 'Edit footnote ${footnote.number}',
      actionLabel: 'Save',
      initialText: footnote.text,
    );
    if (text == null) return;

    ref.read(documentProvider.notifier).updateFootnote(footnote.id, text);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Footnote updated')));
  }
}
