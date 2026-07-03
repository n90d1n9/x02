// Chart Widget Example
import 'package:flutter/material.dart';

class ChartWidget extends StatelessWidget {
  final String chartType;

  const ChartWidget({super.key, required this.chartType});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                _getChartIcon(chartType),
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '${chartType.split('_').last} Chart',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () {},
                tooltip: 'Edit Chart Data',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'Chart Preview',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getChartIcon(String type) {
    if (type.contains('bar')) return Icons.bar_chart;
    if (type.contains('line')) return Icons.show_chart;
    if (type.contains('pie')) return Icons.pie_chart;
    if (type.contains('area')) return Icons.area_chart;
    return Icons.insert_chart;
  }
}
