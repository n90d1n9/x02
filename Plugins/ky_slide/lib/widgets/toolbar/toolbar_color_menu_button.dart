import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

/// Compact color picker menu for contextual ribbon styling commands.
class ToolbarColorMenuButton extends StatelessWidget {
  static const Object _clearColorValue = Object();

  final IconData icon;
  final String tooltip;
  final String menuLabelPrefix;
  final List<Color> colors;
  final Color? selectedColor;
  final bool enabled;
  final bool compact;
  final ValueChanged<Color> onSelected;
  final VoidCallback? onCleared;
  final String? clearLabel;

  const ToolbarColorMenuButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.menuLabelPrefix,
    required this.colors,
    required this.selectedColor,
    required this.onSelected,
    this.onCleared,
    this.clearLabel,
    this.enabled = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final side = compact ? 40.0 : 48.0;
    final swatchColor = selectedColor ?? Colors.white38;

    return Semantics(
      button: true,
      enabled: enabled,
      label: tooltip,
      child: PopupMenuButton<Object>(
        enabled: enabled,
        tooltip: tooltip,
        color: const Color(0xFF1E293B),
        elevation: 12,
        offset: Offset(0, compact ? 36 : 42),
        padding: EdgeInsets.zero,
        onSelected: (value) {
          if (value == _clearColorValue) {
            onCleared?.call();
            return;
          }

          if (value is Color) onSelected(value);
        },
        itemBuilder: (context) => [
          if (onCleared != null)
            PopupMenuItem<Object>(
              value: _clearColorValue,
              child: Row(
                children: [
                  _ClearColorSwatch(selected: selectedColor == null),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      clearLabel ?? 'No $menuLabelPrefix',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          for (final color in _deduplicatedColors())
            PopupMenuItem<Object>(
              value: color,
              child: Row(
                children: [
                  _ColorSwatch(color: color, selected: color == selectedColor),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      '$menuLabelPrefix ${_labelFor(color)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
        icon: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          width: side,
          height: side,
          decoration: BoxDecoration(
            color: enabled
                ? Colors.white.withValues(alpha: 0.045)
                : Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: enabled
                  ? Colors.white.withValues(alpha: 0.09)
                  : Colors.white.withValues(alpha: 0.05),
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                icon,
                color: enabled ? Colors.white60 : Colors.white24,
                size: compact ? 19 : 21,
              ),
              Positioned(
                bottom: 7,
                child: Container(
                  width: compact ? 18 : 22,
                  height: 3,
                  decoration: BoxDecoration(
                    color: enabled
                        ? swatchColor
                        : swatchColor.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Color> _deduplicatedColors() {
    final seen = <int>{};
    final unique = <Color>[];

    for (final color in colors) {
      final value = color.toARGB32();
      if (seen.add(value)) unique.add(color);
    }

    return unique;
  }

  String _labelFor(Color color) {
    final value = color.toARGB32().toRadixString(16).padLeft(8, '0');
    return '#${value.substring(2).toUpperCase()}';
  }
}

/// Reset affordance used by optional clear-color popup rows.
class _ClearColorSwatch extends StatelessWidget {
  final bool selected;

  const _ClearColorSwatch({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? Colors.white : Colors.white.withValues(alpha: 0.25),
          width: selected ? 2 : 1,
        ),
      ),
      child: Icon(
        selected ? Icons.check : Icons.close,
        color: selected ? const Color(0xFF38BDF8) : Colors.white70,
        size: 12,
      ),
    );
  }
}

/// Small color preview used inside toolbar popup menu items.
class _ColorSwatch extends StatelessWidget {
  final Color color;
  final bool selected;

  const _ColorSwatch({required this.color, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? Colors.white : Colors.white.withValues(alpha: 0.25),
          width: selected ? 2 : 1,
        ),
      ),
    );
  }
}

@Preview(name: 'Toolbar color menu button', size: Size(120, 88))
Widget toolbarColorMenuButtonPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      body: Center(
        child: ToolbarColorMenuButton(
          icon: Icons.format_color_fill,
          tooltip: 'Fill Color',
          menuLabelPrefix: 'Fill',
          selectedColor: const Color(0xFF38BDF8),
          colors: const [Color(0xFF38BDF8), Color(0xFF14B8A6)],
          onSelected: (_) {},
        ),
      ),
    ),
  );
}
