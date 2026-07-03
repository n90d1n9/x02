enum SlideTemplateType { executiveCover, agenda, metricStory, comparison }

enum SlideTemplateCategory { cover, structure, metrics, decision }

extension SlideTemplateCategoryLabel on SlideTemplateCategory {
  String get label {
    switch (this) {
      case SlideTemplateCategory.cover:
        return 'Cover';
      case SlideTemplateCategory.structure:
        return 'Flow';
      case SlideTemplateCategory.metrics:
        return 'Metrics';
      case SlideTemplateCategory.decision:
        return 'Decision';
    }
  }
}

class SlideTemplateTextItem {
  final String label;
  final String title;
  final String body;

  const SlideTemplateTextItem({
    required this.label,
    required this.title,
    required this.body,
  });

  SlideTemplateTextItem copyWith({String? label, String? title, String? body}) {
    return SlideTemplateTextItem(
      label: label ?? this.label,
      title: title ?? this.title,
      body: body ?? this.body,
    );
  }
}

class SlideTemplateMetric {
  final String label;
  final String value;
  final String trend;

  const SlideTemplateMetric({
    required this.label,
    required this.value,
    required this.trend,
  });

  SlideTemplateMetric copyWith({String? label, String? value, String? trend}) {
    return SlideTemplateMetric(
      label: label ?? this.label,
      value: value ?? this.value,
      trend: trend ?? this.trend,
    );
  }
}

class SlideTemplateCustomization {
  final String eyebrow;
  final String headline;
  final String subheadline;
  final String footer;
  final List<SlideTemplateTextItem> items;
  final List<SlideTemplateMetric> metrics;

  const SlideTemplateCustomization({
    required this.eyebrow,
    required this.headline,
    required this.subheadline,
    required this.footer,
    this.items = const [],
    this.metrics = const [],
  });

  factory SlideTemplateCustomization.defaultsFor(SlideTemplateType type) {
    switch (type) {
      case SlideTemplateType.executiveCover:
        return const SlideTemplateCustomization(
          eyebrow: 'STRATEGIC BRIEF',
          headline: 'Turn the next decision into a clear narrative.',
          subheadline:
              'A concise executive opening slide for proposals, investor updates, and leadership reviews.',
          footer: 'Prepared for Kaysir Platform',
        );
      case SlideTemplateType.agenda:
        return const SlideTemplateCustomization(
          eyebrow: '',
          headline: 'Meeting Flow',
          subheadline: 'A structured path from context to commitment.',
          footer: '',
          items: [
            SlideTemplateTextItem(
              label: '01',
              title: 'Context',
              body: 'What changed, why it matters, and where the risk sits.',
            ),
            SlideTemplateTextItem(
              label: '02',
              title: 'Insight',
              body: 'The strongest signal behind the recommended move.',
            ),
            SlideTemplateTextItem(
              label: '03',
              title: 'Decision',
              body: 'Trade-offs, options, and the direction to approve.',
            ),
            SlideTemplateTextItem(
              label: '04',
              title: 'Next',
              body: 'Owners, milestones, and measurable follow-through.',
            ),
          ],
        );
      case SlideTemplateType.metricStory:
        return const SlideTemplateCustomization(
          eyebrow: '',
          headline: 'Metric Story',
          subheadline:
              'Show the headline performance first, then support it with trend evidence.',
          footer: '',
          metrics: [
            SlideTemplateMetric(
              label: 'Revenue',
              value: '\$2.4M',
              trend: '+18% QoQ',
            ),
            SlideTemplateMetric(
              label: 'Activation',
              value: '64%',
              trend: '+9 pts',
            ),
            SlideTemplateMetric(
              label: 'Retention',
              value: '91%',
              trend: 'Stable',
            ),
          ],
        );
      case SlideTemplateType.comparison:
        return const SlideTemplateCustomization(
          eyebrow: '',
          headline: 'Compare the options',
          subheadline: '',
          footer: '',
          items: [
            SlideTemplateTextItem(
              label: 'A',
              title: 'Option A',
              body:
                  'Best when speed, confidence, and clear ownership matter most.',
            ),
            SlideTemplateTextItem(
              label: 'B',
              title: 'Option B',
              body:
                  'Best when flexibility, learning, and phased rollout matter most.',
            ),
            SlideTemplateTextItem(
              label: 'Lens',
              title: 'Decision lens',
              body: 'Impact, risk, effort, timeline',
            ),
            SlideTemplateTextItem(
              label: 'Pick',
              title: 'Recommendation',
              body: 'Choose the path with fewer hidden dependencies.',
            ),
          ],
        );
    }
  }

  SlideTemplateCustomization copyWith({
    String? eyebrow,
    String? headline,
    String? subheadline,
    String? footer,
    List<SlideTemplateTextItem>? items,
    List<SlideTemplateMetric>? metrics,
  }) {
    return SlideTemplateCustomization(
      eyebrow: eyebrow ?? this.eyebrow,
      headline: headline ?? this.headline,
      subheadline: subheadline ?? this.subheadline,
      footer: footer ?? this.footer,
      items: items ?? this.items,
      metrics: metrics ?? this.metrics,
    );
  }
}

class SlideTemplateRecipe {
  final SlideTemplateType type;
  final SlideTemplateCategory category;
  final String name;
  final String summary;
  final String actionLabel;
  final int componentCount;

  const SlideTemplateRecipe({
    required this.type,
    required this.category,
    required this.name,
    required this.summary,
    required this.actionLabel,
    required this.componentCount,
  });
}

class SlideTemplateCatalog {
  const SlideTemplateCatalog._();

  static const recipes = [
    SlideTemplateRecipe(
      type: SlideTemplateType.executiveCover,
      category: SlideTemplateCategory.cover,
      name: 'Executive Cover',
      summary: 'Hero title, signal badge, and focused subtitle.',
      actionLabel: 'Add cover',
      componentCount: 6,
    ),
    SlideTemplateRecipe(
      type: SlideTemplateType.agenda,
      category: SlideTemplateCategory.structure,
      name: 'Agenda Flow',
      summary: 'Four-step session structure with visual pacing.',
      actionLabel: 'Add agenda',
      componentCount: 10,
    ),
    SlideTemplateRecipe(
      type: SlideTemplateType.metricStory,
      category: SlideTemplateCategory.metrics,
      name: 'Metric Story',
      summary: 'KPI cards with a clean trend chart.',
      actionLabel: 'Add metrics',
      componentCount: 9,
    ),
    SlideTemplateRecipe(
      type: SlideTemplateType.comparison,
      category: SlideTemplateCategory.decision,
      name: 'Comparison Board',
      summary: 'Side-by-side options for decisions or positioning.',
      actionLabel: 'Add compare',
      componentCount: 9,
    ),
  ];
}
