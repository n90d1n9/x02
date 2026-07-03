// main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'dart:convert';

import 'ppt_provider.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Presentation Viewer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Poppins',
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Poppins',
      ),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}

// Models
class Presentation {
  final String id;
  final String title;
  final DateTime lastModified;
  final List<Slide> slides;

  Presentation({
    required this.id,
    required this.title,
    required this.lastModified,
    required this.slides,
  });

  factory Presentation.fromJson(Map<String, dynamic> json) {
    return Presentation(
      id: json['id'] as String,
      title: json['title'] as String,
      lastModified: DateTime.parse(json['lastModified'] as String),
      slides: (json['slides'] as List)
          .map((slideJson) => Slide.fromJson(slideJson))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'lastModified': lastModified.toIso8601String(),
      'slides': slides.map((slide) => slide.toJson()).toList(),
    };
  }
}

class Slide {
  final String id;
  final String title;
  final String content;
  final SlideType type;

  Slide({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
  });

  factory Slide.fromJson(Map<String, dynamic> json) {
    return Slide(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      type: SlideType.values.firstWhere(
        (e) => e.toString() == 'SlideType.${json['type']}',
        orElse: () => SlideType.text,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'type': type.toString().split('.').last,
    };
  }
}

enum SlideType { text, bulletPoints, image, chart }

// Providers
final presentationsProvider =
    StateNotifierProvider<PresentationsNotifier, List<Presentation>>((ref) {
      return PresentationsNotifier();
    });

final currentPresentationProvider = StateProvider<Presentation?>((ref) => null);

final currentSlideIndexProvider = StateProvider<int>((ref) => 0);

class PresentationsNotifier extends StateNotifier<List<Presentation>> {
  PresentationsNotifier() : super([]) {
    _loadPresentations();
  }

  Future<void> _loadPresentations() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/presentations.json');

      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final List<dynamic> jsonList = json.decode(jsonString);

        state = jsonList.map((json) => Presentation.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error loading presentations: $e');
    }
  }

  Future<void> _savePresentations() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/presentations.json');

      final jsonList = state
          .map((presentation) => presentation.toJson())
          .toList();
      await file.writeAsString(json.encode(jsonList));
    } catch (e) {
      print('Error saving presentations: $e');
    }
  }

  void addPresentation(Presentation presentation) {
    state = [...state, presentation];
    _savePresentations();
  }

  void updatePresentation(Presentation updatedPresentation) {
    state = state.map((presentation) {
      if (presentation.id == updatedPresentation.id) {
        return updatedPresentation;
      }
      return presentation;
    }).toList();
    _savePresentations();
  }

  void deletePresentation(String id) {
    state = state.where((presentation) => presentation.id != id).toList();
    _savePresentations();
  }

  Future<File> exportPresentation(Presentation presentation) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      '${directory.path}/${presentation.title.replaceAll(' ', '_')}.json',
    );

    final jsonData = presentation.toJson();
    await file.writeAsString(json.encode(jsonData));

    return file;
  }
}

// Screens
class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presentations = ref.watch(presentationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Presentations'),
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () {
              // Show sort options
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Show search
            },
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Import PowerPoint',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PowerPointImportScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: presentations.isEmpty
          ? const EmptyStateWidget()
          : PresentationGrid(presentations: presentations),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _createNewPresentation(context, ref);
        },
        icon: const Icon(Icons.add),
        label: const Text('New Presentation'),
      ),
    );
  }

  void _createNewPresentation(BuildContext context, WidgetRef ref) {
    final presentationsNotifier = ref.read(presentationsProvider.notifier);

    final newPresentation = Presentation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Untitled Presentation',
      lastModified: DateTime.now(),
      slides: [
        Slide(
          id: '1',
          title: 'Title Slide',
          content: 'Click to edit this slide',
          type: SlideType.text,
        ),
      ],
    );

    presentationsNotifier.addPresentation(newPresentation);

    ref.read(currentPresentationProvider.notifier).state = newPresentation;
    ref.read(currentSlideIndexProvider.notifier).state = 0;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PresentationEditorScreen()),
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.slideshow,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'No Presentations Yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Text(
            'Create your first presentation to get started',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              // Create new presentation
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Presentation'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () {
              // Import presentation
            },
            icon: const Icon(Icons.upload_file),
            label: const Text('Import Presentation'),
          ),
        ],
      ),
    );
  }
}

