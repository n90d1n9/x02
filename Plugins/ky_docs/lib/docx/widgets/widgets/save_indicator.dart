import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../states/docs_provider.dart';

class SaveIndicator extends ConsumerWidget {
  const SaveIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docState = ref.watch(documentControllerProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Center(
        child: Row(
          children: [
            Icon(
              docState.isSaved ? Icons.cloud_done : Icons.sync,
              size: 18,
              color: docState.isSaved ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 6),
            Text(
              docState.isSaved ? 'Saved' : 'Saving...',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
