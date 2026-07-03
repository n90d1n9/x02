import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../states/component_provider.dart';

class ZoomControls extends ConsumerWidget {
  const ZoomControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zoom = ref.watch(zoomLevelProvider);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, color: Colors.white70),
            iconSize: 20,
            onPressed: () {
              final newZoom = (zoom - 0.1).clamp(0.25, 3.0);
              ref.read(zoomLevelProvider.notifier).state = newZoom;
            },
          ),
          Text(
            '${(zoom * 100).toInt()}%',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white70),

            iconSize: 20,
            onPressed: () {
              final newZoom = (zoom + 0.1).clamp(0.25, 3.0);
              ref.read(zoomLevelProvider.notifier).state = newZoom;
            },
          ),
          IconButton(
            icon: const Icon(Icons.fit_screen, color: Colors.white70),
            iconSize: 20,
            tooltip: 'Fit to Screen',
            onPressed: () {
              ref.read(zoomLevelProvider.notifier).state = 1.0;
            },
          ),
        ],
      ),
    );
  }
}
