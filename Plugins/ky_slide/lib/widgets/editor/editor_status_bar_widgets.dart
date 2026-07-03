import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../services/editor_zoom_service.dart';

/// Single-line metadata text used in the editor status bar.
class EditorStatusText extends StatelessWidget {
  final String text;
  final Color color;
  final FontWeight fontWeight;

  const EditorStatusText(
    this.text, {
    super.key,
    this.color = Colors.white60,
    this.fontWeight = FontWeight.w500,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: color,
        fontSize: 12,
        fontWeight: fontWeight,
        letterSpacing: 0,
      ),
    );
  }
}

/// Thin separator for compact groups in the editor status bar.
class EditorStatusDivider extends StatelessWidget {
  const EditorStatusDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 16,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: Colors.white.withValues(alpha: 0.08),
    );
  }
}

/// Soft container for related status bar controls.
class EditorStatusControlGroup extends StatelessWidget {
  final List<Widget> children;

  const EditorStatusControlGroup({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

/// Toggle command for ruler, grid, and notes visibility.
class EditorStatusToggleButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final bool isActive;
  final VoidCallback onPressed;

  const EditorStatusToggleButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.isActive,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? const Color(0xFF6366F1) : Colors.white38;

    return IconButton(
      tooltip: tooltip,
      icon: Icon(icon, size: 16),
      color: color,
      hoverColor: color.withValues(alpha: 0.12),
      highlightColor: color.withValues(alpha: 0.14),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 28, height: 28),
      style: IconButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
      ),
      onPressed: onPressed,
    );
  }
}

/// Icon command for zoom controls in the editor status bar.
class EditorZoomButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  const EditorZoomButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      icon: Icon(icon, size: 16),
      color: Colors.white60,
      hoverColor: Colors.white.withValues(alpha: 0.08),
      highlightColor: Colors.white.withValues(alpha: 0.1),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 28, height: 28),
      style: IconButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
      ),
      onPressed: onPressed,
    );
  }
}

/// Compact, presentation-editor zoom slider for precise canvas scale changes.
class EditorZoomSlider extends StatelessWidget {
  final double zoom;
  final double minZoom;
  final double maxZoom;
  final ValueChanged<double> onChanged;

  const EditorZoomSlider({
    super.key,
    required this.zoom,
    this.minZoom = EditorZoomService.minZoom,
    this.maxZoom = EditorZoomService.maxZoom,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final clampedZoom = zoom.clamp(minZoom, maxZoom).toDouble();

    return Tooltip(
      message: 'Zoom slider',
      child: Semantics(
        label: 'Zoom level',
        value: _zoomLabel(clampedZoom),
        child: SizedBox(
          width: 104,
          height: 28,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2.5,
              activeTrackColor: const Color(0xFF38BDF8),
              inactiveTrackColor: Colors.white.withValues(alpha: 0.16),
              thumbColor: const Color(0xFFFFFFFF),
              overlayColor: const Color(0xFF38BDF8).withValues(alpha: 0.16),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            ),
            child: Slider(
              key: const ValueKey('editor-zoom-slider'),
              min: minZoom,
              max: maxZoom,
              divisions: 55,
              value: clampedZoom,
              label: _zoomLabel(clampedZoom),
              semanticFormatterCallback: _zoomLabel,
              onChanged: onChanged,
            ),
          ),
        ),
      ),
    );
  }

  String _zoomLabel(double value) => EditorZoomService.label(value);
}

/// Preset zoom option shown in the editor status bar zoom menu.
class EditorZoomPreset {
  final String label;
  final double value;

  const EditorZoomPreset({required this.label, required this.value});

  static const List<EditorZoomPreset> defaults = [
    EditorZoomPreset(label: '50%', value: 0.5),
    EditorZoomPreset(label: '75%', value: 0.75),
    EditorZoomPreset(label: '100%', value: 1),
    EditorZoomPreset(label: '125%', value: 1.25),
    EditorZoomPreset(label: '150%', value: 1.5),
    EditorZoomPreset(label: '200%', value: 2),
  ];
}

/// Fixed-width zoom percentage readout for stable status-bar layout.
class EditorZoomIndicator extends StatelessWidget {
  final double zoom;
  final bool showMenuIndicator;

  const EditorZoomIndicator({
    super.key,
    required this.zoom,
    this.showMenuIndicator = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: showMenuIndicator ? 58 : 48,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              EditorZoomService.label(zoom),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ),
          if (showMenuIndicator) ...[
            const SizedBox(width: 2),
            const Icon(Icons.expand_less, size: 13, color: Colors.white54),
          ],
        ],
      ),
    );
  }
}

/// Clickable zoom readout that exposes common presentation-editor zoom presets.
class EditorZoomPresetMenu extends StatelessWidget {
  final double zoom;
  final List<EditorZoomPreset> presets;
  final ValueChanged<double> onZoomSelected;
  final VoidCallback? onFitToWindow;

