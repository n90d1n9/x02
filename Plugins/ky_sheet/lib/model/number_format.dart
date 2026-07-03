class SheetNumberFormatId {
  const SheetNumberFormatId._();

  static const general = 'general';
  static const number = 'number';
  static const currency = 'currency';
  static const percent = 'percent';
  static const date = 'date';

  static const values = [general, number, currency, percent, date];

  static String labelFor(String? value) {
    switch (value) {
      case number:
        return 'Number';
      case currency:
        return 'Currency';
      case percent:
        return 'Percent';
      case date:
        return 'Date';
      case general:
      case null:
      default:
        return 'General';
    }
  }
}
