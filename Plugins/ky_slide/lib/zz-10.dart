

// ==================== SIMPLE CHART WIDGET ====================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';

class SimpleChartWidget extends StatelessWidget {
  final ChartData data;

  const SimpleChartWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    switch (data.type) {
      case ChartType.bar:
        return CustomPaint(
          painter: BarChartPainter(data),
        );
      case ChartType.line:
        return CustomPaint(
          painter: LineChartPainter(data),
        );
      case ChartType.pie:
        return CustomPaint(
          painter: PieChartPainter(data),
        );
      default:
        return const Center(child: Icon(Icons.show_chart));
    }
  }
}

class BarChartPainter extends CustomPainter {
  final ChartData data;

  BarChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final maxValue = data.values.reduce(math.max);
    final barWidth = size.width / (data.values.length * 2);
    final spacing = barWidth * 0.5;

    for (int i = 0; i < data.values.length; i++) {
      final barHeight = (data.values[i] / maxValue) * (size.height - 40);
      final x = i * (barWidth + spacing) + spacing;
      final y = size.height - barHeight - 20;

      final paint = Paint()..color = data.colors[i % data.colors.length];
      canvas.drawRect(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        paint,
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: data.labels[i],
          style: const TextStyle(color: Colors.black87, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x + barWidth / 2 - textPainter.width / 2, size.height - 15),
      );
    }
  }

  @override
  bool shouldRepaint(BarChartPainter oldDelegate) => false;
}

class LineChartPainter extends CustomPainter {
  final ChartData data;

  LineChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final maxValue = data.values.reduce(math.max);
    final path = Path();
    final paint = Paint()
      ..color = data.colors.first
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < data.values.length; i++) {
      final x = (i / (data.values.length - 1)) * size.width;
      final y = size.height - (data.values[i] / maxValue) * (size.height - 40) - 20;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      canvas.drawCircle(Offset(x, y), 4, Paint()..color = data.colors.first);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(LineChartPainter oldDelegate) => false;
}

class PieChartPainter extends CustomPainter {
  final ChartData data;

  PieChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 20;
    final total = data.values.reduce((a, b) => a + b);

    double startAngle = -math.pi / 2;

    for (int i = 0; i < data.values.length; i++) {
      final sweepAngle = (data.values[i] / total) * 2 * math.pi;
      final paint = Paint()
        ..color = data.colors[i % data.colors.length]
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(PieChartPainter oldDelegate) => false;
}

class TrianglePainter extends CustomPainter {
  final Color color;

  TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(TrianglePainter oldDelegate) => oldDelegate.color != color;
}

// ==================== SLIDE PANEL ====================

class SlidePanel extends ConsumerWidget {
  const SlidePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presentation = ref.watch(presentationProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => ref.read(presentationProvider.notifier).addSlide(),
              icon: const Icon(Icons.add),
              label: const Text('New Slide'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ReorderableListView.builder(
            itemCount: presentation.slides.length,
            onReorder: (oldIndex, newIndex) {
              ref.read(presentationProvider.notifier).reorderSlides(oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              final slide = presentation.slides[index];
              final isSelected = index == presentation.currentSlideIndex;
              return Card(
                key: ValueKey(slide.id),
                color: isSelected 
                    ? Theme.of(context).colorScheme.primaryContainer 
                    : null,
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                elevation: isSelected ? 4 : 1,
                child: InkWell(
                  onTap: () => ref
                      .read(presentationProvider.notifier)
                      .setCurrentSlide(index),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? Theme.of(context).colorScheme.primary 
                                    : Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          Text(value, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildPropertySlider(
    BuildContext context,
    WidgetRef ref,
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged, {
    String suffix = '',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
            Text('${value.toInt()}$suffix', style: const TextStyle(fontSize: 13)),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
          onChangeEnd: (_) {
            ref.read(historyProvider.notifier).addState(ref.read(presentationProvider));
          },
        ),
      ],
    );
  }

  Future<void> _showColorPicker(
    BuildContext context,
    WidgetRef ref,
    PresentationComponent component,
    bool isTextColor,
  ) async {
    Color pickerColor = isTextColor 
      ? (component.richText?.style.color ?? Colors.black)
      : (component.backgroundColor ?? Colors.blue);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isTextColor ? 'Pick Text Color' : 'Pick Background Color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            color: pickerColor,
            onColorChanged: (color) => pickerColor = color,
            pickersEnabled: const {
              ColorPickerType.wheel: true,
              ColorPickerType.accent: false,
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (isTextColor) {
                final updatedRichText = component.richText?.copyWith(
                  style: component.richText!.style.copyWith(color: pickerColor),
                );
                ref.read(presentationProvider.notifier).updateComponent(
                  component.id,
                  component.copyWith(richText: updatedRichText),
                );
              } else {
                ref.read(presentationProvider.notifier).updateComponent(
                  component.id,
                  component.copyWith(backgroundColor: pickerColor),
                );
              }
              ref.read(historyProvider.notifier).addState(ref.read(presentationProvider));
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSlideColorPicker(BuildContext context, WidgetRef ref) async {
    final presentation = ref.read(presentationProvider);
    final currentSlide = presentation.slides[presentation.currentSlideIndex];
    Color pickerColor = currentSlide.backgroundColor ?? presentation.theme.backgroundColor;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick Slide Background'),
        content: SingleChildScrollView(
          child: ColorPicker(
            color: pickerColor,
            onColorChanged: (color) => pickerColor = color,
            pickersEnabled: const {
              ColorPickerType.wheel: true,
              ColorPickerType.accent: false,
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(presentationProvider.notifier).setSlideBackground(pickerColor);
              ref.read(historyProvider.notifier).addState(ref.read(presentationProvider));
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _showFontSizePicker(
    BuildContext context,
    WidgetRef ref,
    PresentationComponent component,
  ) async {
    double fontSize = component.richText?.style.fontSize ?? 16;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Font Size'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Size: ${fontSize.toInt()}', style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 16),
              Slider(
                value: fontSize,
                min: 8,
                max: 96,
                divisions: 88,
                label: fontSize.toInt().toString(),
                onChanged: (value) => setState(() => fontSize = value),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final updatedRichText = component.richText?.copyWith(
                style: component.richText!.style.copyWith(fontSize: fontSize),
              );
              ref.read(presentationProvider.notifier).updateComponent(
                component.id,
                component.copyWith(richText: updatedRichText),
              );
              ref.read(historyProvider.notifier).addState(ref.read(presentationProvider));
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _addSlideBackgroundImage(WidgetRef ref, BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        ref.read(presentationProvider.notifier).setSlideBackgroundImage(result.files.single.bytes);
        ref.read(historyProvider.notifier).addState(ref.read(presentationProvider));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding background: $e')),
      );
    }
  }
}

// ==================== PRESENTER VIEW ====================

class PresenterView extends ConsumerStatefulWidget {
  const PresenterView({super.key});

  @override
  ConsumerState<PresenterView> createState() => _PresenterViewState();
}

class _PresenterViewState extends ConsumerState<PresenterView> {
  Timer? _autoPlayTimer;

  @override
  void initState() {
    super.initState();
    _setupAutoPlay();
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
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

  @override
  Widget build(BuildContext context) {
    final presentation = ref.watch(presentationProvider);
    final currentSlide = presentation.slides[presentation.currentSlideIndex];
    final autoPlay = ref.watch(autoPlayProvider);

    return Scaffold(
      backgroundColor: Colors.black,
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
            } else if (event.logicalKey == LogicalKeyboardKey.escape ||
                       event.logicalKey == LogicalKeyboardKey.f5) {
              ref.read(presenterModeProvider.notifier).state = false;
              _autoPlayTimer?.cancel();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Stack(
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (child, animation) {
                    return _buildTransition(currentSlide.transition, child, animation);
                  },
                  child: Container(
                    key: ValueKey(currentSlide.id),
                    decoration: BoxDecoration(
                      color: currentSlide.backgroundColor ?? presentation.theme.backgroundColor,
                      image: currentSlide.backgroundImage != null
                          ? DecorationImage(
                              image: MemoryImage(currentSlide.backgroundImage!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: Stack(
                      children: currentSlide.components
                          .map((c) => _buildAnimatedComponent(c))
                          .toList()
                        ..sort((a, b) {
                          final aComp = currentSlide.components
                              .firstWhere((c) => (a.key as ValueKey).value == c.id);
                          final bComp = currentSlide.components
                              .firstWhere((c) => (b.key as ValueKey).value == c.id);
                          return aComp.zIndex.compareTo(bComp.zIndex);
                        }),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (autoPlay) ...[
                        const Icon(Icons.play_arrow, color: Colors.green, size: 16),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        'Slide ${presentation.currentSlideIndex + 1} / ${presentation.slides.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 30,
              right: 30,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      autoPlay ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () {
                      final newAutoPlay = !autoPlay;
                      ref.read(autoPlayProvider.notifier).state = newAutoPlay;
                      if (newAutoPlay) {
                        _setupAutoPlay();
                      } else {
                        _autoPlayTimer?.cancel();
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 32),
                    onPressed: () {
                      ref.read(presenterModeProvider.notifier).state = false;
                      _autoPlayTimer?.cancel();
                    },
                  ),
                ],
              ),
            ),
            Positioned(
              top: 30,
              left: 30,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Press ESC to exit',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const Text(
                      'Arrow keys to navigate',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const Text(
                      'Space for next slide',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
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

  Widget _buildTransition(SlideTransition transition, Widget child, Animation<double> animation) {
    switch (transition) {
      case SlideTransition.fade:
        return FadeTransition(opacity: animation, child: child);
      case SlideTransition.slide:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      case SlideTransition.zoom:
        return ScaleTransition(scale: animation, child: child);
      case SlideTransition.flip:
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final angle = animation.value * math.pi;
            return Transform(
              transform: Matrix4.rotationY(angle),
              alignment: Alignment.center,
              child: child,
            );
          },
          child: child,
        );
      default:
        return child;
    }
  }

  Widget _buildAnimatedComponent(PresentationComponent component) {
    Widget content = Positioned(
      left: component.position.dx,
      top: component.position.dy,
      child: Transform.rotate(
        angle: component.rotation * math.pi / 180,
        child: Opacity(
          opacity: component.opacity,
          child: Container(
            width: component.size.width,
            height: component.size.height,
            decoration: BoxDecoration(
              color: component.backgroundColor,
            ),
            child: _buildComponentContent(component),
          ),
        ),
      ),
    );

    return AnimatedComponentWrapper(
      key: ValueKey(component.id),
      animation: component.animation,
      delay: component.animationDelay,
      duration: component.animationDuration,
      child: content,
    );
  }

  Widget _buildComponentContent(PresentationComponent component) {
    switch (component.type) {
      case ComponentType.richText:
        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(
            component.richText?.text ?? '',
            style: component.richText?.style,
            textAlign: component.richText?.alignment ?? TextAlign.left,
          ),
        );
      case ComponentType.image:
        return component.imageData != null
            ? Image.memory(component.imageData!, fit: BoxFit.contain)
            : const Icon(Icons.image);
      case ComponentType.shape:
        return Container(color: component.backgroundColor);
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
            ? SimpleChartWidget(data: component.chartData!)
            : const Center(child: Icon(Icons.auto_graph));
      case ComponentType.video:
        return Container(
          color: Colors.black,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.play_circle_outline, size: 64, color: Colors.white),
                const SizedBox(height: 8),
                Text(
                  component.videoUrl ?? 'Video',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        );
      case ComponentType.diagram:
        return const Center(
          child: Icon(Icons.account_tree, size: 48, color: Colors.grey),
        );
    }
  }
}

class AnimatedComponentWrapper extends StatefulWidget {
  final AnimationType animation;
  final Widget child;
  final double delay;
  final double duration;

  const AnimatedComponentWrapper({
    super.key,
    required this.animation,
    required this.child,
    this.delay = 0,
    this.duration = 0.6,
  });

  @override
  State<AnimatedComponentWrapper> createState() => _AnimatedComponentWrapperState();
}

class _AnimatedComponentWrapperState extends State<AnimatedComponentWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: (widget.duration * 1000).toInt()),
      vsync: this,
    );

    _setupAnimation();

    if (widget.delay > 0) {
      Future.delayed(Duration(milliseconds: (widget.delay * 1000).toInt()), () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.forward();
    }
  }

  void _setupAnimation() {
    switch (widget.animation) {
      case AnimationType.fadeIn:
        _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
        break;
      case AnimationType.zoom:
        _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
        );
        break;
      case AnimationType.bounce:
        _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _controller, curve: Curves.bounceOut),
        );
        break;
      case AnimationType.slideIn:
        _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOut),
        );
        break;
      default:
        _animation = Tween<double>(begin: 1.0, end: 1.0).animate(_controller);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.animation == AnimationType.none) {
      return widget.child;
    }

    if (widget.animation == AnimationType.fadeIn) {
      return FadeTransition(
        opacity: _animation,
        child: widget.child,
      );
    }

    if (widget.animation == AnimationType.slideIn) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -1),
          end: Offset.zero,
        ).animate(_animation),
        child: widget.child,
      );
    }

    if (widget.animation == AnimationType.slideRight) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-1, 0),
          end: Offset.zero,
        ).animate(_animation),
        child: widget.child,
      );
    }

    if (widget.animation == AnimationType.slideLeft) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(_animation),
        child: widget.child,
      );
    }

