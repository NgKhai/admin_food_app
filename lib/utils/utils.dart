import 'package:intl/intl.dart';

class Utils {
  static String formatCurrency(num amount) {
    final format = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return format.format(amount);
  }
}