  const EditorZoomPresetMenu({
    super.key,
    required this.zoom,
    this.presets = EditorZoomPreset.defaults,
    required this.onZoomSelected,
    this.onFitToWindow,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_EditorZoomMenuSelection>(
      tooltip: 'Zoom presets',
      color: const Color(0xFF111827),
      elevation: 10,
      offset: const Offset(0, -8),
      onSelected: (selection) {
        if (selection.fitToWindow) {
          onFitToWindow?.call();
          return;
        }

        onZoomSelected(selection.zoom);
      },
      itemBuilder: (context) {
        return [
          if (onFitToWindow != null) ...[
            const PopupMenuItem<_EditorZoomMenuSelection>(
              value: _EditorZoomMenuSelection.fitToWindow(),
              child: _EditorZoomFitMenuItem(),
            ),
            const PopupMenuDivider(height: 1),
          ],
          ...presets.map((preset) {
            return PopupMenuItem<_EditorZoomMenuSelection>(
              value: _EditorZoomMenuSelection.zoom(preset.value),
              child: _EditorZoomPresetMenuItem(
                preset: preset,
                isSelected: _isSelected(preset.value),
              ),
            );
          }),
        ];
      },
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(7),
        child: Ink(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(7)),
          child: InkWell(
            borderRadius: BorderRadius.circular(7),
            child: SizedBox(
              height: 28,
              child: EditorZoomIndicator(zoom: zoom, showMenuIndicator: true),
            ),
          ),
        ),
      ),
    );
  }

  bool _isSelected(double value) => (zoom - value).abs() < 0.005;
}

/// Internal menu selection for zoom percentage or fit-to-window commands.
class _EditorZoomMenuSelection {
  final double zoom;
  final bool fitToWindow;

  const _EditorZoomMenuSelection.zoom(this.zoom) : fitToWindow = false;

  const _EditorZoomMenuSelection.fitToWindow() : zoom = 1, fitToWindow = true;
}

/// Single selectable row for fitting the slide to the visible canvas viewport.
class _EditorZoomFitMenuItem extends StatelessWidget {
  const _EditorZoomFitMenuItem();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 128,
      child: Row(
        children: [
          Icon(Icons.fit_screen, size: 16, color: Color(0xFF38BDF8)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Fit to window',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Single selectable row in the editor zoom preset popup.
class _EditorZoomPresetMenuItem extends StatelessWidget {
  final EditorZoomPreset preset;
  final bool isSelected;

  const _EditorZoomPresetMenuItem({
    required this.preset,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      child: Row(
        children: [
          Icon(
            isSelected ? Icons.check : Icons.zoom_out_map,
            size: 16,
            color: isSelected ? const Color(0xFF6366F1) : Colors.white38,
          ),
          const SizedBox(width: 10),
          Text(
            preset.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

@Preview(name: 'Editor status text', size: Size(240, 70))
Widget editorStatusTextPreview() {
  return const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: Color(0xFF0F172A),
      body: Center(child: EditorStatusText('Selected: Hero title')),
    ),
  );
}

@Preview(name: 'Editor status controls', size: Size(320, 80))
Widget editorStatusControlsPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            EditorStatusControlGroup(
              children: [
                EditorStatusToggleButton(
                  tooltip: 'Toggle ruler',
                  icon: Icons.straighten,
                  isActive: true,
                  onPressed: () {},
                ),
                EditorStatusToggleButton(
                  tooltip: 'Toggle grid',
                  icon: Icons.grid_on,
                  isActive: false,
                  onPressed: () {},
                ),
                EditorStatusToggleButton(
                  tooltip: 'Toggle snap to grid',
                  icon: Icons.center_focus_strong,
                  isActive: true,
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(width: 8),
            EditorStatusControlGroup(
              children: [
                EditorZoomButton(
                  tooltip: 'Zoom out',
                  icon: Icons.remove,
                  onPressed: () {},
                ),
                EditorZoomPresetMenu(zoom: 1, onZoomSelected: (_) {}),
                EditorZoomSlider(zoom: 1, onChanged: (_) {}),
                EditorZoomButton(
                  tooltip: 'Zoom in',
                  icon: Icons.add,
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

@Preview(name: 'Editor zoom slider', size: Size(260, 80))
Widget editorZoomSliderPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: EditorStatusControlGroup(
          children: [
            EditorZoomButton(
              tooltip: 'Zoom out',
              icon: Icons.remove,
              onPressed: () {},
            ),
            EditorZoomSlider(zoom: 1.25, onChanged: (_) {}),
            EditorZoomButton(
              tooltip: 'Zoom in',
              icon: Icons.add,
              onPressed: () {},
            ),
          ],
        ),
      ),
    ),
  );
}
