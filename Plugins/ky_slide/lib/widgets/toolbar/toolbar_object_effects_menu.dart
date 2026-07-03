import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import 'ribbon_menu_button.dart';

/// Ribbon menu for lightweight selected-object visual effects.
class ToolbarObjectEffectsMenu extends StatelessWidget {
  final bool hasGlow;
  final Color? selectedGlowColor;
  final List<Color> colors;
  final bool enabled;
  final bool compact;
  final ValueChanged<bool> onGlowEnabledChanged;
  final ValueChanged<Color> onGlowColorSelected;

  const ToolbarObjectEffectsMenu({
    super.key,
    required this.hasGlow,
    required this.selectedGlowColor,
    required this.colors,
    required this.onGlowEnabledChanged,
    required this.onGlowColorSelected,
    this.enabled = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return RibbonMenuButton<_GlowEffectCommand>(
      icon: hasGlow ? Icons.auto_awesome : Icons.auto_awesome_outlined,
      tooltip: 'Effects',
      enabled: enabled,
      compact: compact,
      onSelected: _handleSelected,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: const _GlowEffectCommand.disabled(),
          child: _EffectMenuRow(
            icon: Icons.block,
            label: 'No Glow',
            selected: !hasGlow,
          ),
        ),
        PopupMenuItem(
          value: const _GlowEffectCommand.enabled(),
          child: _EffectMenuRow(
            icon: Icons.auto_awesome,
            label: 'Glow On',
            selected: hasGlow,
          ),
        ),
        const PopupMenuDivider(height: 8),
        for (final color in _colorChoices())
          PopupMenuItem(
            value: _GlowEffectCommand.color(color),
            child: _GlowColorMenuRow(
              color: color,
              label: 'Glow ${_labelFor(color)}',
              selected: hasGlow && selectedGlowColor == color,
            ),
          ),
      ],
    );
  }

  void _handleSelected(_GlowEffectCommand command) {
    switch (command.type) {
      case _GlowEffectCommandType.disabled:
        onGlowEnabledChanged(false);
        break;
      case _GlowEffectCommandType.enabled:
        onGlowEnabledChanged(true);
        break;
      case _GlowEffectCommandType.color:
        final color = command.color;
        if (color != null) onGlowColorSelected(color);
        break;
    }
  }

  List<Color> _colorChoices() {
    final seeded = <Color>[
      ?selectedGlowColor,
      ...colors,
      const Color(0xFFFFFFFF),
      const Color(0xFF0F172A),
      const Color(0xFFF59E0B),
    ];

    final seen = <int>{};
    return [
      for (final color in seeded)
        if (seen.add(color.toARGB32())) color,
    ].take(8).toList();
  }

  String _labelFor(Color color) {
    final rgb = color.toARGB32() & 0x00FFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }
}

enum _GlowEffectCommandType { disabled, enabled, color }

class _GlowEffectCommand {
  final _GlowEffectCommandType type;
  final Color? color;

  const _GlowEffectCommand._({required this.type, this.color});

  const _GlowEffectCommand.disabled()
    : this._(type: _GlowEffectCommandType.disabled);

  const _GlowEffectCommand.enabled()
    : this._(type: _GlowEffectCommandType.enabled);

  const _GlowEffectCommand.color(Color color)
    : this._(type: _GlowEffectCommandType.color, color: color);
}

/// Popup row for effect on/off commands.
class _EffectMenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;

  const _EffectMenuRow({
    required this.icon,
    required this.label,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          selected ? Icons.check_circle : icon,
          color: selected ? const Color(0xFF38BDF8) : Colors.white70,
          size: 18,
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// Popup row for picking the selected object's glow color.
class _GlowColorMenuRow extends StatelessWidget {
  final Color color;
  final String label;
  final bool selected;

  const _GlowColorMenuRow({
    required this.color,
    required this.label,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.25),
              width: selected ? 2 : 1,
            ),
          ),
          child: selected
              ? const Icon(Icons.check, size: 12, color: Colors.white)
              : null,
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

@Preview(name: 'Toolbar object effects menu', size: Size(120, 88))
Widget toolbarObjectEffectsMenuPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      body: Center(
        child: ToolbarObjectEffectsMenu(
          hasGlow: true,
          selectedGlowColor: const Color(0xFF38BDF8),
          colors: const [Color(0xFF38BDF8), Color(0xFF14B8A6)],
          onGlowEnabledChanged: (_) {},
          onGlowColorSelected: (_) {},
        ),
      ),
    ),
  );
}