class PresentationGrid extends StatelessWidget {
  final List<Presentation> presentations;

  const PresentationGrid({Key? key, required this.presentations})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 4 / 5,
      ),
      itemCount: presentations.length,
      itemBuilder: (context, index) {
        final presentation = presentations[index];
        return PresentationCard(presentation: presentation);
      },
    );
  }
}

class PresentationCard extends ConsumerWidget {
  final Presentation presentation;

  const PresentationCard({Key? key, required this.presentation})
    : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        ref.read(currentPresentationProvider.notifier).state = presentation;
        ref.read(currentSlideIndexProvider.notifier).state = 0;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PresentationEditorScreen(),
          ),
        );
      },
      child: Card(
        elevation: 4,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Expanded(
              child: Container(
                width: double.infinity,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Center(
                  child: Text(
                    presentation.title.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),

            // Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    presentation.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${presentation.slides.length} slides • ${_formatDate(presentation.lastModified)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.share, size: 20),
                        onPressed: () =>
                            _sharePresentation(context, ref, presentation),
                        visualDensity: VisualDensity.compact,
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert, size: 20),
                        onPressed: () =>
                            _showOptionsMenu(context, ref, presentation),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _sharePresentation(
    BuildContext context,
    WidgetRef ref,
    Presentation presentation,
  ) async {
    final presentationsNotifier = ref.read(presentationsProvider.notifier);
    final file = await presentationsNotifier.exportPresentation(presentation);

    await Share.shareXFiles([
      XFile(file.path),
    ], text: 'Check out my presentation: ${presentation.title}');
  }

  void _showOptionsMenu(
    BuildContext context,
    WidgetRef ref,
    Presentation presentation,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Rename'),
                onTap: () {
                  Navigator.pop(context);
                  _showRenameDialog(context, ref, presentation);
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Duplicate'),
                onTap: () {
                  Navigator.pop(context);
                  _duplicatePresentation(ref, presentation);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share'),
                onTap: () {
                  Navigator.pop(context);
                  _sharePresentation(context, ref, presentation);
                },
              ),
              ListTile(
                leading: const Icon(Icons.save_alt),
                title: const Text('Export'),
                onTap: () {
                  Navigator.pop(context);
                  _exportPresentation(context, ref, presentation);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context, ref, presentation);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    Presentation presentation,
  ) {
    final textController = TextEditingController(text: presentation.title);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename Presentation'),
          content: TextField(
            controller: textController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Presentation Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final newTitle = textController.text.trim();
                if (newTitle.isNotEmpty) {
                  final updatedPresentation = Presentation(
                    id: presentation.id,
                    title: newTitle,
                    lastModified: DateTime.now(),
                    slides: presentation.slides,
                  );

                  ref
                      .read(presentationsProvider.notifier)
                      .updatePresentation(updatedPresentation);
                }
                Navigator.pop(context);
              },
              child: const Text('Rename'),
            ),
          ],
        );
      },
    );
  }

  void _duplicatePresentation(WidgetRef ref, Presentation presentation) {
    final newPresentation = Presentation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '${presentation.title} (Copy)',
      lastModified: DateTime.now(),
      slides: presentation.slides,
    );

    ref.read(presentationsProvider.notifier).addPresentation(newPresentation);
  }

  Future<void> _exportPresentation(
    BuildContext context,
    WidgetRef ref,
    Presentation presentation,
  ) async {
    final presentationsNotifier = ref.read(presentationsProvider.notifier);
    await presentationsNotifier.exportPresentation(presentation);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Presentation exported successfully to Documents folder',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    Presentation presentation,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Presentation'),
          content: Text(
            'Are you sure you want to delete "${presentation.title}"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                ref
                    .read(presentationsProvider.notifier)
                    .deletePresentation(presentation.id);
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}

class PresentationEditorScreen extends ConsumerWidget {
  const PresentationEditorScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presentation = ref.watch(currentPresentationProvider);
    final currentSlideIndex = ref.watch(currentSlideIndexProvider);

