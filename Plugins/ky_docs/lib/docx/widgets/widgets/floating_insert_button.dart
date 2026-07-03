import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'widget_gallery_panel.dart';

class FloatingInsertButton extends ConsumerWidget {
  const FloatingInsertButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Positioned(
      right: 24,
      bottom: 80,
      child: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const WidgetGalleryPanel(),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Insert'),
        tooltip: 'Insert blocks and widgets',
      ),
    );
  }
}
