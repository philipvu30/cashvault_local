import 'package:intl/intl.dart';

class MoneyCalculationService {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_US',
    symbol: r'$',
    decimalDigits: 2,
  );

  static String formatCents(int cents) => _currencyFormat.format(cents / 100);

  static String toDecimalString(int cents) {
    final absoluteCents = cents.abs();
    final dollars = absoluteCents ~/ 100;
    final remainder = absoluteCents % 100;
    final sign = cents < 0 ? '-' : '';
    return '$sign$dollars.${remainder.toString().padLeft(2, '0')}';
  }

  static int parseToCents(String input) {
    final normalized = input.replaceAll(',', '').replaceAll(r'$', '').trim();
    if (normalized.isEmpty) {
      throw const FormatException('Invalid amount format.');
    }

    if (normalized.startsWith('-')) {
      throw const FormatException('Amount must be 0 or greater.');
    }

    final parts = normalized.split('.');
    if (parts.length > 2) {
      throw const FormatException('Invalid amount format.');
    }

    final wholePart = parts.first.isEmpty ? '0' : parts.first;
    if (!_digitsOnly.hasMatch(wholePart)) {
      throw const FormatException('Invalid amount format.');
    }

    final fractionalPart = parts.length == 2 ? parts[1] : '';
    if (fractionalPart.length > 2 || !_digitsOrEmpty.hasMatch(fractionalPart)) {
      throw const FormatException('Invalid amount format.');
    }

    final wholeCents = int.parse(wholePart) * 100;
    final paddedFraction = fractionalPart.padRight(2, '0');
    final fractionalCents = paddedFraction.isEmpty ? 0 : int.parse(paddedFraction);
    return wholeCents + fractionalCents;
  }

  static final RegExp _digitsOnly = RegExp(r'^\d+$');
  static final RegExp _digitsOrEmpty = RegExp(r'^\d*$');
}
