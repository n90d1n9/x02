enum SlideLayoutType {
  blank,
  title,
  titleAndContent,
  twoColumn,
  sectionHeader,
  comparison,
}

class SlideLayoutRecipe {
  final SlideLayoutType type;
  final String name;
  final String summary;
  final String actionLabel;
  final int placeholderCount;

  const SlideLayoutRecipe({
    required this.type,
    required this.name,
    required this.summary,
    required this.actionLabel,
    required this.placeholderCount,
  });
}

class SlideLayoutCatalog {
  const SlideLayoutCatalog._();

  static const recipes = [
    SlideLayoutRecipe(
      type: SlideLayoutType.blank,
      name: 'Blank',
      summary: 'Open canvas with no placeholders.',
      actionLabel: 'Add blank layout',
      placeholderCount: 0,
    ),
    SlideLayoutRecipe(
      type: SlideLayoutType.title,
      name: 'Title Slide',
      summary: 'Centered title and subtitle placeholders.',
      actionLabel: 'Add title slide',
      placeholderCount: 2,
    ),
    SlideLayoutRecipe(
      type: SlideLayoutType.titleAndContent,
      name: 'Title + Content',
      summary: 'Title with one large content placeholder.',
      actionLabel: 'Add content slide',
      placeholderCount: 2,
    ),
    SlideLayoutRecipe(
      type: SlideLayoutType.twoColumn,
      name: 'Two Columns',
      summary: 'Title with balanced left and right content areas.',
      actionLabel: 'Add two-column slide',
      placeholderCount: 3,
    ),
    SlideLayoutRecipe(
      type: SlideLayoutType.sectionHeader,
      name: 'Section Header',
      summary: 'Centered section title with short support copy.',
      actionLabel: 'Add section slide',
      placeholderCount: 2,
    ),
    SlideLayoutRecipe(
      type: SlideLayoutType.comparison,
      name: 'Comparison',
      summary: 'Title plus side-by-side option placeholders.',
      actionLabel: 'Add comparison slide',
      placeholderCount: 5,
    ),
  ];
}
