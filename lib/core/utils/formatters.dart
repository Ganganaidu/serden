import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static final _currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  static final _dateShort = DateFormat('MMM d');
  static final _dateMedium = DateFormat('MMM d, yyyy');
  static final _monthYear = DateFormat('MMMM yyyy');

  static final _currencyShort = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

  static String currency(double amount) => _currency.format(amount);

  /// Rounded, no cents — used in header summaries ("$21,400 lifetime work").
  static String currencyShort(double amount) => _currencyShort.format(amount.roundToDouble());

  static String dateShort(DateTime date) => _dateShort.format(date);

  static String dateMedium(DateTime date) => _dateMedium.format(date);

  static String monthYear(DateTime date) => _monthYear.format(date);

  static String initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
