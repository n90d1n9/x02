import 'package:flutter/material.dart';

/// Groups related document app-bar actions into a compact modern command cluster.
class DocumentActionCluster extends StatelessWidget {
  static const groupKeyPrefix = 'document-action-cluster';

  final String groupId;
  final String semanticLabel;
  final List<Widget> children;

  const DocumentActionCluster({
    super.key,
    required this.groupId,
    required this.semanticLabel,
    required this.children,
  });

  static Key groupKey(String groupId) {
    return ValueKey('$groupKeyPrefix-$groupId');
  }

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Semantics(
        container: true,
        label: semanticLabel,
        child: DecoratedBox(
          key: groupKey(groupId),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.58),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButtonTheme(
            data: IconButtonThemeData(
              style: IconButton.styleFrom(
                minimumSize: const Size.square(40),
                padding: const EdgeInsets.all(8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Row(mainAxisSize: MainAxisSize.min, children: children),
            ),
          ),
        ),
      ),
    );
  }
}
