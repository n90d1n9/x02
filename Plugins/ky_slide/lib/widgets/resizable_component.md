
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/component.dart';
import '../models/enums.dart';
import '../models/presentation_component.dart';
import '../models/style/presentation_theme.dart';
import '../states/component_provider.dart';
import '../states/history_provider.dart';
import '../states/presentation_provider.dart';
import 'simple_chart_widget.dart';
import 'triangle_painter.dart';

class ResizableComponent extends ConsumerStatefulWidget {
  final PresentationComponent component;

  const ResizableComponent({super.key, required this.component});

  @override
  ConsumerState<ResizableComponent> createState() => _ResizableComponentState();
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

  Widget _buildRotateHandle() {
    return Positioned(
      top: -40,
      left: widget.component.size.width / 2 - 15,
      child: GestureDetector(
        onPanStart: (details) {
          rotationStart = widget.component.rotation;
        },
        onPanUpdate: (details) {
          if (rotationStart == null) return;

          final center = Offset(
            widget.component.size.width / 2,
            widget.component.size.height / 2 + 40,
          );

          final angle = math.atan2(
            details.localPosition.dy - center.dy,
            details.localPosition.dx - center.dx,
          );

          final rotation = (angle * 180 / math.pi) + 90;

          ref.read(presentationProvider.notifier).updateComponent(
            widget.component.id,
            widget.component.copyWith(rotation: rotation),
          );
        },
        onPanEnd: (_) {
          rotationStart = null;
          ref.read(historyProvider.notifier).addState(ref.read(presentationProvider));
        },
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
              ),
            ],
          ),
          child: const Icon(Icons.refresh, color: Colors.white, size: 18),
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
            },onSubmitted: (_) {
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
      case ComponentType.audio:
        // TODO: Handle this case.
        throw UnimplementedError();
      case ComponentType.icon:
        // TODO: Handle this case.
        throw UnimplementedError();
      case ComponentType.gif:
        // TODO: Handle this case.
        throw UnimplementedError();
      case ComponentType.hotspot:
        // TODO: Handle this case.
        throw UnimplementedError();
      case ComponentType.poll:
        // TODO: Handle this case.
        throw UnimplementedError();
      case ComponentType.quiz:
        // TODO: Handle this case.
        throw UnimplementedError();
      case ComponentType.countdown:
        // TODO: Handle this case.
        throw UnimplementedError();
      case ComponentType.progressBar:
        // TODO: Handle this case.
        throw UnimplementedError();
      case ComponentType.lottie:
        // TODO: Handle this case.
        throw UnimplementedError();
      case ComponentType.particles:
        // TODO: Handle this case.
        throw UnimplementedError();
      case ComponentType.gradient:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }
           
           
           
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