    if (widget.animation == AnimationType.rotate) {
      return RotationTransition(
        turns: _animation,
        child: widget.child,
      );
    }

    return ScaleTransition(
      scale: _animation,
      child: widget.child,
    );
  }
}



// ==================== PROPERTIES PANEL ====================

class PropertiesPanel extends ConsumerWidget {
  const PropertiesPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(selectedComponentProvider);
    final presentation = ref.watch(presentationProvider);

    if (selectedId == null) {
      return _buildSlideProperties(context, ref, presentation);
    }

    final component = presentation
        .slides[presentation.currentSlideIndex].components
        .firstWhere((c) => c.id == selectedId);

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text(
                  'Properties',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),

            _buildPropertyCard(
              context,
              'Transform',
              [
                _buildPropertyRow('Type', component.type.name.toUpperCase()),
                _buildPropertySlider(
                  context,
                  ref,
                  'X Position',
                  component.position.dx,
                  0,
                  presentation.slideSize.width,
                  (value) {
                    ref.read(presentationProvider.notifier).updateComponent(
                      component.id,
                      component.copyWith(
                        position: Offset(value, component.position.dy),
                      ),
                    );
                  },
                ),
                _buildPropertySlider(
                  context,
                  ref,
                  'Y Position',
                  component.position.dy,
                  0,
                  presentation.slideSize.height,
                  (value) {
                    ref.read(presentationProvider.notifier).updateComponent(
                      component.id,
                      component.copyWith(
                        position: Offset(component.position.dx, value),
                      ),
                    );
                  },
                ),
                _buildPropertySlider(
                  context,
                  ref,
                  'Rotation',
                  component.rotation,
                  -180,
                  180,
                  (value) {
                    ref.read(presentationProvider.notifier).updateComponent(
                      component.id,
                      component.copyWith(rotation: value),
                    );
                  },
                  suffix: '°',
                ),
              ],
            ),

            const SizedBox(height: 16),

