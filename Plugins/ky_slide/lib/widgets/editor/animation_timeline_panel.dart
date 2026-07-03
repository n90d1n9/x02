import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/animation.dart';
import '../../services/animation_timeline_service.dart';
import '../animations/animation_icon.dart';

/// Animation Timeline Panel Widget
/// Similar to PowerPoint's Animation Pane and Google Slides' Motion panel
class AnimationTimelinePanel extends ConsumerStatefulWidget {
  final String slideId;

  const AnimationTimelinePanel({
    super.key,
    required this.slideId,
  });

  @override
  ConsumerState<AnimationTimelinePanel> createState() =>
      _AnimationTimelinePanelState();
}

class _AnimationTimelinePanelState extends ConsumerState<AnimationTimelinePanel> {
  late AnimationTimelineService _timelineService;
  final ScrollController _scrollController = ScrollController();
  bool _showDetails = true;

  @override
  void initState() {
    super.initState();
    _timelineService = AnimationTimelineService();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _timelineService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _timelineService,
      builder: (context, _) {
        return Container(
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            children: [
              _buildHeader(),
              _buildToolbar(),
              Expanded(child: _buildTimeline()),
              _buildFooter(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.animation,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            'Animation Timeline',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              _showDetails ? Icons.visibility_off : Icons.visibility,
              size: 18,
            ),
            onPressed: () => setState(() => _showDetails = !_showDetails),
            tooltip: 'Toggle Details',
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 18),
            onPressed: () => _showAddAnimationDialog(),
            tooltip: 'Add Animation',
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          _buildPlaybackButton(),
          const SizedBox(width: 8),
          _buildZoomSlider(),
          const Spacer(),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 18),
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'copy',
                child: ListTile(
                  leading: Icon(Icons.copy, size: 18),
                  title: Text('Copy Animations'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'paste',
                child: ListTile(
                  leading: Icon(Icons.paste, size: 18),
                  title: Text('Paste Animations'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: ListTile(
                  leading: Icon(Icons.delete_sweep, size: 18),
                  title: Text('Clear All'),
                  dense: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaybackButton() {
    final isPlaying = _timelineService.isPlaying;

    return ElevatedButton.icon(
      onPressed: isPlaying
          ? () => _timelineService.stopPreview()
          : () => _timelineService.playPreview(widget.slideId, () {
                // Trigger animation preview on canvas
                debugPrint('Animating...');
              }),
      icon: Icon(
        isPlaying ? Icons.stop : Icons.play_arrow,
        size: 16,
      ),
      label: Text(isPlaying ? 'Stop' : 'Preview'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildZoomSlider() {
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.zoom_out, size: 14),
          Expanded(
            child: Slider(
              value: _timelineService.timelineZoom,
              min: 0.5,
              max: 4.0,
              divisions: 7,
              onChanged: (value) => _timelineService.setTimelineZoom(value),
            ),
          ),
          const Icon(Icons.zoom_in, size: 14),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    final animations = _timelineService.getAnimationsForSlide(widget.slideId);

    if (animations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.animation_outlined,
              size: 48,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No animations yet',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).disabledColor,
                  ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _showAddAnimationDialog(),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Animation'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: animations.length,
      itemBuilder: (context, index) {
        final animation = animations[index];
        final isSelected = _timelineService.selectedAnimationId == animation.id;
        final isCurrent = _timelineService.currentAnimationIndex == index;
        final category = AnimationCategory.fromEffect(animation.effect);

        return _buildAnimationTile(
          animation: animation,
          index: index,
          isSelected: isSelected,
          isCurrent: isCurrent,
          category: category,
        );
      },
    );
  }

  Widget _buildAnimationTile({
    required ElementAnimation animation,
    required int index,
    required bool isSelected,
    required bool isCurrent,
    required AnimationCategory category,
  }) {
    final durationText =
        '${(animation.duration.inMilliseconds / 1000).toStringAsFixed(1)}s';
    final delayText = animation.delay > Duration.zero
        ? '+${(animation.delay.inMilliseconds / 1000).toStringAsFixed(1)}s'
        : '';

    return Dismissible(
      key: Key(animation.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) =>
          _timelineService.removeAnimation(widget.slideId, animation.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: isCurrent
              ? category.color.withOpacity(0.2)
              : isSelected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                )
              : null,
        ),
        child: Column(
          children: [
            ListTile(
              dense: true,
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: category.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  _getAnimationIcon(animation.effect),
                  color: category.color,
                  size: 18,
                ),
              ),
              title: Text(
                _getAnimationLabel(animation.effect),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
              ),
              subtitle: Text(
                'Target: ${animation.targetId.substring(0, 8)}...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (delayText.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        delayText,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: category.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      durationText,
                      style: TextStyle(
                        color: category.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 16),
                    onSelected: (value) =>
                        _handleAnimationMenu(value, animation),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit, size: 16),
                          title: Text('Edit'),
                          dense: true,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'duplicate',
                        child: ListTile(
                          leading: Icon(Icons.copy, size: 16),
                          title: Text('Duplicate'),
                          dense: true,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, size: 16),
                          title: Text('Delete'),
                          dense: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              onTap: () => _timelineService.selectAnimation(animation.id),
              onLongPress: () => _showEditAnimationDialog(animation),
            ),
            if (_showDetails) ...[
              Container(
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: category.color.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 4),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            '${_timelineService.getAnimationsForSlide(widget.slideId).length} animations',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const Spacer(),
          if (_timelineService.totalDuration > 0)
            Text(
              'Total: ${(_timelineService.totalDuration / 1000).toStringAsFixed(1)}s',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
        ],
      ),
    );
  }

  IconData _getAnimationIcon(AnimationEffect effect) {
    switch (effect) {
      case AnimationEffect.fadeIn:
      case AnimationEffect.fadeOut:
        return Icons.opacity;
      case AnimationEffect.flyInFromLeft:
      case AnimationEffect.flyOutToLeft:
        return Icons.arrow_back;
      case AnimationEffect.flyInFromRight:
      case AnimationEffect.flyOutToRight:
        return Icons.arrow_forward;
      case AnimationEffect.flyInFromTop:
      case AnimationEffect.flyOutToTop:
        return Icons.arrow_upward;
      case AnimationEffect.flyInFromBottom:
      case AnimationEffect.flyOutToBottom:
        return Icons.arrow_downward;
      case AnimationEffect.zoomIn:
      case AnimationEffect.zoomOut:
        return Icons.zoom_in_map;
      case AnimationEffect.bounceIn:
      case AnimationEffect.bounceOut:
        return Icons.bouncing_ball;
      case AnimationEffect.pulse:
        return Icons.flash_on;
      case AnimationEffect.spin:
        return Icons.refresh;
      case AnimationEffect.wobble:
        return Icons.waves;
      case AnimationEffect.growShrink:
        return Icons.expand;
      case AnimationEffect.colorPulse:
        return Icons.palette;
      case AnimationEffect.motionPathLine:
      case AnimationEffect.motionPathArc:
      case AnimationEffect.motionPathLoop:
        return Icons.draw;
    }
  }

  String _getAnimationLabel(AnimationEffect effect) {
    return effect.name.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (m) => ' ${m.group(0)}',
    ).trim();
  }

  void _showAddAnimationDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddAnimationDialog(
        slideId: widget.slideId,
        timelineService: _timelineService,
      ),
    );
  }

  void _showEditAnimationDialog(ElementAnimation animation) {
    showDialog(
      context: context,
      builder: (context) => _EditAnimationDialog(
        animation: animation,
        slideId: widget.slideId,
        timelineService: _timelineService,
      ),
    );
  }

  void _handleAnimationMenu(String value, ElementAnimation animation) {
    switch (value) {
      case 'edit':
        _showEditAnimationDialog(animation);
        break;
      case 'duplicate':
        _timelineService.updateAnimation(
          slideId: widget.slideId,
          animationId: animation.id,
          order: _timelineService.getAnimationsForSlide(widget.slideId).indexOf(animation) + 1,
        );
        break;
      case 'delete':
        _timelineService.removeAnimation(widget.slideId, animation.id);
        break;
    }
  }

  void _handleMenuAction(String value) {
    switch (value) {
      case 'copy':
        // Copy animations to clipboard
        debugPrint('Copy animations');
        break;
      case 'paste':
        // Paste animations from clipboard
        debugPrint('Paste animations');
        break;
      case 'clear':
        _timelineService.clearSlideAnimations(widget.slideId);
        break;
    }
  }
}

/// Dialog for adding new animation
class _AddAnimationDialog extends StatefulWidget {
  final String slideId;
  final AnimationTimelineService timelineService;

  const _AddAnimationDialog({
    required this.slideId,
    required this.timelineService,
  });

  @override
  State<_AddAnimationDialog> createState() => _AddAnimationDialogState();
}

class _AddAnimationDialogState extends State<_AddAnimationDialog> {
  AnimationEffect _selectedEffect = AnimationEffect.fadeIn;
  AnimationTrigger _trigger = AnimationTrigger.onClick;
  Duration _duration = const Duration(milliseconds: 500);
  Duration _delay = Duration.zero;
  Easing _easing = Easing.easeInOut;
  String? _targetComponentId;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Animation'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<AnimationEffect>(
              value: _selectedEffect,
              decoration: const InputDecoration(labelText: 'Effect'),
              items: AnimationEffect.values.map((e) {
                return DropdownMenuItem(
                  value: e,
                  child: Text(e.name.replaceAllMapped(
                    RegExp(r'[A-Z]'),
                    (m) => ' ${m.group(0)}',
                  ).trim()),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedEffect = v!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<AnimationTrigger>(
              value: _trigger,
              decoration: const InputDecoration(labelText: 'Trigger'),
              items: AnimationTrigger.values.map((t) {
                return DropdownMenuItem(
                  value: t,
                  child: Text(t.name.replaceAll('_', ' ').capitalize()),
                );
              }).toList(),
              onChanged: (v) => setState(() => _trigger = v!),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Duration (ms)',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      final ms = int.tryParse(v) ?? 500;
                      setState(() => _duration = Duration(milliseconds: ms));
                    },
                    controller: TextEditingController(
                      text: _duration.inMilliseconds.toString(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Delay (ms)',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      final ms = int.tryParse(v) ?? 0;
                      setState(() => _delay = Duration(milliseconds: ms));
                    },
                    controller: TextEditingController(
                      text: _delay.inMilliseconds.toString(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_targetComponentId != null) {
              widget.timelineService.addAnimation(
                slideId: widget.slideId,
                targetComponentId: _targetComponentId!,
                effect: _selectedEffect,
                trigger: _trigger,
                duration: _duration,
                delay: _delay,
                easing: _easing,
              );
            }
            Navigator.pop(context);
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

/// Dialog for editing existing animation
class _EditAnimationDialog extends StatefulWidget {
  final ElementAnimation animation;
  final String slideId;
  final AnimationTimelineService timelineService;

  const _EditAnimationDialog({
    required this.animation,
    required this.slideId,
    required this.timelineService,
  });

  @override
  State<_EditAnimationDialog> createState() => _EditAnimationDialogState();
}

class _EditAnimationDialogState extends State<_EditAnimationDialog> {
  late AnimationEffect _effect;
  late AnimationTrigger _trigger;
  late Duration _duration;
  late Duration _delay;
  late Easing _easing;

  @override
  void initState() {
    super.initState();
    _effect = widget.animation.effect;
    _trigger = widget.animation.trigger;
    _duration = widget.animation.duration;
    _delay = widget.animation.delay;
    _easing = widget.animation.easing;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Animation'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Similar fields as Add dialog but pre-populated
            Text('Editing: ${_effect.name}'),
            const SizedBox(height: 16),
            // ... add editing controls
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.timelineService.updateAnimation(
              slideId: widget.slideId,
              animationId: widget.animation.id,
              effect: _effect,
              trigger: _trigger,
              duration: _duration,
              delay: _delay,
              easing: _easing,
            );
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

extension on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
