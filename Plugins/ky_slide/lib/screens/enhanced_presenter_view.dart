import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../models/component.dart';
import '../models/enums.dart';
import '../models/presentation_component.dart';
import '../models/slide_transition_type.dart';
import '../states/component_provider.dart';
import '../states/presentation_provider.dart';
import '../widgets/animated_component_wrapper.dart';
import '../widgets/particle_background.dart';
import '../widgets/simple_chart_widget.dart';
import '../widgets/triangle_painter.dart';

/// Enhanced Presenter View with dual-screen support, showing:
/// - Current slide (large)
/// - Next slide preview (thumbnail)
/// - Speaker notes
/// - Timer/clock
/// - Navigation controls
/// - Slide thumbnails for quick navigation
class EnhancedPresenterView extends ConsumerStatefulWidget {
  const EnhancedPresenterView({super.key});

  @override
  ConsumerState<EnhancedPresenterView> createState() => _EnhancedPresenterViewState();
}

class _EnhancedPresenterViewState extends ConsumerState<EnhancedPresenterView> {
  Timer? _autoPlayTimer;
  Timer? _clockTimer;
  DateTime _presentationStartTime = DateTime.now();
  Duration _elapsedTime = Duration.zero;
  int _selectedThumbnailIndex = 0;
  bool _isFullscreen = true;
  final ScrollController _thumbnailScrollController = ScrollController();
  final ScrollController _notesScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _setupAutoPlay();
    _setupClock();
    _selectedThumbnailIndex = ref.read(presentationProvider).currentSlideIndex;
    
