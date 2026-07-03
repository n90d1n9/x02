import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/alignment_guide.dart';
import '../models/alignment_snap_result.dart';
import '../models/component.dart';
import '../models/enums.dart';
import '../models/presentation_component.dart';
import '../models/transform_feedback.dart';
import '../services/alignment_guide_service.dart';
import '../services/component_layer_service.dart';
import '../services/component_rotation_service.dart';
import '../states/alignment_guides_provider.dart';
import '../states/component_provider.dart';
import '../states/history_provider.dart';
import '../states/presentation_provider.dart';
import '../states/transform_feedback_provider.dart';
import 'animated_gradient_container.dart';
import 'canvas/component_hover_overlay.dart';
import 'canvas/component_transform_handles.dart';
import 'simple_chart_widget.dart';
import 'triangle_painter.dart';

/// Interactive slide object widget for selection, editing, moving, resizing, and rotation.
class ModernResizableComponent extends ConsumerStatefulWidget {
  final PresentationComponent component;

  const ModernResizableComponent({super.key, required this.component});

  @override
  ConsumerState<ModernResizableComponent> createState() =>
      _ModernResizableComponentState();
}

/// Gesture state for an editable slide object on the canvas.
class _ModernResizableComponentState
    extends ConsumerState<ModernResizableComponent> {
  Offset? dragStart;
  Offset? resizeDragStart;
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
  void didUpdateWidget(ModernResizableComponent oldWidget) {
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
    final isSelected =
        ref.watch(selectedComponentProvider) == widget.component.id;
    final isHovered =
        ref.watch(hoveredComponentProvider) == widget.component.id;
    final snapToGrid = ref.watch(snapToGridProvider);
    final gridPreset = ref.watch(canvasGridPresetProvider);
    final currentTool = ref.watch(currentToolProvider);
    final accentColor = ref.watch(
      presentationProvider.select(
        (presentation) => presentation.theme.primaryColor,
      ),
    );
    final isLocked = widget.component.isLocked;
    final layerService = const ComponentLayerService();

    Widget content = _buildComponentContent();

    // Apply visual effects
    if (widget.component.visualEffect != null) {
      content = _applyVisualEffect(content);
    }

    return Positioned(
      left: widget.component.position.dx,
      top: widget.component.position.dy,
      child: Transform.rotate(
        angle: widget.component.rotation * math.pi / 180,
        child: MouseRegion(
          onEnter: (_) {
            if (currentTool != ToolMode.select) return;
            ref.read(hoveredComponentProvider.notifier).state =
                widget.component.id;
          },
          onExit: (_) {
            if (ref.read(hoveredComponentProvider) == widget.component.id) {
              ref.read(hoveredComponentProvider.notifier).state = null;
            }
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              ref.read(selectedComponentProvider.notifier).state =
                  widget.component.id;
            },
            onDoubleTap: () {
              if (isLocked) return;
              if (widget.component.type == ComponentType.richText) {
                ref
                    .read(presentationProvider.notifier)
                    .updateComponent(
                      widget.component.id,
                      widget.component.copyWith(isEditing: true),
                    );
                _focusNode.requestFocus();
              }
            },
            onPanStart: (details) {
              if (!isSelected || isLocked) return;
              dragStart = details.localPosition;
              positionStart = widget.component.position;
              _updateAlignmentGuides(widget.component);
              _setTransformFeedback(
                TransformFeedbackMode.move,
                widget.component,
              );
            },
            onPanUpdate: (details) {
              if (isLocked ||
                  !isSelected ||
                  dragStart == null ||
                  positionStart == null) {
                return;
              }
              var delta = details.localPosition - dragStart!;
              var newPosition = positionStart! + delta;

              if (snapToGrid) {
                final gridSize = gridPreset.spacing;
                newPosition = Offset(
                  (newPosition.dx / gridSize).round() * gridSize,
                  (newPosition.dy / gridSize).round() * gridSize,
                );
              }

              final snapResult = _snapMove(
                widget.component.copyWith(position: newPosition),
              );
              final updated = snapResult.component;
              _setAlignmentGuides(snapResult.guides);
              _setTransformFeedback(TransformFeedbackMode.move, updated);

              ref
                  .read(presentationProvider.notifier)
                  .updateComponent(widget.component.id, updated);
            },
            onPanEnd: (_) {
              if (isLocked || dragStart == null) return;
              dragStart = null;
              positionStart = null;
              _clearAlignmentGuides();
              _clearTransformFeedback();
              ref
                  .read(historyProvider.notifier)
                  .addState(ref.read(presentationProvider));
            },
            child: Opacity(
              opacity: widget.component.opacity,
              child: Container(
                width: widget.component.size.width,
                height: widget.component.size.height,
                decoration: BoxDecoration(
                  border: isSelected
                      ? Border.all(
                          color: isLocked
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFF6366F1),
                          width: 2,
                        )
                      : widget.component.border != null
                      ? Border.fromBorderSide(widget.component.border!)
                      : null,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(
                              0xFF6366F1,
                            ).withValues(alpha: 0.3),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ]
                      : widget.component.hasGlow
                      ? [
                          BoxShadow(
                            color: (widget.component.glowColor ?? Colors.blue)
                                .withValues(alpha: 0.6),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ]
                      : null,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    content,
                    if (isHovered && !isSelected)
                      ComponentHoverOverlay(
                        label: layerService.titleFor(widget.component),
                        typeLabel: layerService.typeLabelFor(
                          widget.component.type,
                        ),
                        isLocked: isLocked,
                        accentColor: accentColor,
                      ),
                    if (isSelected && !isLocked) ..._buildResizeHandles(),
                    if (isSelected && !isLocked) _buildRotateHandle(),
                    if (isSelected && isLocked) _buildLockBadge(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLockBadge() {
    return Positioned(
      top: 6,
      right: 6,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(7),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(Icons.lock_outline, size: 14, color: Colors.white),
      ),
    );
  }

  Widget _buildRotateHandle() {
    return ComponentRotateHandle(
      componentWidth: widget.component.size.width,
      onPanStart: (details) {
        rotationStart = widget.component.rotation;
        _setTransformFeedback(TransformFeedbackMode.rotate, widget.component);
      },
      onPanUpdate: (details) {
        if (rotationStart == null) return;

        final rotation = ComponentRotationService.rotationFromHandleDrag(
          localPosition: details.localPosition,
          componentSize: widget.component.size,
        );

        ref
            .read(presentationProvider.notifier)
            .updateComponent(
              widget.component.id,
              widget.component.copyWith(rotation: rotation),
            );
        _setTransformFeedback(
          TransformFeedbackMode.rotate,
          widget.component.copyWith(rotation: rotation),
        );
      },
      onPanEnd: (_) {
        rotationStart = null;
        _clearTransformFeedback();
        ref
            .read(historyProvider.notifier)
            .addState(ref.read(presentationProvider));
      },
    );
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
    return ComponentResizeHandle(
      handle: handle,
      alignment: alignment,
      onPanStart: (details) {
        activeHandle = handle;
        resizeStart = widget.component.size;
        positionStart = widget.component.position;
        resizeDragStart = details.globalPosition;
        _updateAlignmentGuides(widget.component);
        _setTransformFeedback(TransformFeedbackMode.resize, widget.component);
      },
      onPanUpdate: (details) {
        if (activeHandle == null ||
            resizeStart == null ||
            positionStart == null ||
            resizeDragStart == null) {
          return;
        }

        double newWidth = resizeStart!.width;
        double newHeight = resizeStart!.height;
        double newX = positionStart!.dx;
        double newY = positionStart!.dy;
        final zoom = math.max(ref.read(zoomLevelProvider), 0.1);
        final resizeDelta = (details.globalPosition - resizeDragStart!) / zoom;

        switch (activeHandle!) {
          case ResizeHandle.topLeft:
            newWidth = math.max(50, resizeStart!.width - resizeDelta.dx);
            newHeight = math.max(50, resizeStart!.height - resizeDelta.dy);
            newX = positionStart!.dx + (resizeStart!.width - newWidth);
            newY = positionStart!.dy + (resizeStart!.height - newHeight);
            break;
          case ResizeHandle.topRight:
            newWidth = math.max(50, resizeStart!.width + resizeDelta.dx);
            newHeight = math.max(50, resizeStart!.height - resizeDelta.dy);
            newY = positionStart!.dy + (resizeStart!.height - newHeight);
            break;
          case ResizeHandle.bottomLeft:
            newWidth = math.max(50, resizeStart!.width - resizeDelta.dx);
            newHeight = math.max(50, resizeStart!.height + resizeDelta.dy);
            newX = positionStart!.dx + (resizeStart!.width - newWidth);
            break;
          case ResizeHandle.bottomRight:
            newWidth = math.max(50, resizeStart!.width + resizeDelta.dx);
            newHeight = math.max(50, resizeStart!.height + resizeDelta.dy);
            break;
          case ResizeHandle.top:
            newHeight = math.max(50, resizeStart!.height - resizeDelta.dy);
            newY = positionStart!.dy + (resizeStart!.height - newHeight);
            break;
          case ResizeHandle.bottom:
            newHeight = math.max(50, resizeStart!.height + resizeDelta.dy);
            break;
          case ResizeHandle.left:
            newWidth = math.max(50, resizeStart!.width - resizeDelta.dx);
            newX = positionStart!.dx + (resizeStart!.width - newWidth);
            break;
          case ResizeHandle.right:
            newWidth = math.max(50, resizeStart!.width + resizeDelta.dx);
            break;
          default:
            break;
        }

        final updated = widget.component.copyWith(
          size: Size(newWidth, newHeight),
          position: Offset(newX, newY),
        );
        final snapResult = _snapResize(updated, activeHandle!);
        _setAlignmentGuides(snapResult.guides);
        _setTransformFeedback(
          TransformFeedbackMode.resize,
          snapResult.component,
        );

        ref
            .read(presentationProvider.notifier)
            .updateComponent(widget.component.id, snapResult.component);
      },
      onPanEnd: (_) {
        activeHandle = null;
        resizeStart = null;
        positionStart = null;
        resizeDragStart = null;
        _clearAlignmentGuides();
        _clearTransformFeedback();
        ref
            .read(historyProvider.notifier)
            .addState(ref.read(presentationProvider));
      },
    );
  }

  void _updateAlignmentGuides(PresentationComponent previewComponent) {
    final presentation = ref.read(presentationProvider);
    final currentSlide = presentation.slides[presentation.currentSlideIndex];
    final guides = AlignmentGuideService.resolve(
      component: previewComponent,
      components: currentSlide.components,
      slideSize: presentation.slideSize,
    );

    ref.read(alignmentGuidesProvider.notifier).state = guides;
  }

  AlignmentSnapResult _snapMove(PresentationComponent previewComponent) {
    final presentation = ref.read(presentationProvider);
    final currentSlide = presentation.slides[presentation.currentSlideIndex];

    return AlignmentGuideService.snapMove(
      component: previewComponent,
      components: currentSlide.components,
      slideSize: presentation.slideSize,
    );
  }

  AlignmentSnapResult _snapResize(
    PresentationComponent previewComponent,
    ResizeHandle handle,
  ) {
    final presentation = ref.read(presentationProvider);
    final currentSlide = presentation.slides[presentation.currentSlideIndex];

    return AlignmentGuideService.snapResize(
      component: previewComponent,
      handle: handle,
      components: currentSlide.components,
      slideSize: presentation.slideSize,
    );
  }

  void _setAlignmentGuides(List<AlignmentGuide> guides) {
    ref.read(alignmentGuidesProvider.notifier).state = guides;
  }

  void _clearAlignmentGuides() {
    ref.read(alignmentGuidesProvider.notifier).state = const [];
  }

  void _setTransformFeedback(
    TransformFeedbackMode mode,
    PresentationComponent component,
  ) {
    ref.read(transformFeedbackProvider.notifier).state =
        TransformFeedback.fromComponent(mode: mode, component: component);
  }

  void _clearTransformFeedback() {
    ref.read(transformFeedbackProvider.notifier).state = null;
  }

  Widget _applyVisualEffect(Widget child) {
    switch (widget.component.visualEffect) {
      case VisualEffect.glassmorphism:
        return ClipRRect(
          borderRadius: BorderRadius.circular(
            widget.component.glassStyle?.borderRadius ?? 16,
          ),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(
              sigmaX: widget.component.glassStyle?.blur ?? 10,
              sigmaY: widget.component.glassStyle?.blur ?? 10,
            ),
            child: Container(
              decoration: BoxDecoration(
                color:
                    widget.component.glassStyle?.tintColor.withValues(
                      alpha: widget.component.glassStyle?.opacity ?? 0.2,
                    ) ??
                    Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(
                  widget.component.glassStyle?.borderRadius ?? 16,
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
      case VisualEffect.neumorphism:
        final neumo = widget.component.neumoStyle;
        return Container(
          decoration: BoxDecoration(
            color: neumo?.baseColor ?? Colors.grey[300],
            borderRadius: BorderRadius.circular(neumo?.borderRadius ?? 16),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.7),
                offset: Offset(-(neumo?.depth ?? 10), -(neumo?.depth ?? 10)),
                blurRadius: (neumo?.depth ?? 10) * 2,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                offset: Offset(neumo?.depth ?? 10, neumo?.depth ?? 10),
                blurRadius: (neumo?.depth ?? 10) * 2,
              ),
            ],
          ),
          child: child,
        );
      case VisualEffect.gradient:
        if (widget.component.gradientAnim != null) {
          return AnimatedGradientContainer(
            gradient: widget.component.gradientAnim!,
            child: child,
          );
        }
        return child;
      default:
        return child;
    }
  }

  Widget _buildComponentContent() {
    switch (widget.component.type) {
      case ComponentType.richText:
        final richText = widget.component.richText;
        if (widget.component.isEditing) {
          return TextField(
            controller: _textController,
            focusNode: _focusNode,
            style: richText?.effectiveStyle,
            textAlign: richText?.alignment ?? TextAlign.left,
            maxLines: null,
            expands: true,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(12),
            ),
            onChanged: (value) {
              final updatedRichText = widget.component.richText?.copyWith(
                text: value,
              );
              ref
                  .read(presentationProvider.notifier)
                  .updateComponent(
                    widget.component.id,
                    widget.component.copyWith(richText: updatedRichText),
                  );
            },
            onSubmitted: (_) {
              ref
                  .read(presentationProvider.notifier)
                  .updateComponent(
                    widget.component.id,
                    widget.component.copyWith(isEditing: false),
                  );
              ref
                  .read(historyProvider.notifier)
                  .addState(ref.read(presentationProvider));
            },
          );
        } else {
          return Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: widget.component.backgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              richText?.text ?? '',
              style: richText?.effectiveStyle,
              textAlign: richText?.alignment ?? TextAlign.left,
            ),
          );
        }
      case ComponentType.image:
        return widget.component.imageData != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  widget.component.imageData!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(
                        Icons.broken_image,
                        size: 48,
                        color: Colors.white30,
                      ),
                    );
                  },
                ),
              )
            : const Center(
                child: Icon(Icons.image, size: 48, color: Colors.white30),
              );
      case ComponentType.shape:
        return Container(
          decoration: BoxDecoration(
            color: widget.component.backgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
        );
      case ComponentType.circle:
        return Container(
          decoration: BoxDecoration(
            color: widget.component.backgroundColor,
            shape: BoxShape.circle,
          ),
        );
      case ComponentType.triangle:
        return CustomPaint(
          painter: TrianglePainter(
            widget.component.backgroundColor ?? Colors.blue,
          ),
        );
      case ComponentType.chart:
        return widget.component.chartData != null
            ? Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.component.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SimpleChartWidget(data: widget.component.chartData!),
              )
            : const Center(
                child: Icon(Icons.auto_graph, size: 48, color: Colors.white30),
              );
      case ComponentType.video:
        return Container(
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
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF6366F1).withValues(alpha: 0.8),
                        const Color(0xFF8B5CF6).withValues(alpha: 0.8),
                      ],
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
                  widget.component.videoUrl ?? 'Video',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        );
      case ComponentType.hotspot:
        return _buildInteractiveContent();
      default:
        return Container(
          decoration: BoxDecoration(
            color: widget.component.backgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Icon(Icons.widgets, size: 48, color: Colors.white30),
          ),
        );
    }
  }

  Widget _buildInteractiveContent() {
    final interactive = widget.component.interactive;
    if (interactive == null) return Container();

    switch (interactive.type) {
      case InteractiveType.hotspot:
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF6366F1).withValues(alpha: 0.3),
                const Color(0xFF8B5CF6).withValues(alpha: 0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF6366F1), width: 2),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.ads_click, size: 48, color: Colors.white),
                const SizedBox(height: 8),
                Text(
                  interactive.label ?? 'Click Here',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      case InteractiveType.poll:
      case InteractiveType.quiz:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF10B981).withValues(alpha: 0.2),
                const Color(0xFF14B8A6).withValues(alpha: 0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF10B981), width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    interactive.type == InteractiveType.poll
                        ? Icons.poll
                        : Icons.quiz,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    interactive.label ??
                        (interactive.type == InteractiveType.poll
                            ? 'Poll'
                            : 'Quiz'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (interactive.options != null)
                ...interactive.options!.map(
                  (option) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      option,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        );
      case InteractiveType.countdown:
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFF59E0B).withValues(alpha: 0.3),
                const Color(0xFFF97316).withValues(alpha: 0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFF59E0B), width: 2),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.timer, size: 48, color: Colors.white),
                const SizedBox(height: 12),
                Text(
                  interactive.label ?? '60',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'seconds',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),
        );
      default:
        return Container();
    }
  }
}
