import 'package:intl/intl.dart';

class CollaborationAddLogic {
  /// Formats rate for display (removes .0 if present)
  static String formatRate(double val) {
    if (val == 0) return "";
    String text = val.toStringAsFixed(1);
    if (text.endsWith('.0')) text = text.substring(0, text.length - 2);
    return text;
  }

  /// Formats num value as currency (₹)
  static String formatCurrency(num value) {
    return NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 2,
      locale: 'en_IN',
    ).format(value);
  }
}
