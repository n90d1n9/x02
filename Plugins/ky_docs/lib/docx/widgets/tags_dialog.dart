import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../states/provider.dart';
import 'panel/document_panel_text_field.dart';

/// Manages document tags through a compact add/remove dialog.
class TagsDialog extends ConsumerStatefulWidget {
  const TagsDialog({super.key});

  @override
  ConsumerState<TagsDialog> createState() => _TagsDialogState();
}

class _TagsDialogState extends ConsumerState<TagsDialog> {
  late final TextEditingController _tagController;
  bool _hasTagText = false;

  @override
  void initState() {
    super.initState();
    _tagController = TextEditingController()..addListener(_syncTagTextState);
  }

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final docState = ref.watch(documentProvider);
    return AlertDialog(
      title: const Text('Manage Tags'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DocumentPanelTextField(
            controller: _tagController,
            labelText: 'Add Tag',
            hintText: 'review, client, draft',
            prefixIcon: Icons.sell_outlined,
            textInputAction: TextInputAction.done,
            onSubmitted: _addTagText,
            suffixIcon: IconButton(
              tooltip: 'Add tag',
              icon: const Icon(Icons.add),
              onPressed: _hasTagText ? _addTag : null,
            ),
          ),
          const SizedBox(height: 16),
          if (docState.metadata.tags.isEmpty)
            const Text('No tags yet. Add one above!')
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: docState.metadata.tags.map((tag) {
                return Chip(
                  label: Text(tag),
                  onDeleted: () {
                    ref.read(documentProvider.notifier).removeTag(tag);
                    setState(() {});
                  },
                );
              }).toList(),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  void _syncTagTextState() {
    final nextHasText = _tagController.text.trim().isNotEmpty;
    if (nextHasText == _hasTagText) return;
    setState(() => _hasTagText = nextHasText);
  }

  void _addTag() {
    _addTagText(_tagController.text);
  }

  void _addTagText(String value) {
    final tag = value.trim();
    if (tag.isEmpty) return;

    ref.read(documentProvider.notifier).addTag(tag);
    _tagController.clear();
  }
}
