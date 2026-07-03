import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

/// Labeled switch row used by inspector panels for binary component settings.
class PropertyToggleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const PropertyToggleTile({
    super.key,
    required this.icon,
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: enabled ? Colors.white54 : Colors.white24, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: enabled ? Colors.white : Colors.white38,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: enabled ? Colors.white54 : Colors.white30,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          activeThumbColor: const Color(0xFF6366F1),
          onChanged: enabled ? onChanged : null,
        ),
      ],
    );
  }
}

@Preview(name: 'Property toggle tile', size: Size(320, 88))
Widget propertyToggleTilePreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: SizedBox(
          width: 280,
          child: PropertyToggleTile(
            icon: Icons.auto_awesome,
            label: 'Glow',
            description: 'Add a presentation-ready glow',
            value: true,
            onChanged: (_) {},
          ),
        ),
      ),
    ),
  );
}