    if (presentation == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentSlide = presentation.slides[currentSlideIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(presentation.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Edit presentation metadata
            },
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              // Save changes
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Changes saved'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              _sharePresentation(context, ref, presentation);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Slide content area
          Expanded(child: SlideViewerWidget(slide: currentSlide)),

          // Navigation and thumbnails
          SizedBox(
            height: 120,
            child: Column(
              children: [
                // Slide navigation
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Navigation buttons
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.skip_previous),
                            onPressed: currentSlideIndex > 0
                                ? () {
                                    ref
                                        .read(
                                          currentSlideIndexProvider.notifier,
                                        )
                                        .state--;
                                  }
                                : null,
                          ),
                          Text(
                            '${currentSlideIndex + 1}/${presentation.slides.length}',
                          ),
                          IconButton(
                            icon: const Icon(Icons.skip_next),
                            onPressed:
                                currentSlideIndex <
                                    presentation.slides.length - 1
                                ? () {
                                    ref
                                        .read(
                                          currentSlideIndexProvider.notifier,
                                        )
                                        .state++;
                                  }
                                : null,
                          ),
                        ],
                      ),

                      // Add slide button
                      FilledButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Add Slide'),
                        onPressed: () {
                          _addNewSlide(context, ref, presentation);
                        },
                      ),
                    ],
                  ),
                ),

                // Slide thumbnails
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.all(8),
                    itemCount: presentation.slides.length,
                    itemBuilder: (context, index) {
                      final slide = presentation.slides[index];
                      final isSelected = index == currentSlideIndex;

                      return GestureDetector(
                        onTap: () {
                          ref.read(currentSlideIndexProvider.notifier).state =
                              index;
                        },
                        child: Container(
                          width: 120,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey.withValues(alpha: 0.3),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              slide.title,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
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
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _editCurrentSlide(context, ref, presentation, currentSlideIndex);
        },
        child: const Icon(Icons.edit),
      ),
    );
  }

  Future<void> _sharePresentation(
    BuildContext context,
    WidgetRef ref,
    Presentation presentation,
  ) async {
    final presentationsNotifier = ref.read(presentationsProvider.notifier);
    final file = await presentationsNotifier.exportPresentation(presentation);

    await Share.shareXFiles([
      XFile(file.path),
    ], text: 'Check out my presentation: ${presentation.title}');
  }

  void _addNewSlide(
    BuildContext context,
    WidgetRef ref,
    Presentation presentation,
  ) {
    final newSlide = Slide(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'New Slide',
      content: 'Add your content here',
      type: SlideType.text,
    );

    final updatedSlides = [...presentation.slides, newSlide];
    final updatedPresentation = Presentation(
      id: presentation.id,
      title: presentation.title,
      lastModified: DateTime.now(),
      slides: updatedSlides,
    );

    ref
        .read(presentationsProvider.notifier)
        .updatePresentation(updatedPresentation);
    ref.read(currentPresentationProvider.notifier).state = updatedPresentation;
    ref.read(currentSlideIndexProvider.notifier).state =
        updatedSlides.length - 1;
  }

  void _editCurrentSlide(
    BuildContext context,
    WidgetRef ref,
    Presentation presentation,
    int currentSlideIndex,
  ) {
    final currentSlide = presentation.slides[currentSlideIndex];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SlideEditorScreen(
          slide: currentSlide,
          onSave: (updatedSlide) {
            final updatedSlides = [...presentation.slides];
            updatedSlides[currentSlideIndex] = updatedSlide;

            final updatedPresentation = Presentation(
              id: presentation.id,
              title: presentation.title,
              lastModified: DateTime.now(),
              slides: updatedSlides,
            );

            ref
                .read(presentationsProvider.notifier)
                .updatePresentation(updatedPresentation);
            ref.read(currentPresentationProvider.notifier).state =
                updatedPresentation;
          },
        ),
      ),
    );
  }
}

class SlideViewerWidget extends StatelessWidget {
  final Slide slide;

  const SlideViewerWidget({Key? key, required this.slide}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              slide.title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(child: _buildSlideContent(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildSlideContent(BuildContext context) {
    switch (slide.type) {
      case SlideType.text:
        return SingleChildScrollView(
          child: Text(
            slide.content,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        );

      case SlideType.bulletPoints:
        final points = slide.content.split('\n');
        return ListView.builder(
          itemCount: points.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 18)),
                  Expanded(
                    child: Text(
                      points[index],
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
            );
          },
        );

      case SlideType.image:
        return Center(
          child: Container(
            width: double.infinity,
            height: 300,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.image, size: 64, color: Colors.grey),
          ),
        );

      case SlideType.chart:
        return Center(
          child: Container(
            width: double.infinity,
            height: 300,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.bar_chart, size: 64, color: Colors.grey),
          ),
        );
    }
  }
}

class SlideEditorScreen extends StatefulWidget {
  final Slide slide;
  final Function(Slide) onSave;

