class KyOfficeRecentFile {
  const KyOfficeRecentFile({
    required this.id,
    required this.title,
    required this.productId,
    required this.updatedAt,
    this.location,
    this.owner,
    this.starred = false,
  });

  final String id;
  final String title;
  final String productId;
  final DateTime updatedAt;
  final String? location;
  final String? owner;
  final bool starred;

  String updatedLabel({DateTime? now}) {
    final reference = now ?? DateTime.now();
    final updatedDate = DateTime(
      updatedAt.year,
      updatedAt.month,
      updatedAt.day,
    );
    final today = DateTime(reference.year, reference.month, reference.day);
    final days = today.difference(updatedDate).inDays;

    if (days <= 0) return 'Today';
    if (days == 1) return 'Yesterday';
    if (days < 7) return '$days days ago';
    if (days < 30) {
      final weeks = (days / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    }

    return '${_monthName(updatedAt.month)} ${updatedAt.day}, ${updatedAt.year}';
  }

  static String _monthName(int month) {
    return const [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ][month - 1];
  }
}
