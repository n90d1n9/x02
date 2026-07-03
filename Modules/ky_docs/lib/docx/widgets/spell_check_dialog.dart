import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/spell_check_error.dart';
import '../states/provider.dart';
import 'spell_check/document_spell_check_panel.dart';

class SpellCheckDialog extends ConsumerWidget {
  const SpellCheckDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final errors = ref.watch(documentProvider).spellErrors;

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
                    Icons.spellcheck_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Spell check',
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
                child: DocumentSpellCheckPanel(
                  errors: errors,
                  onReplaceWithSuggestion: (error, suggestion) {
                    _replaceWithSuggestion(context, ref, error, suggestion);
                  },
                  onIgnore: (error) {
                    ref
                        .read(documentProvider.notifier)
                        .ignoreSpellingError(error.word);
                  },
                  onAddToDictionary: (error) {
                    _addToDictionary(context, ref, error);
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

  void _replaceWithSuggestion(
    BuildContext context,
    WidgetRef ref,
    SpellCheckError error,
    String suggestion,
  ) {
    ref
        .read(documentProvider.notifier)
        .replaceWithSuggestion(error, suggestion);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Replaced with "$suggestion"')));
  }

  void _addToDictionary(
    BuildContext context,
    WidgetRef ref,
    SpellCheckError error,
  ) {
    ref.read(documentProvider.notifier).addWordToDictionary(error.word);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Added to dictionary')));
  }
}
