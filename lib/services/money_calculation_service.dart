import 'package:intl/intl.dart';

class MoneyCalculationService {
  static final NumberFormat _format = NumberFormat('#,##0.00', 'en_US');

  static int decimalToCents(double value) => (value * 100).round();

  static double centsToDecimal(int cents) => cents / 100.0;

  static String formatCents(int cents) => _format.format(centsToDecimal(cents));

  static int parseToCents(String input) {
    final normalized = input.replaceAll(',', '').trim();
    final parsed = double.tryParse(normalized);
    if (parsed == null) {
      throw const FormatException('Invalid amount format.');
    }
    if (parsed < 0) {
      throw const FormatException('Amount must be 0 or greater.');
    }
    return decimalToCents(parsed);
  }
}
