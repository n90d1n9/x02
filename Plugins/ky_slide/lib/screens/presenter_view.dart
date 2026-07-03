import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

//import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
                    return _buildTransition(
                      currentSlide.transition,
                      child,
                      animation,
                    );
                  },
                  child: Container(
                    key: ValueKey(currentSlide.id),
                    decoration: BoxDecoration(
                      color:
                          currentSlide.backgroundColor ??
                          presentation.theme.backgroundColor,
                      image: currentSlide.backgroundImage != null
                          ? DecorationImage(
                              image: MemoryImage(currentSlide.backgroundImage!),
                              fit: BoxFit.cover,
                            )
                          : null,
                      gradient: currentSlide.backgroundGradient != null
                          ? LinearGradient(
                              colors: currentSlide.backgroundGradient!.colors,
                              begin: currentSlide.backgroundGradient!.begin,
                              end: currentSlide.backgroundGradient!.end,
                            )
                          : null,
                    ),
                    child: Stack(
                      children: [
                        if (currentSlide.backgroundParticles != null)
                          ParticleBackground(
                            effect: currentSlide.backgroundParticles!,
                          ),
                        ...currentSlide.components
                            .where((component) => component.isVisible)
                            .map((c) => _buildAnimatedComponent(c))
                            .toList()
                          ..sort((a, b) {
                            final aComp = currentSlide.components.firstWhere(
                              (c) => (a.key as ValueKey).value == c.id,
                            );
                            final bComp = currentSlide.components.firstWhere(
                              (c) => (b.key as ValueKey).value == c.id,
                            );
                            return aComp.zIndex.compareTo(bComp.zIndex);
                          }),
                      ],
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        presentation.theme.primaryColor.withValues(alpha: 0.9),
                        presentation.theme.secondaryColor.withValues(
                          alpha: 0.9,
                        ),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: presentation.theme.primaryColor.withValues(
                          alpha: 0.5,
                        ),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (autoPlay) ...[
                        const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        'Slide ${presentation.currentSlideIndex + 1} / ${presentation.slides.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: IconButton(
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
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 32,
                      ),
                      onPressed: () {
                        ref.read(presenterModeProvider.notifier).state = false;
                        _autoPlayTimer?.cancel();
                      },
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 30,
              left: 30,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '⌨️ Keyboard Shortcuts',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'ESC - Exit',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                    const Text(
                      'Space / → - Next',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                    const Text(
                      '← - Previous',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                    const Text(
                      'F5 - Toggle Present',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
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

  Widget _buildTransition(
    SlideTransitionType transition,
    Widget child,
    Animation<double> animation,
  ) {
    switch (transition) {
      case SlideTransitionType.fade:
        return FadeTransition(opacity: animation, child: child);
      case SlideTransitionType.slide:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      case SlideTransitionType.zoom:
        return ScaleTransition(scale: animation, child: child);
      case SlideTransitionType.dissolve:
        return FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          ),
          child: child,
        );
      case SlideTransitionType.flip:
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
          child: SizedBox(
            width: component.size.width,
            height: component.size.height,
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
    Widget baseContent;

    switch (component.type) {
      case ComponentType.richText:
        baseContent = Container(
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
        break;
      case ComponentType.image:
        baseContent = component.imageData != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(component.imageData!, fit: BoxFit.cover),
              )
            : const Icon(Icons.image);
        break;
      case ComponentType.shape:
        baseContent = Container(
          decoration: BoxDecoration(
            color: component.backgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
        );
        break;
      case ComponentType.circle:
        baseContent = Container(
          decoration: BoxDecoration(
            color: component.backgroundColor,
            shape: BoxShape.circle,
          ),
        );
        break;
      case ComponentType.triangle:
        baseContent = CustomPaint(
          painter: TrianglePainter(component.backgroundColor ?? Colors.blue),
        );
        break;
      case ComponentType.chart:
        baseContent = component.chartData != null
            ? Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: component.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SimpleChartWidget(data: component.chartData!),
              )
            : const Icon(Icons.auto_graph);
        break;
      case ComponentType.video:
        baseContent = Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  component.videoUrl ?? 'Video',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        );
        break;
      default:
        baseContent = Container();
    }

    // Apply visual effects
    if (component.visualEffect != null &&
        component.visualEffect != VisualEffect.none) {
      return _applyVisualEffectToContent(baseContent, component);
    }

    return baseContent;
  }

  Widget _applyVisualEffectToContent(
    Widget child,
    PresentationComponent component,
  ) {
    switch (component.visualEffect) {
      case VisualEffect.glassmorphism:
        return ClipRRect(
          borderRadius: BorderRadius.circular(
            component.glassStyle?.borderRadius ?? 16,
          ),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(
              sigmaX: component.glassStyle?.blur ?? 10,
              sigmaY: component.glassStyle?.blur ?? 10,
            ),
            child: Container(
              decoration: BoxDecoration(
                color:
                    component.glassStyle?.tintColor.withValues(
                      alpha: component.glassStyle?.opacity ?? 0.2,
                    ) ??
                    Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(
                  component.glassStyle?.borderRadius ?? 16,
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: child,
            ),
          ),
        );
      case VisualEffect.glow:
      case VisualEffect.neon:
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: (component.glowColor ?? Colors.blue).withValues(
                  alpha: 0.8,
                ),
                blurRadius: 30,
                spreadRadius: 10,
              ),
            ],
          ),
          child: child,
        );
      default:
        return child;
    }
  }
}
