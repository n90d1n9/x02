import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../states/docs_provider.dart';
import '../../states/template_provider.dart';

class TemplateGalleryDialog extends ConsumerStatefulWidget {
  const TemplateGalleryDialog({super.key});

  @override
  ConsumerState<TemplateGalleryDialog> createState() =>
      _TemplateGalleryDialogState();
}

class _TemplateGalleryDialogState extends ConsumerState<TemplateGalleryDialog> {
  String _selectedCategory = 'all';

  @override
  Widget build(BuildContext context) {
    final templates = ref.watch(templateProvider);
    final filteredTemplates = _selectedCategory == 'all'
        ? templates
        : templates.where((t) => t.tags.contains(_selectedCategory)).toList();

    return Dialog(
      child: Container(
        width: 800,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Template Gallery',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _categoryChip('all', 'All Templates'),
                  _categoryChip('productivity', 'Productivity'),
                  _categoryChip('business', 'Business'),
                  _categoryChip('writing', 'Writing'),
                  _categoryChip('personal', 'Personal'),
                  _categoryChip('creative', 'Creative'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: filteredTemplates.length,
                itemBuilder: (context, index) {
                  final template = filteredTemplates[index];
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        ref
                            .read(documentControllerProvider.notifier)
                            .loadFromTemplate(template.content);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Created from "${template.name}"'),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                template.icon,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              template.name,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              template.description,
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Spacer(),
                            Wrap(
                              spacing: 4,
                              children: template.tags.take(2).map((tag) {
                                return Chip(
                                  label: Text(tag),
                                  labelStyle: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.copyWith(fontSize: 10),
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryChip(String value, String label) {
    final isSelected = _selectedCategory == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          setState(() {
            _selectedCategory = value;
          });
        },
      ),
    );
  }
}
