import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../states/docs_provider.dart';
import '../widget_gallery/widget_gallery_card.dart';
import '../widget_gallery/widget_gallery_catalog.dart';
import '../widget_gallery/widget_gallery_category_chip.dart';
import '../widget_gallery/widget_gallery_item.dart';

class WidgetGalleryPanel extends ConsumerStatefulWidget {
  const WidgetGalleryPanel({super.key});

  @override
  ConsumerState<WidgetGalleryPanel> createState() => _WidgetGalleryPanelState();
}

class _WidgetGalleryPanelState extends ConsumerState<WidgetGalleryPanel> {
  String _selectedCategory = 'all';
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredWidgets = _getFilteredWidgets();

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.widgets,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Insert Block or Widget',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Search bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search widgets...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),
              // Categories
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final category in widgetGalleryCategories)
                        WidgetGalleryCategoryChip(
                          category: category,
                          selected: _selectedCategory == category.id,
                          onSelected: (id) {
                            setState(() {
                              _selectedCategory = id;
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Widget grid
              Expanded(
                child: GridView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: filteredWidgets.length,
                  itemBuilder: (context, index) {
                    final item = filteredWidgets[index];
                    return WidgetGalleryCard(
                      item: item,
                      onTap: () {
                        _insertWidget(item.id);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<WidgetGalleryItem> _getFilteredWidgets() {
    var filtered = widgetGalleryItems;

    // Filter by category
    if (_selectedCategory != 'all') {
      filtered = filtered
          .where((w) => w.category == _selectedCategory)
          .toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((w) {
        return w.name.toLowerCase().contains(_searchQuery) ||
            w.description.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    return filtered;
  }

  void _insertWidget(String widgetId) {
    if (widgetId == 'youtube') {
      _showYoutubeDialog();
    } else if (widgetId == 'image') {
      _showImageDialog();
    } else if (widgetId.startsWith('chart_')) {
      _showChartDialog(widgetId);
    } else if (widgetId == 'maps') {
      _showMapsDialog();
    } else if (widgetId == 'iframe') {
      _showIframeDialog();
    } else {
      // Insert basic block
      ref.read(documentControllerProvider.notifier).insertBlock(widgetId);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Inserted $widgetId')));
    }
  }

  void _showYoutubeDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.play_circle, color: Colors.red),
            SizedBox(width: 8),
            Text('Embed YouTube Video'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'YouTube URL',
                hintText: 'https://www.youtube.com/watch?v=...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Paste the YouTube video URL',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                final index = ref
                    .read(documentControllerProvider)
                    .controller
                    .selection
                    .baseOffset;
                ref
                    .read(documentControllerProvider)
                    .controller
                    .document
                    .insert(index, '\n[YouTube: ${controller.text}]\n');
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('YouTube video embedded')),
                );
              }
            },
            child: const Text('Insert'),
          ),
        ],
      ),
    );
  }

  void _showImageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.image, color: Colors.pink),
            SizedBox(width: 8),
            Text('Insert Image'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.upload, color: Colors.blue),
              ),
              title: const Text('Upload from device'),
              subtitle: const Text('Choose from gallery or camera'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Image uploaded')));
              },
            ),
            const Divider(),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.link, color: Colors.green),
              ),
              title: const Text('Insert from URL'),
              subtitle: const Text('Paste image link'),
              onTap: () {
                Navigator.pop(context);
                _showUrlDialog('Image', Icons.image);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showUrlDialog(String type, IconData icon) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 8),
            Text('Insert $type URL'),
          ],
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'URL',
            hintText: 'https://...',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.link),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                final index = ref
                    .read(documentControllerProvider)
                    .controller
                    .selection
                    .baseOffset;
                ref
                    .read(documentControllerProvider)
                    .controller
                    .document
                    .insert(index, '\n[$type: ${controller.text}]\n');
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('$type inserted')));
              }
            },
            child: const Text('Insert'),
          ),
        ],
      ),
    );
  }

  void _showChartDialog(String chartType) {
    final chartName = chartType.split('_').last;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.bar_chart, color: Colors.blue),
            const SizedBox(width: 8),
            Text('Insert ${chartName.toUpperCase()} Chart'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A sample chart will be inserted. You can edit the data after insertion.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 20, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Double-click the chart to edit data',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final index = ref
                  .read(documentControllerProvider)
                  .controller
                  .selection
                  .baseOffset;
              ref
                  .read(documentControllerProvider)
                  .controller
                  .document
                  .insert(index, '\n[Chart: $chartType - Sample Data]\n');
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Chart inserted')));
            },
            child: const Text('Insert Chart'),
          ),
        ],
      ),
    );
  }

  void _showMapsDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.map, color: Colors.green),
            SizedBox(width: 8),
            Text('Embed Google Maps'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Location or Maps URL',
                hintText: 'Enter address or Google Maps link',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                final index = ref
                    .read(documentControllerProvider)
                    .controller
                    .selection
                    .baseOffset;
                ref
                    .read(documentControllerProvider)
                    .controller
                    .document
                    .insert(index, '\n[Maps: ${controller.text}]\n');
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Map embedded')));
              }
            },
            child: const Text('Insert'),
          ),
        ],
      ),
    );
  }

  void _showIframeDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.web, color: Colors.indigo),
            SizedBox(width: 8),
            Text('Embed Website'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Website URL',
                hintText: 'https://...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Embed any website as an iframe',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                final index = ref
                    .read(documentControllerProvider)
                    .controller
                    .selection
                    .baseOffset;
                ref
                    .read(documentControllerProvider)
                    .controller
                    .document
                    .insert(index, '\n[Embed: ${controller.text}]\n');
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Website embedded')),
                );
              }
            },
            child: const Text('Insert'),
          ),
        ],
      ),
    );
  }
}
