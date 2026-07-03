import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../states/inline_button.dart';
import 'widget_gallery_panel.dart';

class InlineActionButtons extends ConsumerWidget {
  const InlineActionButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showButtons = ref.watch(showInlineButtonsProvider);
    final position = ref.watch(inlineButtonPositionProvider);

    if (!showButtons) return const SizedBox.shrink();

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 200),
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.scale(scale: 0.8 + (0.2 * value), child: child),
          );
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Insert button (+)
            _InlineButton(
              icon: Icons.add,
              tooltip: 'Insert block',
              color: Theme.of(context).colorScheme.primary,
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const WidgetGalleryPanel(),
                );
              },
            ),
            const SizedBox(width: 8),
            // Chat button
            _InlineButton(
              icon: Icons.chat_bubble_outline,
              tooltip: 'AI Assistant',
              color: Colors.purple,
              onPressed: () {
                ref.read(chatPanelProvider.notifier).state = true;
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onPressed;

  const _InlineButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onPressed,
  });

  @override
  State<_InlineButton> createState() => _InlineButtonState();
}

class _InlineButtonState extends State<_InlineButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Tooltip(
        message: widget.tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _isHovered
                    ? widget.color.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isHovered ? widget.color : Colors.grey.shade300,
                  width: _isHovered ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                widget.icon,
                size: 18,
                color: _isHovered ? widget.color : Colors.grey.shade700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
