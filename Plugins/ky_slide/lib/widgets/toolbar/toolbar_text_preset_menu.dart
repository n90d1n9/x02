import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../models/text_style_preset.dart';
import 'ribbon_menu_button.dart';

/// Ribbon menu for applying theme-aware text style presets.
class ToolbarTextPresetMenu extends StatelessWidget {
  final bool enabled;
  final bool compact;
  final ValueChanged<TextStylePreset> onSelected;

  const ToolbarTextPresetMenu({
    super.key,
    required this.onSelected,
    this.enabled = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return RibbonMenuButton<TextStylePreset>(
      icon: Icons.style_outlined,
      tooltip: 'Text Presets',
      enabled: enabled,
      compact: compact,
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final preset in TextStylePreset.values)
          PopupMenuItem(
            value: preset,
            child: _TextPresetMenuRow(
              icon: _iconFor(preset),
              label: _labelFor(preset),
              sampleStyle: _sampleStyleFor(preset),
            ),
          ),
      ],
    );
  }

  IconData _iconFor(TextStylePreset preset) {
    return switch (preset) {
      TextStylePreset.title => Icons.title,
      TextStylePreset.subtitle => Icons.short_text,
      TextStylePreset.body => Icons.notes,
      TextStylePreset.caption => Icons.subtitles_outlined,
      TextStylePreset.quote => Icons.format_quote,
    };
  }

  String _labelFor(TextStylePreset preset) {
    return switch (preset) {
      TextStylePreset.title => 'Title',
      TextStylePreset.subtitle => 'Subtitle',
      TextStylePreset.body => 'Body',
      TextStylePreset.caption => 'Caption',
      TextStylePreset.quote => 'Quote',
    };
  }

  TextStyle _sampleStyleFor(TextStylePreset preset) {
    return switch (preset) {
      TextStylePreset.title => const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w800,
      ),
      TextStylePreset.subtitle => const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      TextStylePreset.body => const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      TextStylePreset.caption => const TextStyle(
        color: Colors.white70,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      TextStylePreset.quote => const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w600,
      ),
    };
  }
}

/// Popup menu row that previews the typography intent of a text preset.
class _TextPresetMenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextStyle sampleStyle;

  const _TextPresetMenuRow({
    required this.icon,
    required this.label,
    required this.sampleStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 10),
        Text(label, style: sampleStyle),
      ],
    );
  }
}

@Preview(name: 'Toolbar text preset menu', size: Size(120, 88))
Widget toolbarTextPresetMenuPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      body: Center(child: ToolbarTextPresetMenu(onSelected: (_) {})),
    ),
  );
}