            if (component.type == ComponentType.richText) ...[
              _buildPropertyCard(
                context,
                'Text Style',
                [
                  ElevatedButton.icon(
                    onPressed: () => _showFontSizePicker(context, ref, component),
                    icon: const Icon(Icons.format_size, size: 18),
                    label: Text('Font Size: ${component.richText?.style.fontSize?.toInt() ?? 16}'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 40),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showColorPicker(context, ref, component, true),
                    icon: Icon(
                      Icons.color_lens,
                      size: 18,
                      color: component.richText?.style.color ?? Colors.black,
                    ),
                    label: const Text('Text Color'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 40),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<TextAlign>(
                    segments: const [
                      ButtonSegment(
                        value: TextAlign.left,
                        icon: Icon(Icons.format_align_left, size: 18),
                      ),
                      ButtonSegment(
                        value: TextAlign.center,
                        icon: Icon(Icons.format_align_center, size: 18),
                      ),
                      ButtonSegment(
                        value: TextAlign.right,
                        icon: Icon(Icons.format_align_right, size: 18),
                      ),
                    ],
                    selected: {component.richText?.alignment ?? TextAlign.left},
                    onSelectionChanged: (Set<TextAlign> selected) {
                      final updatedRichText = component.richText?.copyWith(
                        alignment: selected.first,
                      );
                      ref.read(presentationProvider.notifier).updateComponent(
                        component.id,
                        component.copyWith(richText: updatedRichText),
                      );
                      ref.read(historyProvider.notifier).addState(ref.read(presentationProvider));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            if (component.type != ComponentType.image) ...[
              _buildPropertyCard(
                context,
                'Appearance',
                [
                  ElevatedButton.icon(
                    onPressed: () => _showColorPicker(context, ref, component, false),
                    icon: Icon(
                      Icons.palette,
                      size: 18,
                      color: component.backgroundColor ?? Colors.transparent,
                    ),
                    label: const Text('Background Color'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 40),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            _buildPropertyCard(
              context,
              'Animation',
              [
                DropdownButtonFormField<AnimationType>(
                  value: component.animation,
                  decoration: const InputDecoration(
                    labelText: 'Animation Type',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: AnimationType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(presentationProvider.notifier).updateComponent(
                        component.id,
                        component.copyWith(animation: value),
                      );
                      ref.read(historyProvider.notifier).addState(ref.read(presentationProvider));
                    }
                  },
                ),
                const SizedBox(height: 8),
                _buildPropertySlider(
                  context,
                  ref,
                  'Opacity',
                  component.opacity,
                  0,
                  1,
                  (value) {
                    ref.read(presentationProvider.notifier).updateComponent(
                      component.id,
                      component.copyWith(opacity: value),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlideProperties(BuildContext context, WidgetRef ref, Presentation presentation) {
    final currentSlide = presentation.slides[presentation.currentSlideIndex];
    final showGrid = ref.watch(showGridProvider);
    final snapToGrid = ref.watch(snapToGridProvider);

    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.slideshow, size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              const Text(
                'Slide Properties',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 16),

          TextField(
            decoration: const InputDecoration(
              labelText: 'Slide Title',
              border: OutlineInputBorder(),
            ),
            controller: TextEditingController(text: currentSlide.title),
            onSubmitted: (value) {
              ref.read(presentationProvider.notifier).setSlideTitle(value);
              ref.read(historyProvider.notifier).addState(ref.read(presentationProvider));
            },
          ),

          const SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed: () => _showSlideColorPicker(context, ref),
            icon: Icon(
              Icons.format_paint,
              color: currentSlide.backgroundColor ?? presentation.theme.backgroundColor,
            ),
            label: const Text('Background Color'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 45),
            ),
          ),

          const SizedBox(height: 8),

          ElevatedButton.icon(
            onPressed: () => _addSlideBackgroundImage(ref, context),
            icon: const Icon(Icons.image),
            label: const Text('Background Image'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 45),
            ),
          ),

          const SizedBox(height: 16),

          DropdownButtonFormField<SlideTransition>(
            value: currentSlide.transition,
            decoration: const InputDecoration(
              labelText: 'Slide Transition',
              border: OutlineInputBorder(),
            ),
            items: SlideTransition.values.map((trans) {
              return DropdownMenuItem(
                value: trans,
                child: Text(trans.name),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                ref.read(presentationProvider.notifier).setSlideTransition(value);
                ref.read(historyProvider.notifier).addState(ref.read(presentationProvider));
              }
            },
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          const Text('View Options', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          SwitchListTile(
            title: const Text('Show Grid'),
            value: showGrid,
            onChanged: (value) {
              ref.read(showGridProvider.notifier).state = value;
            },
          ),

          SwitchListTile(
            title: const Text('Snap to Grid'),
            value: snapToGrid,
            onChanged: (value) {
              ref.read(snapToGridProvider.notifier).state = value;
            },
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          Text(
            'Components: ${currentSlide.components.length}',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            'Slide ${presentation.currentSlideIndex + 1} of ${presentation.slides.length}',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyCard(BuildContext context, String title, List<Widget> children) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceVariant,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.
        
        
// pubspec.yaml dependencies:
// flutter_riverpod: ^2.4.9
// uuid: ^4.2.2
// file_picker: ^6.1.1
// path_provider: ^2.1.1
// archive: ^3.4.9
// xml: ^6.4.2
// image: ^4.1.3
// flex_color_picker: ^3.3.0
// google_fonts: ^6.1.0
// flutter_quill: ^9.3.0
// fl_chart: ^0.66.0
// youtube_player_flutter: ^8.1.2

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';
import 'package:xml/xml.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:google_fonts/google_fonts.dart';

// ==================== MODELS ====================

enum ComponentType { richText, image, shape, circle, triangle, chart, video, diagram }
enum AnimationType { none, fadeIn, slideIn, slideRight, slideLeft, zoom, bounce, rotate, flip }
enum ToolMode { select, text, image, shape, chart }
enum ChartType { line, bar, pie, scatter }
enum SlideTransition { none, fade, slide, zoom, cube, flip }

class PresentationTheme {
  final String id;
  final String name;
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;
  final Color textColor;
  final TextStyle titleStyle;
  final TextStyle bodyStyle;
  final List<Color> colorPalette;

  PresentationTheme({
    required this.id,
    required this.name,
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
    required this.textColor,
    required this.titleStyle,
    required this.bodyStyle,
    required this.colorPalette,
  });

  static PresentationTheme get defaultTheme => PresentationTheme(
    id: 'default',
    name: 'Default',
    primaryColor: Colors.blue,
    secondaryColor: Colors.blueAccent,
    backgroundColor: Colors.white,
    textColor: Colors.black87,
    titleStyle: GoogleFonts.montserrat(fontSize: 32, fontWeight: FontWeight.bold),
    bodyStyle: GoogleFonts.roboto(fontSize: 18),
    colorPalette: [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red],
  );

  static PresentationTheme get modernDark => PresentationTheme(
    id: 'modern_dark',
    name: 'Modern Dark',
    primaryColor: const Color(0xFF00D9FF),
    secondaryColor: const Color(0xFF7B2CBF),
    backgroundColor: const Color(0xFF1A1A2E),
    textColor: Colors.white,
    titleStyle: GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
    bodyStyle: GoogleFonts.inter(fontSize: 18, color: Colors.white70),
    colorPalette: [
      const Color(0xFF00D9FF),
      const Color(0xFF7B2CBF),
      const Color(0xFFFF6B6B),
      const Color(0xFF4ECDC4),
      const Color(0xFFFFA07A),
    ],
  );

  static PresentationTheme get minimalist => PresentationTheme(
    id: 'minimalist',
    name: 'Minimalist',
    primaryColor: const Color(0xFF2D3142),
    secondaryColor: const Color(0xFF4F5D75),
    backgroundColor: const Color(0xFFFAFAFA),
    textColor: const Color(0xFF2D3142),
    titleStyle: GoogleFonts.libreBaskerville(fontSize: 34, fontWeight: FontWeight.w600),
    bodyStyle: GoogleFonts.openSans(fontSize: 16),
    colorPalette: [
      const Color(0xFF2D3142),
      const Color(0xFF4F5D75),
      const Color(0xFFBFC0C0),
      const Color(0xFFEF8354),
    ],
  );
}

class RichTextContent {
  final String text;
  final TextStyle style;
  final bool isBold;
  final bool isItalic;
  final bool isUnderline;
  final TextAlign alignment;

  RichTextContent({
    required this.text,
    required this.style,
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
    this.alignment = TextAlign.left,
  });

  RichTextContent copyWith({
    String? text,
    TextStyle? style,
    bool? isBold,
    bool? isItalic,
    bool? isUnderline,
    TextAlign? alignment,
  }) {
    return RichTextContent(
      text: text ?? this.text,
      style: style ?? this.style,
      isBold: isBold ?? this.isBold,
      isItalic: isItalic ?? this.isItalic,
      isUnderline: isUnderline ?? this.isUnderline,
      alignment: alignment ?? this.alignment,
    );
  }
}

class ChartData {
  final ChartType type;
  final List<double> values;
  final List<String> labels;
  final List<Color> colors;

  ChartData({
    required this.type,
    required this.values,
    required this.labels,
    required this.colors,
  });
}

class PresentationComponent {
  final String id;
  final ComponentType type;
  final Offset position;
  final Size size;
  final RichTextContent? richText;
  final Uint8List? imageData;
  final Color? backgroundColor;
  final double rotation;
  final int zIndex;
  final AnimationType animation;
  final double opacity;
  final BorderSide? border;
  final bool isEditing;
  final ChartData? chartData;
  final String? videoUrl;
  final double animationDelay;
  final double animationDuration;

  PresentationComponent({
    required this.id,
    required this.type,
    required this.position,
    required this.size,
    this.richText,
    this.imageData,
    this.backgroundColor,
    this.rotation = 0,
    this.zIndex = 0,
    this.animation = AnimationType.none,
    this.opacity = 1.0,
    this.border,
    this.isEditing = false,
    this.chartData,
    this.videoUrl,
    this.animationDelay = 0,
    this.animationDuration = 0.6,
  });

  PresentationComponent copyWith({
    Offset? position,
    Size? size,
    RichTextContent? richText,
    Uint8List? imageData,
    Color? backgroundColor,
    double? rotation,
    int? zIndex,
    AnimationType? animation,
    double? opacity,
    BorderSide? border,
    bool? isEditing,
    ChartData? chartData,
    String? videoUrl,
    double? animationDelay,
    double? animationDuration,
  }) {
    return PresentationComponent(
      id: id,
      type: type,
      position: position ?? this.position,
      size: size ?? this.size,
      richText: richText ?? this.richText,
      imageData: imageData ?? this.imageData,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      rotation: rotation ?? this.rotation,
      zIndex: zIndex ?? this.zIndex,
      animation: animation ?? this.animation,
      opacity: opacity ?? this.opacity,
      border: border ?? this.border,
      isEditing: isEditing ?? this.isEditing,
      chartData: chartData ?? this.chartData,
      videoUrl: videoUrl ?? this.videoUrl,
      animationDelay: animationDelay ?? this.animationDelay,
      animationDuration: animationDuration ?? this.animationDuration,
    );
  }
}

class Slide {
  final String id;
  final List<PresentationComponent> components;
  final Color? backgroundColor;
  final String? notes;
  final String? title;
  final SlideTransition transition;
  final Uint8List? backgroundImage;

  Slide({
    required this.id,
    required this.components,
    this.backgroundColor,
    this.notes,
    this.title,
    this.transition = SlideTransition.fade,
    this.backgroundImage,
  });

  Slide copyWith({
    List<PresentationComponent>? components,
    Color? backgroundColor,
    String? notes,
    String? title,
    SlideTransition? transition,
    Uint8List? backgroundImage,
  }) {
    return Slide(
      id: id,
      components: components ?? this.components,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      notes: notes ?? this.notes,
      title: title ?? this.title,
      transition: transition ?? this.transition,
      backgroundImage: backgroundImage ?? this.backgroundImage,
    );
  }
}

class Presentation {
  final String id;
  final String title;
  final List<Slide> slides;
  final int currentSlideIndex;
  final PresentationTheme theme;
  final Size slideSize;

  Presentation({
    required this.id,
    required this.title,
    required this.slides,
    this.currentSlideIndex = 0,
    PresentationTheme? theme,
    this.slideSize = const Size(1920, 1080),
  }) : theme = theme ?? PresentationTheme.defaultTheme;

  Presentation copyWith({
    String? title,
    List<Slide>? slides,
    int? currentSlideIndex,
    PresentationTheme? theme,
    Size? slideSize,
  }) {
    return Presentation(
      id: id,
      title: title ?? this.title,
      slides: slides ?? this.slides,
      currentSlideIndex: currentSlideIndex ?? this.currentSlideIndex,
      theme: theme ?? this.theme,
      slideSize: slideSize ?? this.slideSize,
    );
  }
}

// ==================== STATE PROVIDERS ====================

final presentationProvider = StateNotifierProvider<PresentationNotifier, Presentation>((ref) {
  return PresentationNotifier();
});

class PresentationNotifier extends StateNotifier<Presentation> {
  PresentationNotifier()
      : super(Presentation(
          id: const Uuid().v4(),
          title: 'New Presentation',
          slides: [
            Slide(
              id: const Uuid().v4(),
              components: [],
              title: 'Title Slide',
            )
          ],
        ));

  void addSlide() {
    final slideNum = state.slides.length + 1;
    state = state.copyWith(
      slides: [
        ...state.slides,
        Slide(
          id: const Uuid().v4(),
          components: [],
          title: 'Slide $slideNum',
          backgroundColor: state.theme.backgroundColor,
        ),
      ],
    );
  }

  void duplicateSlide(int index) {
    final slide = state.slides[index];
    final newComponents = slide.components.map((c) => 
      PresentationComponent(
        id: const Uuid().v4(),
        type: c.type,
        position: c.position,
        size: c.size,
        richText: c.richText,
        imageData: c.imageData,
        backgroundColor: c.backgroundColor,
        rotation: c.rotation,
        zIndex: c.zIndex,
        animation: c.animation,
        opacity: c.opacity,
        border: c.border,
        chartData: c.chartData,
        videoUrl: c.videoUrl,
        animationDelay: c.animationDelay,
        animationDuration: c.animationDuration,
      )
    ).toList();
    
    final newSlide = Slide(
      id: const Uuid().v4(),
      components: newComponents,
      backgroundColor: slide.backgroundColor,
      notes: slide.notes,
      title: '${slide.title} (Copy)',
      transition: slide.transition,
      backgroundImage: slide.backgroundImage,
    );
    
    final slides = List<Slide>.from(state.slides);
    slides.insert(index + 1, newSlide);
    state = state.copyWith(slides: slides);
  }

  void deleteSlide(int index) {
    if (state.slides.length <= 1) return;
    final slides = List<Slide>.from(state.slides);
    slides.removeAt(index);
    state = state.copyWith(
      slides: slides,
      currentSlideIndex: state.currentSlideIndex >= slides.length 
          ? slides.length - 1 
          : state.currentSlideIndex,
    );
  }

  void reorderSlides(int oldIndex, int newIndex) {
    final slides = List<Slide>.from(state.slides);
    if (newIndex > oldIndex) newIndex--;
    final slide = slides.removeAt(oldIndex);
    slides.insert(newIndex, slide);
    
    int newCurrentIndex = state.currentSlideIndex;
    if (oldIndex == state.currentSlideIndex) {
      newCurrentIndex = newIndex;
    } else if (oldIndex < state.currentSlideIndex && newIndex >= state.currentSlideIndex) {
      newCurrentIndex--;
    } else if (oldIndex > state.currentSlideIndex && newIndex <= state.currentSlideIndex) {
      newCurrentIndex++;
    }
    
    state = state.copyWith(slides: slides, currentSlideIndex: newCurrentIndex);
  }

  void setCurrentSlide(int index) {
    if (index >= 0 && index < state.slides.length) {
      state = state.copyWith(currentSlideIndex: index);
    }
  }

  void nextSlide() {
    if (state.currentSlideIndex < state.slides.length - 1) {
      state = state.copyWith(currentSlideIndex: state.currentSlideIndex + 1);
    }
  }

  void previousSlide() {
    if (state.currentSlideIndex > 0) {
      state = state.copyWith(currentSlideIndex: state.currentSlideIndex - 1);
    }
  }

  void addComponent(PresentationComponent component) {
    final slides = List<Slide>.from(state.slides);
    final currentSlide = slides[state.currentSlideIndex];
    final maxZ = currentSlide.components.isEmpty 
        ? 0 
        : currentSlide.components.map((c) => c.zIndex).reduce(math.max);
    final newComponent = component.copyWith(zIndex: maxZ + 1);
    slides[state.currentSlideIndex] = currentSlide.copyWith(
      components: [...currentSlide.components, newComponent],
    );
    state = state.copyWith(slides: slides);
  }

  void updateComponent(String componentId, PresentationComponent updated) {
    final slides = List<Slide>.from(state.slides);
    final currentSlide = slides[state.currentSlideIndex];
    final components = currentSlide.components
        .map((c) => c.id == componentId ? updated : c)
        .toList();
    slides[state.currentSlideIndex] = currentSlide.copyWith(components: components);
    state = state.copyWith(slides: slides);
  }

  void deleteComponent(String componentId) {
    final slides = List<Slide>.from(state.slides);
    final currentSlide = slides[state.currentSlideIndex];
    final components = currentSlide.components.where((c) => c.id != componentId).toList();
    slides[state.currentSlideIndex] = currentSlide.copyWith(components: components);
    state = state.copyWith(slides: slides);
  }

  void bringToFront(String componentId) {
    final slides = List<Slide>.from(state.slides);
    final currentSlide = slides[state.currentSlideIndex];
    final maxZ = currentSlide.components.map((c) => c.zIndex).reduce(math.max);
    final components = currentSlide.components.map((c) =>
      c.id == componentId ? c.copyWith(zIndex: maxZ + 1) : c
    ).toList();
    slides[state.currentSlideIndex] = currentSlide.copyWith(components: components);
    state = state.copyWith(slides: slides);
  }

  void sendToBack(String componentId) {
    final slides = List<Slide>.from(state.slides);
    final currentSlide = slides[state.currentSlideIndex];
    final minZ = currentSlide.components.map((c) => c.zIndex).reduce(math.min);
    final components = currentSlide.components.map((c) =>
      c.id == componentId ? c.copyWith(zIndex: minZ - 1) : c
    ).toList();
    slides[state.currentSlideIndex] = currentSlide.copyWith(components: components);
    state = state.copyWith(slides: slides);
  }

  void setTitle(String title) {
    state = state.copyWith(title: title);
  }

  void setSlideBackground(Color? color) {
    final slides = List<Slide>.from(state.slides);
    slides[state.currentSlideIndex] = slides[state.currentSlideIndex].copyWith(
      backgroundColor: color,
    );
    state = state.copyWith(slides: slides);
  }

  void setSlideBackgroundImage(Uint8List? imageData) {
    final slides = List<Slide>.from(state.slides);
    slides[state.currentSlideIndex] = slides[state.currentSlideIndex].copyWith(
      backgroundImage: imageData,
    );
    state = state.copyWith(slides: slides);
  }

  void setSlideTitle(String title) {
    final slides = List<Slide>.from(state.slides);
    slides[state.currentSlideIndex] = slides[state.currentSlideIndex].copyWith(
      title: title,
    );
    state = state.copyWith(slides: slides);
  }

  void setSlideTransition(SlideTransition transition) {
    final slides = List<Slide>.from(state.slides);
    slides[state.currentSlideIndex] = slides[state.currentSlideIndex].copyWith(
      transition: transition,
    );
    state = state.copyWith(slides: slides);
  }

  void applyTheme(PresentationTheme theme) {
    final slides = state.slides.map((slide) {
      return slide.copyWith(
        backgroundColor: slide.backgroundColor ?? theme.backgroundColor,
      );
    }).toList();
    state = state.copyWith(theme: theme, slides: slides);
  }

  void loadPresentation(Presentation presentation) {
    state = presentation;
  }
}

final selectedComponentProvider = StateProvider<String?>((ref) => null);
final presenterModeProvider = StateProvider<bool>((ref) => false);
final currentToolProvider = StateProvider<ToolMode>((ref) => ToolMode.select);
final rulerVisibilityProvider = StateProvider<bool>((ref) => true);
final showGridProvider = StateProvider<bool>((ref) => false);
final snapToGridProvider = StateProvider<bool>((ref) => false);
final zoomLevelProvider = StateProvider<double>((ref) => 1.0);
final cursorPositionProvider = StateProvider<Offset>((ref) => Offset.zero);
final autoPlayProvider = StateProvider<bool>((ref) => false);
final autoPlayIntervalProvider = StateProvider<int>((ref) => 5);

// Undo/Redo History
final historyProvider = StateNotifierProvider<HistoryNotifier, HistoryState>((ref) {
  return HistoryNotifier(ref);
});

class HistoryState {
  final List<Presentation> states;
  final int currentIndex;

  HistoryState({
    required this.states,
    required this.currentIndex,
  });

  bool get canUndo => currentIndex > 0;
  bool get canRedo => currentIndex < states.length - 1;
}

class HistoryNotifier extends StateNotifier<HistoryState> {
  final Ref ref;

  HistoryNotifier(this.ref) 
      : super(HistoryState(states: [], currentIndex: -1));

  void addState(Presentation presentation) {
    final states = state.currentIndex < state.states.length - 1
        ? state.states.sublist(0, state.currentIndex + 1)
        : List<Presentation>.from(state.states);
    
    states.add(presentation);
    
    if (states.length > 50) {
      states.removeAt(0);
      state = HistoryState(states: states, currentIndex: states.length - 1);
    } else {
      state = HistoryState(states: states, currentIndex: states.length - 1);
    }
  }

  void undo() {
    if (state.canUndo) {
      final newIndex = state.currentIndex - 1;
      ref.read(presentationProvider.notifier)
          .loadPresentation(state.states[newIndex]);
      state = HistoryState(states: state.states, currentIndex: newIndex);
    }
  }

  void redo() {
    if (state.canRedo) {
      final newIndex = state.currentIndex + 1;
      ref.read(presentationProvider.notifier)
          .loadPresentation(state.states[newIndex]);
      state = HistoryState(states: state.states, currentIndex: newIndex);
    }
  }
}

// ==================== MAIN APP ====================

void main() {
  runApp(const ProviderScope(child: PresentationApp()));
}

class PresentationApp extends StatelessWidget {
  const PresentationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Advanced Presentation Studio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: const PresentationEditor(),
    );
  }
}

class PresentationEditor extends ConsumerWidget {
  const PresentationEditor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presentation = ref.watch(presentationProvider);
    final isPresenterMode = ref.watch(presenterModeProvider);

    if (isPresenterMode) {
      return const PresenterView();
    }

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.delete) {
            final selected = ref.read(selectedComponentProvider);
            if (selected != null) {
              ref.read(presentationProvider.notifier).deleteComponent(selected);
              ref.read(selectedComponentProvider.notifier).state = null;
            }
            return KeyEventResult.handled;
          } else if (HardwareKeyboard.instance.isControlPressed) {
            if (event.logicalKey == LogicalKeyboardKey.keyZ) {
              ref.read(historyProvider.notifier).undo();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.keyY) {
              ref.read(historyProvider.notifier).redo();
              return KeyEventResult.handled;
            }
          } else if (event.logicalKey == LogicalKeyboardKey.f5) {
            ref.read(presenterModeProvider.notifier).state = true;
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Text(presentation.title, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _ToolButton(
            icon: Icons.near_me,
            label: 'Select',
            isSelected: currentTool == ToolMode.select,
            onPressed: () => ref.read(currentToolProvider.notifier).state = ToolMode.select,
          ),
          _ToolButton(
            icon: Icons.text_fields,
            label: 'Text',
            isSelected: currentTool == ToolMode.text,
            onPressed: () => ref.read(currentToolProvider.notifier).state = ToolMode.text,
          ),
          _ToolButton(
            icon: Icons.image,
            label: 'Image',
            isSelected: currentTool == ToolMode.image,
            onPressed: () => _addImage(ref, context),
          ),
          _ToolButton(
            icon: Icons.auto_graph,
            label: 'Chart',
            isSelected: currentTool == ToolMode.chart,
            onPressed: () => _showChartDialog(context, ref),
          ),
          PopupMenuButton(
            icon: const Icon(Icons.shapes),
            tooltip: 'Shapes',
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Row(
                  children: [Icon(Icons.crop_square), SizedBox(width: 8), Text('Rectangle')],
                ),
                onTap: () => _addShape(ref, ComponentType.shape),
              ),
              PopupMenuItem(
                child: const Row(
                  children: [Icon(Icons.circle_outlined), SizedBox(width: 8), Text('Circle')],
                ),
                onTap: () => _addShape(ref, ComponentType.circle),
              ),
              PopupMenuItem(
                child: const Row(
                  children: [Icon(Icons.change_history), SizedBox(width: 8), Text('Triangle')],
                ),
                onTap: () => _addShape(ref, ComponentType.triangle),
              ),
            ],
          ),
          const VerticalDivider(),
          IconButton(
            icon: const Icon(Icons.flip_to_front),
            tooltip: 'Bring to Front',
            onPressed: () {
              final selected = ref.read(selectedComponentProvider);
              if (selected != null) {
                ref.read(presentationProvider.notifier).bringToFront(selected);
                ref.read(historyProvider.notifier).addState(ref.read(presentationProvider));
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.flip_to_back),
            tooltip: 'Send to Back',
            onPressed: () {
              final selected = ref.read(selectedComponentProvider);
              if (selected != null) {
                ref.read(presentationProvider.notifier).sendToBack(selected);
                ref.read(historyProvider.notifier).addState(ref.read(presentationProvider));
              }
            },
          ),
          const VerticalDivider(),
          IconButton(
            icon: Icon(showRuler ? Icons.straighten : Icons.straighten_outlined),
            tooltip: 'Toggle Ruler',
            color: showRuler ? Theme.of(context).colorScheme.primary : null,
            onPressed: () {
              ref.read(rulerVisibilityProvider.notifier).state = !showRuler;
            },
          ),
          IconButton(
            icon: Icon(showGrid ? Icons.grid_on : Icons.grid_off),
            tooltip: 'Toggle Grid',
            color: showGrid ? Theme.of(context).colorScheme.primary : null,
            onPressed: () {
              ref.read(showGridProvider.notifier).state = !showGrid;
            },
          ),
          const VerticalDivider(),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Delete (Del)',
            onPressed: () {
              final selected = ref.read(selectedComponentProvider);
              if (selected != null) {
                ref.read(presentationProvider.notifier).deleteComponent(selected);
                ref.read(selectedComponentProvider.notifier).state = null;
                ref.read(historyProvider.notifier).addState(ref.read(presentationProvider));
              }
            },
          ),
        ],
      ),
    );
  }

  void _addShape(WidgetRef ref, ComponentType type) {
    final presentation = ref.read(presentationProvider);
    final component = PresentationComponent(
      id: const Uuid().v4(),
      type: type,
      position: const Offset(300, 300),
      size: const Size(200, 200),
      backgroundColor: presentation.theme.primaryColor,
    );
    ref.read(presentationProvider.notifier).addComponent(component);
    ref.read(selectedComponentProvider.notifier).state = component.id;
    ref.read(historyProvider.notifier).addState(ref.read(presentationProvider));
  }

  Future<void> _addImage(WidgetRef ref, BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        final component = PresentationComponent(
          id: const Uuid().v4(),
          type: ComponentType.image,
          position: const Offset(300, 300),
          size: const Size(400, 300),
          imageData: result.files.single.bytes,
        );
        ref.read(presentationProvider.notifier).addComponent(component);
        ref.read(selectedComponentProvider.notifier).state = component.id;
        ref.read(historyProvider.notifier).addState(ref.read(presentationProvider));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding image: $e')),
      );
    }
  }

  void _showChartDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Insert Chart'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.show_chart),
              title: const Text('Line Chart'),
              onTap: () {
                _addChart(ref, ChartType.line);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('Bar Chart'),
              onTap: () {
                _addChart(ref, ChartType.bar);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.pie_chart),
              title: const Text('Pie Chart'),
              onTap: () {
                _addChart(ref, ChartType.pie);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addChart(WidgetRef ref, ChartType type) {
    final presentation = ref.read(presentationProvider);
    final chartData = ChartData(
      type: type,
      values: [30, 50, 70, 40, 60],
      labels: ['Q1', 'Q2', 'Q3', 'Q4', 'Q5'],
      colors: presentation.theme.colorPalette,
    );
    
    final component = PresentationComponent(
      id: const Uuid().v4(),
      type: ComponentType.chart,
      position: const Offset(300, 300),
      size: const Size(500, 350),
      chartData: chartData,
      backgroundColor: Colors.white,
    );
    ref.read(presentationProvider.notifier).addComponent(component);
    ref.read(selectedComponentProvider.notifier).state = component.id;
    ref.read(historyProvider.notifier).addState(ref.read(presentationProvider));
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: isSelected 
            ? Theme.of(context).colorScheme.primaryContainer 
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon, 
                  size: 24, 
                  color: isSelected 
                      ? Theme.of(context).colorScheme.primary 
                      : Theme.of(context).iconTheme.color,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: isSelected 
                        ? Theme.of(context).colorScheme.primary 
                        : Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ZoomControls extends ConsumerWidget {
  const ZoomControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zoom = ref.watch(zoomLevelProvider);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            iconSize: 20,
            onPressed: () {
              final newZoom = (zoom - 0.1).clamp(0.25, 3.0);
              ref.read(zoomLevelProvider.notifier).state = newZoom;
            },
          ),
          Text('${(zoom * 100).toInt()}%', style: const TextStyle(fontSize: 14)),
          IconButton(
            icon: const Icon(Icons.add),
            iconSize: 20,
            onPressed: () {
              final newZoom = (zoom + 0.1).clamp(0.25, 3.0);
              ref.read(zoomLevelProvider.notifier).state = newZoom;
            },
          ),
          IconButton(
            icon: const Icon(Icons.fit_screen),
            iconSize: 20,
            tooltip: 'Fit to Screen',
            onPressed: () {
              ref.read(zoomLevelProvider.notifier).state = 1.0;
            },
          ),
        ],
      ),
    );
  }
}

// ==================== CANVAS AREA WITH RULERS ====================

class SlideCanvasArea extends ConsumerStatefulWidget {
  const SlideCanvasArea({super.key});

  @override
  ConsumerState<SlideCanvasArea> createState() => _SlideCanvasAreaState();
}

class _SlideCanvasAreaState extends ConsumerState<SlideCanvasArea> {
  @override
  Widget build(BuildContext context) {
    final showRuler = ref.watch(rulerVisibilityProvider);
    final cursorPosition = ref.watch(cursorPositionProvider);
    final presentation = ref.watch(presentationProvider);
    final canvasWidth = presentation.slideSize.width;
    final canvasHeight = presentation.slideSize.height;

    return Container(
      color: Colors.grey[300],
      child: Column(
        children: [
          if (showRuler)
            HorizontalRuler(
              width: canvasWidth,
              cursorX: cursorPosition.dx,
              leftMargin: 0,
              rightMargin: 0,
            ),
          Expanded(
            child: Row(
              children: [
                if (showRuler)
                  VerticalRuler(
                    height: canvasHeight,
                    cursorY: cursorPosition.dy,
                    topMargin: 0,
                    bottomMargin: 0,
                  ),
                Expanded(
                  child: Center(
                    child: SlideCanvas(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SlideCanvas extends ConsumerStatefulWidget {
  const SlideCanvas({super.key});

  @override
  ConsumerState<SlideCanvas> createState() => _SlideCanvasState();
}

class _SlideCanvasState extends ConsumerState<SlideCanvas> {
  @override
  Widget build(BuildContext context) {
    final presentation = ref.watch(presentationProvider);
    final currentSlide = presentation.slides[presentation.currentSlideIndex];
    final sortedComponents = List<PresentationComponent>.from(currentSlide.components)
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));
    final zoom = ref.watch(zoomLevelProvider);
    final showGrid = ref.watch(showGridProvider);
    final currentTool = ref.watch(currentToolProvider);

    return MouseRegion(
      onHover: (event) {
        ref.read(cursorPositionProvider.notifier).state = event.localPosition / zoom;
      },
      child: Transform.scale(
        scale: zoom,
        child: Container(
          width: presentation.slideSize.width,
          height: presentation.slideSize.height,
          decoration: BoxDecoration(
            color: currentSlide.backgroundColor ?? presentation.theme.backgroundColor,
            image: currentSlide.backgroundImage != null
                ? DecorationImage(
                    image: MemoryImage(currentSlide.backgroundImage!),
                    fit: BoxFit.cover,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: GestureDetector(
            onTapDown: (details) {
              final localPos = details.localPosition;
              if (currentTool == ToolMode.text) {
                _addRichText(localPos);
              } else {
                ref.read(selectedComponentProvider.notifier).state = null;
              }
            },
            child: Stack(
              children: [
                if (showGrid) const GridPainter(),
                ...sortedComponents
                    .map((c) => ResizableComponent(component: c))
                    .toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _addRichText(Offset position) {
    final presentation = ref.read(presentationProvider);
    final richText = RichTextContent(
      text: 'Double click to edit',
      style: presentation.theme.bodyStyle,
      alignment: TextAlign.left,
    );
    
    final component = PresentationComponent(
      id: const Uuid().v4(),
      type: ComponentType.richText,
      position: position,
      size: const Size(300, 100),
      richText: richText,
      backgroundColor: Colors.transparent,
    );
    
    ref.read(presentationProvider.notifier).addComponent(component);
    ref.read(selectedComponentProvider.notifier).state = component.id;
    ref.read(historyProvider.notifier).addState(ref.read(presentationProvider));
    ref.read(currentToolProvider.notifier).state = ToolMode.select;
  }
}

// ==================== RULERS ====================

class HorizontalRuler extends StatelessWidget {
  final double width;
  final double cursorX;
  final double leftMargin;
  final double rightMargin;

  const HorizontalRuler({
    super.key,
    required this.width,
    this.cursorX = 0,
    this.leftMargin = 0,
    this.rightMargin = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return CustomPaint(
            size: Size(constraints.maxWidth, 30),
            painter: HorizontalRulerPainter(
              leftMargin: leftMargin,
              rightMargin: rightMargin,
              pageWidth: width,
              cursorX: cursorX,
              color: Theme.of(context).colorScheme.onSurface,
              isDark: Theme.of(context).brightness == Brightness.dark,
            ),
          );
        },
      ),
    );
  }
}

class HorizontalRulerPainter extends CustomPainter {
  final double leftMargin;
  final double rightMargin;
  final double pageWidth;
  final double cursorX;
  final Color color;
  final bool isDark;

  HorizontalRulerPainter({
    required this.leftMargin,
    required this.rightMargin,
    required this.pageWidth,
    required this.cursorX,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.6)
      ..strokeWidth = 1;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    const pixelsPerInch = 96.0;
    final totalInches = (size.width / pixelsPerInch).ceil();

    for (int i = 0; i <= totalInches * 8; i++) {
      final inches = i / 8.0;
      final x = inches * pixelsPerInch;

      if (x > size.width) break;

      final isInch = i % 8 == 0;
      final isHalfInch = i % 4 == 0;
      final isQuarterInch = i % 2 == 0;

      double lineHeight;
      if (isInch) {
        lineHeight = 20;
        if (i > 0) {
          textPainter.text = TextSpan(
            text: '${i ~/ 8}',
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          );
          textPainter.layout();
          textPainter.paint(canvas, Offset(x - textPainter.width / 2, 2));
        }
      } else if (isHalfInch) {
        lineHeight = 14;
      } else if (isQuarterInch) {
        lineHeight = 10;
      } else {
        lineHeight = 6;
      }

      canvas.drawLine(
        Offset(x, size.height - lineHeight),
        Offset(x, size.height),
        paint,
      );
    }

    if (cursorX > 0 && cursorX < size.width) {
      final cursorPaint = Paint()
        ..color = Colors.red
        ..strokeWidth = 1;

      canvas.drawLine(
        Offset(cursorX, 0),
        Offset(cursorX, size.height),
        cursorPaint,
      );

      final path = Path()
        ..moveTo(cursorX - 4, 0)
        ..lineTo(cursorX + 4, 0)
        ..lineTo(cursorX, 6)
        ..close();

      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.red
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(HorizontalRulerPainter oldDelegate) {
    return oldDelegate.cursorX != cursorX || oldDelegate.pageWidth != pageWidth;
  }
}

class VerticalRuler extends StatelessWidget {
  final double height;
  final double cursorY;
  final double topMargin;
  final double bottomMargin;

  const VerticalRuler({
    super.key,
    required this.height,
    this.cursorY = 0,
    this.topMargin = 0,
    this.bottomMargin = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        border: Border(
          right: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: CustomPaint(
        size: Size(30, height),
        painter: VerticalRulerPainter(
          topMargin: topMargin,
          bottomMargin: bottomMargin,
          pageHeight: height,
          cursorY: cursorY,
          color: Theme.of(context).colorScheme.onSurface,
          isDark: Theme.of(context).brightness == Brightness.dark,
        ),
      ),
    );
  }
}

class VerticalRulerPainter extends CustomPainter {
  final double topMargin;
  final double bottomMargin;
  final double pageHeight;
  final double cursorY;
  final Color color;
  final bool isDark;

  VerticalRulerPainter({
    required this.topMargin,
    required this.bottomMargin,
    required this.pageHeight,
    required this.cursorY,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.6)
      ..strokeWidth = 1;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    const pixelsPerInch = 96.0;
    final totalInches = (size.height / pixelsPerInch).ceil();

    for (int i = 0; i <= totalInches * 8; i++) {
      final inches = i / 8.0;
      final y = inches * pixelsPerInch;

      if (y > size.height) break;

      final isInch = i % 8 == 0;
      final isHalfInch = i % 4 == 0;
      final isQuarterInch = i % 2 == 0;

      double lineWidth;
      if (isInch) {
        lineWidth = 20;
        if (i > 0) {
          canvas.save();
          canvas.translate(15, y);
          canvas.rotate(-1.5708);
          textPainter.text = TextSpan(
            text: '${i ~/ 8}',
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          );
          textPainter.layout();
          textPainter.paint(canvas, Offset(-textPainter.width / 2, -4));
          canvas.restore();
        }
      } else if (isHalfInch) {
        lineWidth = 14;
      } else if (isQuarterInch) {
        lineWidth = 10;
      } else {
        lineWidth = 6;
      }

      canvas.drawLine(
        Offset(size.width - lineWidth, y),
        Offset(size.width, y),
        paint,
      );
    }

    if (cursorY > 0 && cursorY < size.height) {
      final cursorPaint = Paint()
        ..color = Colors.red
        ..strokeWidth = 1;

      canvas.drawLine(
        Offset(0, cursorY),
        Offset(size.width, cursorY),
        cursorPaint,
      );

      final path = Path()
        ..moveTo(0, cursorY - 4)
        ..lineTo(0, cursorY + 4)
        ..lineTo(6, cursorY)
        ..close();

      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.red
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(VerticalRulerPainter oldDelegate) {
    return oldDelegate.cursorY != cursorY ||
        oldDelegate.pageHeight != pageHeight;
  }
}

class GridPainter extends StatelessWidget {
  const GridPainter({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GridPainter(),
      child: Container(),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1;

    const gridSize = 20.0;

    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}

// ==================== RESIZABLE COMPONENT ====================

class ResizableComponent extends ConsumerStatefulWidget {
  final PresentationComponent component;

  const ResizableComponent({super.key, required this.component});

  @override
  ConsumerState<ResizableComponent> createState() => _ResizableComponentState();
}

enum ResizeHandle {
  topLeft, topRight, bottomLeft, bottomRight,
  top, bottom, left, right, rotate
}

class _ResizableComponentState extends ConsumerState<ResizableComponent> {
  Offset? dragStart;
  Size? resizeStart;
  Offset? positionStart;
  ResizeHandle? activeHandle;
  double? rotationStart;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _textController.text = widget.component.richText?.text ?? '';
  }

  @override
  void didUpdateWidget(ResizableComponent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.component.richText?.text != widget.component.richText?.text) {
      _textController.text = widget.component.richText?.text ?? '';
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = ref.watch(selectedComponentProvider) == widget.component.id;
    final snapToGrid = ref.watch(snapToGridProvider);

    return Positioned(
      left: widget.component.position.dx,
      top: widget.component.position.dy,
      child: Transform.rotate(
        angle: widget.component.rotation * math.pi / 180,
        child: GestureDetector(
          onTap: () {
            ref.read(selectedComponentProvider.notifier).state = widget.component.id;
          },
          onDoubleTap: () {
            if (widget.component.type == ComponentType.richText) {
              ref.read(presentationProvider.notifier).updateComponent(
                widget.component.id,
                widget.component.copyWith(isEditing: true),
              );
              _focusNode.requestFocus();
            }
          },
          onPanStart: (details) {
            if (!isSelected) return;
            dragStart = details.localPosition;
            positionStart = widget.component.position;
          },
          onPanUpdate: (details) {
            if (!isSelected || dragStart == null || positionStart == null) return;
            var delta = details.localPosition - dragStart!;
            var newPosition = positionStart! + delta;

            if (snapToGrid) {
              newPosition = Offset(
                (newPosition.dx / 20).round() * 20.0,
                (newPosition.dy / 20).round() * 20.0,
              );
            }

            ref.read(presentationProvider.notifier).updateComponent(
              widget.component.id,
              widget.component.copyWith(position: newPosition),
            );
          },
          onPanEnd: (_) {
            ref.read(historyProvider.notifier).addState(ref.read(presentationProvider));
          },
          child: Opacity(
            opacity: widget.component.opacity,
            child: Container(
              width: widget.component.size.width,
              height: widget.component.size.height,
              decoration: BoxDecoration(
                border: isSelected
                    ? Border.all(color: Colors.blue, width: 2)
                    : widget.component.border != null
                      ? Border.fromBorderSide(widget.component.border!)
                      : null,
                color: widget.component.backgroundColor,
              ),
              child: Stack(
                children: [
                  _buildComponentContent(),
                  if (isSelected) ..._buildResizeHandles(),
                  if (isSelected) _buildRotateHandle(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComponentContent() {
    switch (widget.component.type) {
      case ComponentType.richText:
        if (widget.component.isEditing) {
          return TextField(
            controller: _textController,
            focusNode: _focusNode,
            style: widget.component.richText?.style,
            textAlign: widget.component.richText?.alignment ?? TextAlign.left,
            maxLines: null,
            expands: true,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(12),
            ),
            onChanged: (value) {
              final updatedRichText = widget.component.richText?.copyWith(text: value);
              ref.read(presentationProvider.notifier).updateComponent(
                widget.component.id,
                widget.component.copyWith(richText: updatedRichText),
              );
            },
            on.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Slide ${presentation.currentSlideIndex + 1}/${presentation.slides.length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.undo),
              tooltip: 'Undo (Ctrl+Z)',
              onPressed: ref.watch(historyProvider).canUndo
                  ? () => ref.read(historyProvider.notifier).undo()
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.redo),
              tooltip: 'Redo (Ctrl+Y)',
              onPressed: ref.watch(historyProvider).canRedo
                  ? () => ref.read(historyProvider.notifier).redo()
                  : null,
            ),
            const VerticalDivider(),
            IconButton(
              icon: const Icon(Icons.palette),
              tooltip: 'Themes',
              onPressed: () => _showThemeDialog(context, ref),
            ),
            IconButton(
              icon: const Icon(Icons.slideshow),
              tooltip: 'Presenter Mode (F5)',
              onPressed: () {
                ref.read(presenterModeProvider.notifier).state = true;
              },
            ),
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Export to PPT',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Export feature coming soon!')),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Row(
          children: [
            Container(
              width: 240,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  right: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: const SlidePanel(),
            ),
            Expanded(
              child: Column(
                children: [
                  const Toolbar(),
                  Expanded(
                    child: Stack(
                      children: [
                        const SlideCanvasArea(),
                        Positioned(
                          bottom: 16,
                          right: 16,
                          child: ZoomControls(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 320,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  left: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: const PropertiesPanel(),
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ThemeOption(
                theme: PresentationTheme.defaultTheme,
                onSelect: () {
                  ref.read(presentationProvider.notifier).applyTheme(PresentationTheme.defaultTheme);
                  ref.read(historyProvider.notifier).addState(ref.read(presentationProvider));
                  Navigator.pop(context);
                },
              ),
              _ThemeOption(
                theme: PresentationTheme.modernDark,
                onSelect: () {
                  ref.read(presentationProvider.notifier).applyTheme(PresentationTheme.modernDark);
                  ref.read(historyProvider.notifier).addState(ref.read(presentationProvider));
                  Navigator.pop(context);
                },
              ),
              _ThemeOption(
                theme: PresentationTheme.minimalist,
                onSelect: () {
                  ref.read(presentationProvider.notifier).applyTheme(PresentationTheme.minimalist);
                  ref.read(historyProvider.notifier).addState(ref.read(presentationProvider));
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final PresentationTheme theme;
  final VoidCallback onSelect;

  const _ThemeOption({required this.theme, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onSelect,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(theme.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: theme.colorPalette.take(5).map((color) {
                  return Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Continue with remaining UI components...
class Toolbar extends ConsumerWidget {
  const Toolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTool = ref.watch(currentToolProvider);
    final showRuler = ref.watch(rulerVisibilityProvider);
    final showGrid = ref.watch(showGridProvider);

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      padding: const EdgeInsets 





//---------

circular(4),
                              ),
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                slide.title ?? 'Slide ${index + 1}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            PopupMenuButton(
                              icon: const Icon(Icons.more_vert, size: 18),
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  child: const Row(
                                    children: [
                                      Icon(Icons.content_copy, size: 18),
                                      SizedBox(width: 8),
                                      Text('Duplicate'),
                                    ],
                                  ),
                                  onTap: () => Future.delayed(
                                    Duration.zero,
                                    () => ref.read(presentationProvider.notifier).duplicateSlide(index),
                                  ),
                                ),
                                PopupMenuItem(
                                  child: const Row(
                                    children: [
                                      Icon(Icons.delete, size: 18, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Delete', style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                  onTap: () => Future.delayed(
                                    Duration.zero,
                                    () => ref.read(presentationProvider.notifier).deleteSlide(index),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.all(8),
                        height: 80,
                        decoration: BoxDecoration(
                          color: slide.backgroundColor ?? presentation.theme.backgroundColor,
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(4),
                          image: slide.backgroundImage != null
                              ? DecorationImage(
                                  image: MemoryImage(slide.backgroundImage!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${slide.components.length} items',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}



//-------------

      onSubmitted: (_) {
              ref.read(presentationProvider.notifier).updateComponent(
                widget.component.id,
                widget.component.copyWith(isEditing: false),
              );
              ref.read(historyProvider.notifier).addState(ref.read(presentationProvider));
            },
          );
        } else {
          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              widget.component.richText?.text ?? '',
              style: widget.component.richText?.style,
              textAlign: widget.component.richText?.alignment ?? TextAlign.left,
            ),
          );
        }
      case ComponentType.image:
        return widget.component.imageData != null
            ? Image.memory(
                widget.component.imageData!,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                  );
                },
              )
            : const Center(
                child: Icon(Icons.image, size: 48, color: Colors.grey),
              );
      case ComponentType.shape:
        return Container(color: widget.component.backgroundColor);
      case ComponentType.circle:
        return Container(
          decoration: BoxDecoration(
            color: widget.component.backgroundColor,
            shape: BoxShape.circle,
          ),
        );
      case ComponentType.triangle:
        return CustomPaint(
          painter: TrianglePainter(widget.component.backgroundColor ?? Colors.blue),
        );
      case ComponentType.chart:
        return widget.component.chartData != null
            ? SimpleChartWidget(data: widget.component.chartData!)
            : const Center(child: Icon(Icons.auto_graph, size: 48));
      case ComponentType.video:
        return Container(
          color: Colors.black,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.play_circle_outline, size: 64, color: Colors.white),
                const SizedBox(height: 8),
                Text(
                  widget.component.videoUrl ?? 'Video',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        );
      case ComponentType.diagram:
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
          ),
          child: const Center(
            child: Icon(Icons.account_tree, size: 48, color: Colors.grey),
          ),
        );
    }
  }

  List<Widget> _buildResizeHandles() {
    return [
      _buildHandle(ResizeHandle.topLeft, Alignment.topLeft),
      _buildHandle(ResizeHandle.topRight, Alignment.topRight),
      _buildHandle(ResizeHandle.bottomLeft, Alignment.bottomLeft),
      _buildHandle(ResizeHandle.bottomRight, Alignment.bottomRight),
      _buildHandle(ResizeHandle.top, Alignment.topCenter),
      _buildHandle(ResizeHandle.bottom, Alignment.bottomCenter),
      _buildHandle(ResizeHandle.left, Alignment.centerLeft),
      _buildHandle(ResizeHandle.right, Alignment.centerRight),
    ];
  }

  Widget _buildHandle(ResizeHandle handle, Alignment alignment) {
    return Align(
      alignment: alignment,
      child: GestureDetector(
        onPanStart: (details) {
          activeHandle = handle;
          resizeStart = widget.component.size;
          positionStart = widget.component.position;
        },
        onPanUpdate: (details) {
          if (activeHandle == null || resizeStart == null || positionStart == null) return;

          double newWidth = resizeStart!.width;
          double newHeight = resizeStart!.height;
          double newX = positionStart!.dx;
          double newY = positionStart!.dy;

          switch (activeHandle!) {
            case ResizeHandle.topLeft:
              newWidth = math.max(50, resizeStart!.width - details.delta.dx);
              newHeight = math.max(50, resizeStart!.height - details.delta.dy);
              newX = positionStart!.dx + (resizeStart!.width - newWidth);
              newY = positionStart!.dy + (resizeStart!.height - newHeight);
              break;
            case ResizeHandle.topRight:
              newWidth = math.max(50, resizeStart!.width + details.delta.dx);
              newHeight = math.max(50, resizeStart!.height - details.delta.dy);
              newY = positionStart!.dy + (resizeStart!.height - newHeight);
              break;
            case ResizeHandle.bottomLeft:
              newWidth = math.max(50, resizeStart!.width - details.delta.dx);
              newHeight = math.max(50, resizeStart!.height + details.delta.dy);
              newX = positionStart!.dx + (resizeStart!.width - newWidth);
              break;
            case ResizeHandle.bottomRight:
              newWidth = math.max(50, resizeStart!.width + details.delta.dx);
              newHeight = math.max(50, resizeStart!.height + details.delta.dy);
              break;
            case ResizeHandle.top:
              newHeight = math.max(50, resizeStart!.height - details.delta.dy);
              newY = positionStart!.dy + (resizeStart!.height - newHeight);
              break;
            case ResizeHandle.bottom:
              newHeight = math.max(50, resizeStart!.height + details.delta.dy);
              break;
            case ResizeHandle.left:
              newWidth = math.max(50, resizeStart!.width - details.delta.dx);
              newX = positionStart!.dx + (resizeStart!.width - newWidth);
              break;
            case ResizeHandle.right:
              newWidth = math.max(50, resizeStart!.width + details.delta.dx);
              break;
            default:
              break;
          }

          ref.read(presentationProvider.notifier).updateComponent(
            widget.component.id,
            widget.component.copyWith(
              size: Size(newWidth, newHeight),
              position: Offset(newX, newY),
            ),
          );
        },
        onPanEnd: (_) {
          activeHandle = null;
          resizeStart = null;
          positionStart = null;
          ref.read(historyProvider.notifier).addState(ref.read(presentationProvider));
        },
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.blue, width: 2),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

}