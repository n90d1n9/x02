import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../models/enums.dart';
import 'editor_dialog_frame.dart';

/// Dialog for applying a visual effect to the selected component.
class VisualEffectsDialog extends StatelessWidget {
  final Color accentColor;
  final ValueChanged<VisualEffect> onEffectSelected;

  const VisualEffectsDialog({
    super.key,
    required this.accentColor,
    required this.onEffectSelected,
  });

  @override
  Widget build(BuildContext context) {
    return EditorDialogFrame(
      title: 'Visual Effects',
      icon: Icons.auto_awesome,
      accentColor: accentColor,
      width: 460,
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final choice in _effectChoices) ...[
                VisualEffectOptionTile(
                  choice: choice,
                  accentColor: accentColor,
                  onTap: () => onEffectSelected(choice.effect),
                ),
                if (choice != _effectChoices.last) const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.maybePop(context),
          style: TextButton.styleFrom(foregroundColor: Colors.white70),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

/// Selectable visual-effect option for the effects dialog.
class VisualEffectOptionTile extends StatelessWidget {
  final VisualEffectChoice choice;
  final Color accentColor;
  final VoidCallback onTap;

  const VisualEffectOptionTile({
    super.key,
    required this.choice,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: choice.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.045),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: choice.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: choice.color.withValues(alpha: 0.28),
                  ),
                ),
                child: Icon(choice.icon, color: choice.color, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      choice.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      choice.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                        height: 1.25,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward, color: accentColor, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// Metadata for a visual effect option shown in [VisualEffectsDialog].
class VisualEffectChoice {
  final VisualEffect effect;
  final IconData icon;
  final String label;
  final String description;
  final Color color;

  const VisualEffectChoice({
    required this.effect,
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
  });
}

const List<VisualEffectChoice> _effectChoices = [
  VisualEffectChoice(
    effect: VisualEffect.glassmorphism,
    icon: Icons.blur_on,
    label: 'Glassmorphism',
    description: 'Frosted depth with translucent surface blur.',
    color: Color(0xFF38BDF8),
  ),
  VisualEffectChoice(
    effect: VisualEffect.neumorphism,
    icon: Icons.layers,
    label: 'Neumorphism',
    description: 'Soft raised depth for tactile cards and controls.',
    color: Color(0xFFA78BFA),
  ),
  VisualEffectChoice(
    effect: VisualEffect.glow,
    icon: Icons.lightbulb,
    label: 'Glow',
    description: 'Subtle brand-colored highlight around the object.',
    color: Color(0xFFFACC15),
  ),
  VisualEffectChoice(
    effect: VisualEffect.neon,
    icon: Icons.flare,
    label: 'Neon',
    description: 'Bright cyber-style light treatment for emphasis.',
    color: Color(0xFFFB7185),
  ),
  VisualEffectChoice(
    effect: VisualEffect.gradient,
    icon: Icons.gradient,
    label: 'Gradient',
    description: 'Animated palette motion using the deck colors.',
    color: Color(0xFF22C55E),
  ),
];

@Preview(name: 'Visual effects dialog', size: Size(560, 560))
Widget visualEffectsDialogPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: VisualEffectsDialog(
          accentColor: const Color(0xFF38BDF8),
          onEffectSelected: (_) {},
        ),
      ),
    ),
  );
}

@Preview(name: 'Visual effect option tile', size: Size(500, 120))
Widget visualEffectOptionTilePreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: SizedBox(
          width: 440,
          child: VisualEffectOptionTile(
            choice: _effectChoices.first,
            accentColor: const Color(0xFF38BDF8),
            onTap: () {},
          ),
        ),
      ),
    ),
  );
}