    // Request fullscreen on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _enterFullscreen();
    });
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _clockTimer?.cancel();
    _thumbnailScrollController.dispose();
    _notesScrollController.dispose();
    _exitFullscreen();
    super.dispose();
  }

  void _setupAutoPlay() {
    final autoPlay = ref.read(autoPlayProvider);
    if (autoPlay) {
      final interval = ref.read(autoPlayIntervalProvider);
      _autoPlayTimer = Timer.periodic(Duration(seconds: interval), (timer) {
        final presentation = ref.read(presentationProvider);
        if (presentation.currentSlideIndex < presentation.slides.length - 1) {
          ref.read(presentationProvider.notifier).nextSlide();
        } else {
          timer.cancel();
        }
      });
    }
  }

  void _setupClock() {
    _presentationStartTime = DateTime.now();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedTime = DateTime.now().difference(_presentationStartTime);
      });
    });
  }

  Future<void> _enterFullscreen() async {
    if (await windowManager.isPreventClose()) {
      await windowManager.setFullScreen(true);
    }
  }

  Future<void> _exitFullscreen() async {
    await windowManager.setFullScreen(false);
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatClock() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final presentation = ref.watch(presentationProvider);
    final currentSlide = presentation.slides[presentation.currentSlideIndex];
    final nextSlideIndex = presentation.currentSlideIndex + 1;
    final hasNotes = currentSlide.notes != null && currentSlide.notes!.trim().isNotEmpty;
    final autoPlay = ref.watch(autoPlayProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
                event.logicalKey == LogicalKeyboardKey.space ||
                event.logicalKey == LogicalKeyboardKey.pageDown) {
              ref.read(presentationProvider.notifier).nextSlide();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
                event.logicalKey == LogicalKeyboardKey.pageUp) {
              ref.read(presentationProvider.notifier).previousSlide();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.escape) {
              _exitPresenterView();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.keyB) {
              // Toggle black screen
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.keyW) {
              // Toggle white screen
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Row(
          children: [
            // Left side - Current slide (70% width)
            Expanded(
              flex: 7,
              child: Column(
                children: [
                  // Top bar with timer and controls
                  _buildTopBar(presentation, autoPlay),
                  
                  // Main content area
                  Expanded(
                    child: Row(
                      children: [
                        // Current slide (85% of left side)
                        Expanded(
                          flex: 17,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: _buildCurrentSlide(currentSlide, presentation),
                          ),
                        ),
                        
                        // Right sidebar (15% of left side)
                        Expanded(
                          flex: 3,
                          child: _buildRightSidebar(
                            presentation,
                            nextSlideIndex,
                            hasNotes,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Right side - Speaker notes and thumbnails (30% width)
            Expanded(
              flex: 4,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF252525),
                  border: Border(
                    left: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    // Next slide preview
                    _buildNextSlidePreview(presentation, nextSlideIndex),
                    
                    // Divider
                    Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    
                    // Speaker notes
                    if (hasNotes || true) // Always show notes panel
                      Expanded(
                        flex: 3,
                        child: _buildSpeakerNotesPanel(currentSlide),
                      ),
                    
                    // Divider
                    Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    
                    // Slide thumbnails
                    Expanded(
                      flex: 2,
                      child: _buildThumbnailsGrid(presentation),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(PresentationState presentation, bool autoPlay) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF2d2d2d),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            // Timer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _formatDuration(_elapsedTime),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Clock
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, color: Colors.white70, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    _formatClock(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            
            const Spacer(),
            
            // Slide counter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    presentation.theme.primaryColor.withValues(alpha: 0.9),
                    presentation.theme.secondaryColor.withValues(alpha: 0.9),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Slide ${presentation.currentSlideIndex + 1} / ${presentation.slides.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Auto-play indicator
            if (autoPlay)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.play_circle, color: Colors.green, size: 20),
                    SizedBox(width: 4),
                    Text(
                      'Auto-play',
                      style: TextStyle(color: Colors.green, fontSize: 12),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(width: 12),
            
            // Exit button
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white70, size: 28),
              onPressed: _exitPresenterView,
              tooltip: 'Exit Presenter View (ESC)',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentSlide(PresentationSlide slide, PresentationState presentation) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            decoration: BoxDecoration(
              color: slide.backgroundColor ?? presentation.theme.backgroundColor,
              image: slide.backgroundImage != null
                  ? DecorationImage(
                      image: MemoryImage(slide.backgroundImage!),
                      fit: BoxFit.cover,
                    )
                  : null,
              gradient: slide.backgroundGradient != null
                  ? LinearGradient(
                      colors: slide.backgroundGradient!.colors,
                      begin: slide.backgroundGradient!.begin,
                      end: slide.backgroundGradient!.end,
                    )
                  : null,
            ),
            child: Stack(
              children: [
                if (slide.backgroundParticles != null)
                  ParticleBackground(effect: slide.backgroundParticles!),
                ...slide.components
                    .where((component) => component.isVisible)
                    .map((c) => _buildComponent(c))
                    .toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComponent(PresentationComponent component) {
    return Positioned(
      left: component.position.dx,
      top: component.position.dy,
      child: Transform.rotate(
        angle: component.rotation * math.pi / 180,
        child: Opacity(
          opacity: component.opacity,
          child: SizedBox(
            width: component.size.width,
            height: component.size.height,
            child: _buildComponentContent(component),
          ),
        ),
      ),
    );
  }

  Widget _buildComponentContent(PresentationComponent component) {
    switch (component.type) {
      case ComponentType.richText:
        return Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: component.backgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            component.richText?.text ?? '',
            style: component.richText?.style,
            textAlign: component.richText?.alignment ?? TextAlign.left,
          ),
        );
      case ComponentType.image:
        return component.imageData != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(component.imageData!, fit: BoxFit.cover),
              )
            : const Icon(Icons.image);
      case ComponentType.shape:
        return Container(
          decoration: BoxDecoration(
            color: component.backgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
        );
      case ComponentType.circle:
        return Container(
          decoration: BoxDecoration(
            color: component.backgroundColor,
            shape: BoxShape.circle,
          ),
        );
      case ComponentType.triangle:
        return CustomPaint(
          painter: TrianglePainter(component.backgroundColor ?? Colors.blue),
        );
      case ComponentType.chart:
        return component.chartData != null
            ? Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: component.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SimpleChartWidget(data: component.chartData!),
              )
            : const Icon(Icons.auto_graph);
      default:
        return Container(
          color: component.backgroundColor ?? Colors.grey,
        );
    }
  }

  Widget _buildRightSidebar(
    PresentationState presentation,
    int nextSlideIndex,
    bool hasNotes,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        border: Border(
          left: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Quick stats
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Presentation Stats',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildStatItem(
                    Icons.slideshow,
                    'Total Slides',
                    '${presentation.slides.length}',
                  ),
                  const SizedBox(height: 8),
                  _buildStatItem(
                    Icons.visibility,
                    'Current',
                    '${presentation.currentSlideIndex + 1}',
                  ),
                  const SizedBox(height: 8),
                  _buildStatItem(
                    Icons.layers,
                    'Remaining',
                    '${presentation.slides.length - presentation.currentSlideIndex - 1}',
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 16),
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildQuickAction(
                    Icons.blackboard_outlined,
                    'Black Screen',
                    () {},
                  ),
                  const SizedBox(height: 6),
                  _buildQuickAction(
                    Icons.light_mode,
                    'White Screen',
                    () {},
                  ),
                  const SizedBox(height: 6),
                  _buildQuickAction(
                    Icons.restart_alt,
                    'Restart',
                    () {
                      ref.read(presentationProvider.notifier).goToSlide(0);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextSlidePreview(PresentationState presentation, int nextSlideIndex) {
    final hasNext = nextSlideIndex < presentation.slides.length;
    final nextSlide = hasNext ? presentation.slides[nextSlideIndex] : null;

    return Container(
      height: 200,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.next_plan, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text(
                hasNext ? 'Next Slide' : 'End of Presentation',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (hasNext)
                Text(
                  '${nextSlideIndex + 1}/${presentation.slides.length}',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: hasNext
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Container(
                          color: nextSlide!.backgroundColor ?? 
                              presentation.theme.backgroundColor,
                          child: Center(
                            child: nextSlide.title != null && 
                                   nextSlide.title!.trim().isNotEmpty
                                ? Text(
                                    nextSlide.title!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  )
                                : const Text(
                                    'Blank Slide',
                                    style: TextStyle(
                                      color: Colors.white38,
                                      fontSize: 12,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: Colors.green.withValues(alpha: 0.7),
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Presentation Complete',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeakerNotesPanel(PresentationSlide slide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.speaker_notes, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              const Text(
                'Speaker Notes',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                slide.notes != null && slide.notes!.trim().isNotEmpty
                    ? '${slide.notes!.split(' ').length} words'
                    : 'No notes',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: _notesScrollController,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Text(
                slide.notes?.trim().isNotEmpty == true
                    ? slide.notes!
                    : 'No speaker notes for this slide.\n\nClick on the slide in the editor to add notes.',
                style: TextStyle(
                  color: slide.notes?.trim().isNotEmpty == true
                      ? Colors.white
                      : Colors.white38,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThumbnailsGrid(PresentationState presentation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.view_carousel, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              const Text(
                'All Slides',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${presentation.slides.length} slides',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _thumbnailScrollController,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: presentation.slides.length,
            itemBuilder: (context, index) {
              final slide = presentation.slides[index];
              final isSelected = index == presentation.currentSlideIndex;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () {
                    ref.read(presentationProvider.notifier).goToSlide(index);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF6366F1).withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF6366F1)
                            : Colors.white.withValues(alpha: 0.1),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Thumbnail preview
                        Container(
                          width: 80,
                          height: 45,
                          margin: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: slide.backgroundColor ?? 
                                presentation.theme.backgroundColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: slide.title != null && 
                                   slide.title!.trim().isNotEmpty
                                ? Text(
                                    slide.title!.substring(0, 
                                        math.min(15, slide.title!.length)),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Slide number and title
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Slide ${index + 1}',
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (slide.title != null && 
                                  slide.title!.trim().isNotEmpty)
                                Text(
                                  slide.title!,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white54,
                                    fontSize: 9,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Icon(
                              Icons.play_circle,
                              color: const Color(0xFF6366F1),
                              size: 20,
                            ),
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
    );
  }

  void _exitPresenterView() {
    ref.read(presenterModeProvider.notifier).state = false;
    _autoPlayTimer?.cancel();
    _clockTimer?.cancel();
    _exitFullscreen();
  }
}
