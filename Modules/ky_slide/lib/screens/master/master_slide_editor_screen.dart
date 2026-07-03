import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/master/master_slide_model.dart';
import '../../services/master/master_slide_service.dart';

/// Master Slide Editor Screen - PowerPoint-style Slide Master view
class MasterSlideEditorScreen extends ConsumerStatefulWidget {
  const MasterSlideEditorScreen({super.key});

  @override
  ConsumerState<MasterSlideEditorScreen> createState() =>
      _MasterSlideEditorScreenState();
}

class _MasterSlideEditorScreenState
    extends ConsumerState<MasterSlideEditorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _thumbnailScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _thumbnailScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final masterSlide = ref.watch(masterSlideProvider);
    final selectedLayout = ref.watch(selectedLayoutProvider);
    final viewMode = ref.watch(masterViewModeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: _buildAppBar(masterSlide),
      body: Row(
        children: [
          // Left: Layout thumbnails panel
          _buildThumbnailPanel(masterSlide, selectedLayout),

          // Center: Canvas editor
          Expanded(child: _buildCanvasArea(selectedLayout, viewMode)),

          // Right: Properties panel
          _buildPropertiesPanel(selectedLayout),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(MasterSlide masterSlide) {
    return AppBar(
      backgroundColor: const Color(0xFF2D2D2D),
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Slide Master',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            masterSlide.name,
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
      actions: [
        // View mode toggle
        SegmentedButton<MasterViewMode>(
          segments: const [
            ButtonSegment(
              value: MasterViewMode.edit,
              label: Text('Edit'),
              icon: Icon(Icons.edit, size: 18),
            ),
            ButtonSegment(
              value: MasterViewMode.preview,
              label: Text('Preview'),
              icon: Icon(Icons.visibility, size: 18),
            ),
          ],
          selected: {ref.watch(masterViewModeProvider)},
          onSelectionChanged: (Set<MasterViewMode> selected) {
            ref.read(masterViewModeProvider.notifier).state = selected.first;
          },
          style: SegmentedButtonThemeData(
            backgroundColor: Colors.transparent,
            selectedBackgroundColor: Colors.blue.withValues(alpha: 0.2),
          ),
        ),
        const SizedBox(width: 16),

        // Close button
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Close Master View',
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Colors.blue,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        tabs: const [
          Tab(text: 'Layouts', icon: Icon(Icons.layout, size: 18)),
          Tab(text: 'Theme', icon: Icon(Icons.palette, size: 18)),
        ],
      ),
    );
  }

  Widget _buildThumbnailPanel(
    MasterSlide masterSlide,
    MasterLayout? selectedLayout,
  ) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        border: Border(right: BorderSide(color: Colors.white10, width: 1)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Layouts',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 20, color: Colors.blue),
                  onPressed: () => _showAddLayoutDialog(masterSlide),
                  tooltip: 'Add New Layout',
                ),
              ],
            ),
          ),

          // Thumbnail list
          Expanded(
            child: ListView.builder(
              controller: _thumbnailScrollController,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: masterSlide.layouts.length,
              itemBuilder: (context, index) {
                final layout = masterSlide.layouts[index];
                final isSelected = selectedLayout?.id == layout.id;

                return _buildLayoutThumbnail(layout, isSelected, index);
              },
            ),
          ),

          // Footer actions
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D2D),
              border: Border(top: BorderSide(color: Colors.white10, width: 1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: selectedLayout != null
                        ? () => _duplicateLayout(selectedLayout)
                        : null,
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Duplicate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: selectedLayout != null
                      ? () => _deleteLayout(selectedLayout)
                      : null,
                  tooltip: 'Delete Layout',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayoutThumbnail(
    MasterLayout layout,
    bool isSelected,
    int index,
  ) {
    return GestureDetector(
      onTap: () {
        ref.read(selectedLayoutProvider.notifier).state = layout;
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.white10,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            // Thumbnail preview
            Container(
              width: double.infinity,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: CustomPaint(
                  size: Size.infinite,
                  painter: LayoutThumbnailPainter(layout),
                ),
              ),
            ),

            // Layout name
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                layout.name,
                style: TextStyle(
                  color: isSelected ? Colors.blue : Colors.white,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCanvasArea(
    MasterLayout? selectedLayout,
    MasterViewMode viewMode,
  ) {
    if (selectedLayout == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.grid_3x3_rounded, size: 64, color: Colors.white38),
            const SizedBox(height: 16),
            Text(
              'Select a layout to edit',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Click on a layout thumbnail from the left panel',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Container(
      color: const Color(0xFF1E1E1E),
      child: Column(
        children: [
          // Toolbar
          _buildCanvasToolbar(selectedLayout),

          // Canvas
          Expanded(
            child: Center(
              child: Container(
                width: 960,
                height: 540,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CustomPaint(
                    size: const Size(960, 540),
                    painter: MasterSlideCanvasPainter(
                      layout: selectedLayout,
                      isEditMode: viewMode == MasterViewMode.edit,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCanvasToolbar(MasterLayout layout) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        border: Border(bottom: BorderSide(color: Colors.white10, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Insert placeholder buttons
          Text(
            'Insert Placeholder:',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(width: 8),
          _buildToolbarButton(
            icon: Icons.title,
            label: 'Text',
            onPressed: () => _insertPlaceholder(PlaceholderType.title),
          ),
          _buildToolbarButton(
            icon: Icons.image_outlined,
            label: 'Picture',
            onPressed: () => _insertPlaceholder(PlaceholderType.picture),
          ),
          _buildToolbarButton(
            icon: Icons.chart_data,
            label: 'Chart',
            onPressed: () => _insertPlaceholder(PlaceholderType.chart),
          ),
          _buildToolbarButton(
            icon: Icons.table_chart,
            label: 'Table',
            onPressed: () => _insertPlaceholder(PlaceholderType.table),
          ),
          _buildToolbarButton(
            icon: Icons.smart_display,
            label: 'SmartArt',
            onPressed: () => _insertPlaceholder(PlaceholderType.smartArt),
          ),
          _buildToolbarButton(
            icon: Icons.video_library,
            label: 'Video',
            onPressed: () => _insertPlaceholder(PlaceholderType.video),
          ),

          const Spacer(),

          // Background button
          _buildToolbarButton(
            icon: Icons.format_paint,
            label: 'Background',
            onPressed: () => _showBackgroundDialog(layout),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: Colors.white),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: Colors.white70, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertiesPanel(MasterLayout? selectedLayout) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        border: Border(left: BorderSide(color: Colors.white10, width: 1)),
      ),
      child: selectedLayout == null
          ? Center(
              child: Text(
                'No layout selected',
                style: TextStyle(color: Colors.white54),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D2D2D),
                      border: Border(
                        bottom: BorderSide(color: Colors.white10, width: 1),
                      ),
                    ),
                    child: Text(
                      'Layout Properties',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),

                  // Name field
                  _buildPropertySection(
                    title: 'Name',
                    child: TextField(
                      initialValue: selectedLayout.name,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Layout name',
                        hintStyle: TextStyle(color: Colors.white38),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF3D3D3D),
                      ),
                      onChanged: (value) {
                        ref
                            .read(masterSlideProvider.notifier)
                            .updateLayout(
                              selectedLayout.id,
                              selectedLayout.copyWith(name: value),
                            );
                      },
                    ),
                  ),

                  // Type
                  _buildPropertySection(
                    title: 'Type',
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3D3D3D),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getLayoutTypeName(selectedLayout.type),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),

                  // Placeholder count
                  _buildPropertySection(
                    title: 'Placeholders',
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3D3D3D),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.widgets, color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '${selectedLayout.placeholders.length} placeholders',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Background settings
                  _buildPropertySection(
                    title: 'Background',
                    child: _buildBackgroundSelector(selectedLayout),
                  ),

                  // Actions
                  _buildPropertySection(
                    title: 'Actions',
                    child: Column(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () =>
                              _resetLayoutToDefault(selectedLayout),
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Reset to Default'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 40),
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () => _exportLayout(selectedLayout),
                          icon: const Icon(Icons.download, size: 16),
                          label: const Text('Export Layout'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white24),
                            minimumSize: const Size(double.infinity, 40),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPropertySection({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _buildBackgroundSelector(MasterLayout layout) {
    final bgColor = layout.background['color'] ?? '#FFFFFF';

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _hexToColor(bgColor.toString()),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white24),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            bgColor.toString(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.color_lens, size: 20),
          onPressed: () => _showBackgroundDialog(layout),
          tooltip: 'Change background',
        ),
      ],
    );
  }

  void _showAddLayoutDialog(MasterSlide masterSlide) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text(
          'Add New Layout',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: MasterLayoutType.values.map((type) {
            return ListTile(
              leading: Icon(Icons.add_box, color: Colors.blue),
              title: Text(
                _getLayoutTypeName(type),
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                final newLayout = MasterLayout(
                  id: 'layout_${DateTime.now().millisecondsSinceEpoch}',
                  name: _getLayoutTypeName(type),
                  type: type,
                  placeholders: MasterLayout.getDefaultPlaceholdersForType(
                    type,
                  ),
                );
                ref.read(masterSlideProvider.notifier).addLayout(newLayout);
                ref.read(selectedLayoutProvider.notifier).state = newLayout;
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  void _duplicateLayout(MasterLayout layout) {
    ref.read(masterSlideProvider.notifier).duplicateLayout(layout.id);
  }

  void _deleteLayout(MasterLayout layout) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text(
          'Delete Layout',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete "${layout.name}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(masterSlideProvider.notifier).removeLayout(layout.id);
              ref.read(selectedLayoutProvider.notifier).state = null;
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _insertPlaceholder(PlaceholderType type) {
    // Implementation for inserting a new placeholder
  }

  void _showBackgroundDialog(MasterLayout layout) {
    // Implementation for background color picker dialog
  }

  void _resetLayoutToDefault(MasterLayout layout) {
    final defaultPlaceholders = MasterLayout.getDefaultPlaceholdersForType(
      layout.type,
    );
    ref
        .read(masterSlideProvider.notifier)
        .updateLayout(
          layout.id,
          layout.copyWith(placeholders: defaultPlaceholders),
        );
  }

  void _exportLayout(MasterLayout layout) {
    // Implementation for exporting layout to JSON/file
  }

  String _getLayoutTypeName(MasterLayoutType type) {
    switch (type) {
      case MasterLayoutType.titleSlide:
        return 'Title Slide';
      case MasterLayoutType.titleAndContent:
        return 'Title and Content';
      case MasterLayoutType.sectionHeader:
        return 'Section Header';
      case MasterLayoutType.twoContent:
        return 'Two Content';
      case MasterLayoutType.comparison:
        return 'Comparison';
      case MasterLayoutType.titleOnly:
        return 'Title Only';
      case MasterLayoutType.blank:
        return 'Blank';
      case MasterLayoutType.contentWithCaption:
        return 'Content with Caption';
      case MasterLayoutType.pictureWithCaption:
        return 'Picture with Caption';
      case MasterLayoutType.custom:
        return 'Custom';
    }
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }
}

/// Custom painter for layout thumbnail preview
class LayoutThumbnailPainter extends CustomPainter {
  final MasterLayout layout;

  LayoutThumbnailPainter(this.layout);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.grey[300]!;

    // Draw background
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Draw placeholder representations
    for (final placeholder in layout.placeholders.take(5)) {
      final rectPaint = Paint()
        ..color = Colors.blue.withOpacity(0.3)
        ..style = PaintingStyle.fill;

      final borderPaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      // Scale coordinates to thumbnail size
      final scaleX = size.width / 960;
      final scaleY = size.height / 540;

      final rect = Rect.fromLTWH(
        placeholder.x * scaleX,
        placeholder.y * scaleY,
        placeholder.width * scaleX,
        placeholder.height * scaleY,
      );

      canvas.drawRect(rect, rectPaint);
      canvas.drawRect(rect, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant LayoutThumbnailPainter oldDelegate) {
    return oldDelegate.layout != layout;
  }
}

/// Custom painter for master slide canvas
class MasterSlideCanvasPainter extends CustomPainter {
  final MasterLayout layout;
  final bool isEditMode;

  MasterSlideCanvasPainter({required this.layout, this.isEditMode = true});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background
    final bgColor = layout.background['color'] ?? '#FFFFFF';
    final bgPaint = Paint()..color = _hexToColor(bgColor.toString());
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Draw placeholders
    for (final placeholder in layout.placeholders) {
      _drawPlaceholder(canvas, placeholder);
    }
  }

  void _drawPlaceholder(Canvas canvas, Component placeholder) {
    final rect = Rect.fromLTWH(
      placeholder.x,
      placeholder.y,
      placeholder.width,
      placeholder.height,
    );

    // Background fill
    final fillPaint = Paint()
      ..color = Colors.blue.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // Border
    final borderPaint = Paint()
      ..color = Colors.blue.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeMiterLimit = 4;

    if (isEditMode) {
      borderPaint.strokeWidth = 2;
    }

    canvas.drawRect(rect, fillPaint);
    canvas.drawRect(rect, borderPaint);

    // Draw placeholder icon and text
    if (placeholder.text != null) {
      final textSpan = TextSpan(
        text: placeholder.text!.content,
        style: TextStyle(
          color: Colors.blueGrey.withOpacity(0.7),
          fontSize: placeholder.text!.style?.fontSize ?? 14,
          fontStyle: FontStyle.italic,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout(maxWidth: rect.width - 20);
      textPainter.paint(
        canvas,
        Offset(
          rect.left + (rect.width - textPainter.width) / 2,
          rect.top + (rect.height - textPainter.height) / 2,
        ),
      );
    }

    // Draw placeholder type icon
    _drawPlaceholderIcon(canvas, placeholder, rect);
  }

  void _drawPlaceholderIcon(Canvas canvas, Component placeholder, Rect rect) {
    IconData? icon;

    switch (placeholder.placeholderType) {
      case PlaceholderType.title:
        icon = Icons.title;
        break;
      case PlaceholderType.subtitle:
        icon = Icons.short_text;
        break;
      case PlaceholderType.content:
        icon = Icons.article;
        break;
      case PlaceholderType.picture:
        icon = Icons.image;
        break;
      case PlaceholderType.chart:
        icon = Icons.insert_chart;
        break;
      case PlaceholderType.table:
        icon = Icons.table_chart;
        break;
      case PlaceholderType.smartArt:
        icon = Icons.account_tree;
        break;
      case PlaceholderType.video:
        icon = Icons.videocam;
        break;
      case PlaceholderType.media:
        icon = Icons.media_output;
        break;
      case PlaceholderType.date:
        icon = Icons.calendar_today;
        break;
      case PlaceholderType.footer:
        icon = Icons.notes;
        break;
      case PlaceholderType.slideNumber:
        icon = Icons.looks_one;
        break;
      case null:
        icon = Icons.widgets;
        break;
    }

    if (icon != null) {
      final iconPainter = IconPainter(
        icon: icon,
        color: Colors.blue.withOpacity(0.5),
        size: 24,
      );
      iconPainter.paint(canvas, Offset(rect.right - 30, rect.top + 10));
    }
  }

  @override
  bool shouldRepaint(covariant MasterSlideCanvasPainter oldDelegate) {
    return oldDelegate.layout != layout || oldDelegate.isEditMode != isEditMode;
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }
}

/// Simple icon painter helper
class IconPainter extends CustomPainter {
  final IconData icon;
  final Color color;
  final double size;

  IconPainter({required this.icon, required this.color, required this.size});

  @override
  void paint(Canvas canvas, Offset offset) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          fontSize: size,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant IconPainter oldDelegate) {
    return oldDelegate.icon != icon ||
        oldDelegate.color != color ||
        oldDelegate.size != size;
  }
}