  const SlideEditorScreen({Key? key, required this.slide, required this.onSave})
    : super(key: key);

  @override
  State<SlideEditorScreen> createState() => _SlideEditorScreenState();
}

class _SlideEditorScreenState extends State<SlideEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late SlideType _slideType;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.slide.title);
    _contentController = TextEditingController(text: widget.slide.content);
    _slideType = widget.slide.type;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Slide'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveSlide),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Slide type selection
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Slide Type',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildTypeOption(
                            SlideType.text,
                            'Text',
                            Icons.text_fields,
                          ),
                          _buildTypeOption(
                            SlideType.bulletPoints,
                            'Bullet Points',
                            Icons.format_list_bulleted,
                          ),
                          _buildTypeOption(
                            SlideType.image,
                            'Image',
                            Icons.image,
                          ),
                          _buildTypeOption(
                            SlideType.chart,
                            'Chart',
                            Icons.bar_chart,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Title field
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Slide Title',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        hintText: 'Enter slide title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content field
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Slide Content',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _contentController,
                      maxLines: 10,
                      decoration: InputDecoration(
                        hintText: _getContentHint(),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    if (_slideType == SlideType.image ||
                        _slideType == SlideType.chart)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: ElevatedButton.icon(
                          onPressed: _pickFile,
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Upload File'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _saveSlide,
            child: const Text('Save Changes'),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeOption(SlideType type, String label, IconData icon) {
    final isSelected = _slideType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _slideType = type;
        });
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Theme.of(context).colorScheme.primary : null,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getContentHint() {
    switch (_slideType) {
      case SlideType.text:
        return 'Enter your slide text content...';
      case SlideType.bulletPoints:
        return 'Enter bullet points (one per line)...';
      case SlideType.image:
        return 'Image description...';
      case SlideType.chart:
        return 'Chart data (JSON format)...';
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: _slideType == SlideType.image ? FileType.image : FileType.any,
    );

    if (result != null) {
      // Handle file selection
      // For a real app, you'd need to implement file storage
      setState(() {
        _contentController.text = 'File selected: ${result.files.single.name}';
      });
    }
  }

  void _saveSlide() {
    final updatedSlide = Slide(
      id: widget.slide.id,
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      type: _slideType,
    );

    widget.onSave(updatedSlide);
    Navigator.pop(context);
  }
}

// Presentation Player Screen
class PresentationPlayerScreen extends ConsumerStatefulWidget {
  final Presentation presentation;

  const PresentationPlayerScreen({Key? key, required this.presentation})
    : super(key: key);

  @override
  ConsumerState<PresentationPlayerScreen> createState() =>
      _PresentationPlayerScreenState();
}

class _PresentationPlayerScreenState
    extends ConsumerState<PresentationPlayerScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isFullScreen
          ? null
          : AppBar(
              title: Text(widget.presentation.title),
              actions: [
                IconButton(
                  icon: const Icon(Icons.fullscreen),
                  onPressed: () {
                    setState(() {
                      _isFullScreen = true;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () => _sharePresentation(context),
                ),
              ],
            ),
      body: Stack(
        children: [
          // Slides
          PageView.builder(
            controller: _pageController,
            itemCount: widget.presentation.slides.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return SlideViewerWidget(
                slide: widget.presentation.slides[index],
              );
            },
          ),

          // Navigation controls
          if (_isFullScreen)
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.fullscreen_exit),
                onPressed: () {
                  setState(() {
                    _isFullScreen = false;
                  });
                },
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
                ),
              ),
            ),

          // Previous button
          if (_currentPage > 0)
            Positioned(
              left: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),

          // Next button
          if (_currentPage < widget.presentation.slides.length - 1)
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),

          // Slide counter
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentPage + 1} / ${widget.presentation.slides.length}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sharePresentation(BuildContext context) async {
    final presentationsNotifier = ref.read(presentationsProvider.notifier);
    final file = await presentationsNotifier.exportPresentation(
      widget.presentation,
    );

    await Share.shareXFiles([
      XFile(file.path),
    ], text: 'Check out my presentation: ${widget.presentation.title}');
  }
}

// pubspec.yaml dependencies:
// dependencies:
//   flutter:
//     sdk: flutter
//   flutter_riverpod: ^2.4.0
//   file_picker: ^5.5.0
//   path_provider: ^2.1.1
//   share_plus: ^7.2.1
