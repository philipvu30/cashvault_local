import 'package:intl/intl.dart';

class MoneyFormatService {
  final NumberFormat _integerFormat = NumberFormat.decimalPattern('en_US');

  String formatCents(int cents) {
    final absCents = cents.abs();
    final dollars = absCents ~/ 100;
    final centPart = absCents % 100;
    final formattedDollars = _integerFormat.format(dollars);
    final display = '\$$formattedDollars.${centPart.toString().padLeft(2, '0')}';
    return cents < 0 ? '-$display' : display;
  }
}
