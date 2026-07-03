import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/slide_transition.dart';
import '../services/slide_transition_service.dart';

/// A visual gallery widget for selecting slide transitions.
/// Displays a grid of cards, each representing a transition type with a live preview.
class TransitionGallery extends ConsumerStatefulWidget {
  final Function(TransitionType) onTransitionSelected;
  final TransitionType? selectedType;

  const TransitionGallery({
    super.key,
    required this.onTransitionSelected,
    this.selectedType,
  });

  @override
  ConsumerState<TransitionGallery> createState() => _TransitionGalleryState();
}

class _TransitionGalleryState extends ConsumerState<TransitionGallery> {
  TransitionType? _hoveredType;

  @override
  Widget build(BuildContext context) {
    final service = ref.read(slideTransitionServiceProvider);
    final types = service.getAvailableTypes();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Transitions',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(8.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // 3 columns like PowerPoint
              childAspectRatio: 0.85,
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
            ),
            itemCount: types.length,
            itemBuilder: (context, index) {
              final type = types[index];
              final isSelected = widget.selectedType == type;
              final isHovered = _hoveredType == type;

              return _TransitionCard(
                type: type,
                isSelected: isSelected,
                isHovered: isHovered,
                onHover: (hovering) {
                  setState(() {
                    _hoveredType = hovering ? type : null;
                  });
                },
                onTap: () {
                  widget.onTransitionSelected(type);
                },
                isPreviewActive: isHovered || isSelected,
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Individual card for a transition type in the gallery.
class _TransitionCard extends StatefulWidget {
  final TransitionType type;
  final bool isSelected;
  final bool isHovered;
  final Function(bool) onHover;
  final VoidCallback onTap;
  final bool isPreviewActive;

  const _TransitionCard({
    required this.type,
    required this.isSelected,
    required this.isHovered,
    required this.onHover,
    required this.onTap,
    required this.isPreviewActive,
  });

  @override
  State<_TransitionCard> createState() => _TransitionCardState();
}

class _TransitionCardState extends State<_TransitionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: TransitionPreviewGenerator.getCurveForType(widget.type),
    );

    if (widget.isPreviewActive) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_TransitionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPreviewActive && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isPreviewActive && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => widget.onHover(true),
      onExit: (_) => widget.onHover(false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? Theme.of(context).primaryColor.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: widget.isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade300,
                  width: widget.isSelected ? 2.0 : 1.0,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Center(
                      child: _buildPreviewWidget(_animation.value),
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    widget.type.displayName,
                    style: TextStyle(
                      fontSize: 12.0,
                      fontWeight:
                          widget.isSelected ? FontWeight.bold : FontWeight.normal,
                      color: widget.isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Builds the dynamic preview animation based on the transition type.
  Widget _buildPreviewWidget(double value) {
    switch (widget.type) {
      case TransitionType.fade:
        return Opacity(
          opacity: value,
          child: const Icon(Icons.visibility, size: 32),
        );
      case TransitionType.push:
        return Transform.translate(
          offset: Offset(-30 * (1 - value), 0),
          child: const Icon(Icons.arrow_forward, size: 32),
        );
      case TransitionType.wipe:
        return ClipRect(
          child: Align(
            alignment: Alignment.centerLeft,
            heightFactor: 1.0,
            widthFactor: value,
            child: const Icon(Icons.drag_handle, size: 32),
          ),
        );
      case TransitionType.zoom:
        return Transform.scale(
          scale: 0.5 + (0.5 * value),
          child: const Icon(Icons.zoom_in, size: 32),
        );
      case TransitionType.flip:
        return Transform.rotate(
          angle: 3.14159 * (1 - value),
          child: const Icon(Icons.flip, size: 32),
        );
      case TransitionType.morph:
        return Transform.scale(
          scale: 1.0 + (0.2 * (value - 0.5)),
          child: const Icon(Icons.auto_awesome, size: 32),
        );
      default:
        return Icon(widget.type.icon, size: 32);
    }
  }
}
