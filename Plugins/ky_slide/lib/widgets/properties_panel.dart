import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../states/component_provider.dart';
import 'component_properties_panel.dart';
import 'slide_properties_panel.dart';

class PropertiesPanel extends ConsumerWidget {
  const PropertiesPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(selectedComponentProvider);

    if (selectedId == null) {
      return const SlidePropertiesPanel();
    }

    return const ComponentPropertiesPanel();
  }
}
