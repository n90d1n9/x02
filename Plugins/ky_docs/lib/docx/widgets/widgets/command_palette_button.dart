import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../states/command_provider.dart';

class CommandPaletteButton extends ConsumerWidget {
  const CommandPaletteButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.search, size: 20),
      tooltip: 'Command Palette (⌘K)',
      onPressed: () {
        ref.read(commandPaletteProvider.notifier).state = true;
      },
    );
  }
}
