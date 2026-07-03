import 'package:flutter/material.dart';

import '../../models/block_option.dart';

class SlashMenuContent extends StatelessWidget {
  final String query;
  final Function(String) onSelect;

  const SlashMenuContent({
    super.key,
    required this.query,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final blocks = [
      BlockOption(
        'heading1',
        'Heading 1',
        Icons.title,
        'Large section heading',
      ),
      BlockOption(
        'heading2',
        'Heading 2',
        Icons.title,
        'Medium section heading',
      ),
      BlockOption(
        'heading3',
        'Heading 3',
        Icons.title,
        'Small section heading',
      ),
      BlockOption(
        'bullet',
        'Bulleted List',
        Icons.format_list_bulleted,
        'Create a simple list',
      ),
      BlockOption(
        'numbered',
        'Numbered List',
        Icons.format_list_numbered,
        'Create a list with numbering',
      ),
      BlockOption('quote', 'Quote', Icons.format_quote, 'Capture a quote'),
      BlockOption('code', 'Code Block', Icons.code, 'Capture a code snippet'),
      BlockOption(
        'divider',
        'Divider',
        Icons.horizontal_rule,
        'Visually divide blocks',
      ),
      BlockOption('table', 'Table', Icons.table_chart, 'Insert a table'),
      BlockOption(
        'callout',
        'Callout',
        Icons.campaign,
        'Add a highlighted note',
      ),
      BlockOption(
        'checkbox',
        'Checkbox',
        Icons.check_box_outlined,
        'Track tasks with checkboxes',
      ),
    ];

    final filtered = blocks.where((block) {
      return block.title.toLowerCase().contains(query.toLowerCase()) ||
          block.description.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final block = filtered[index];
        return InkWell(
          onTap: () => onSelect(block.id),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    block.icon,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        block.title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        block.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
