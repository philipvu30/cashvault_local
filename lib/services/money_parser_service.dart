class MoneyParserService {
  int? tryParseToCents(String input) {
    final value = _sanitizeMoneyInput(input);
    if (value.isEmpty) return null;
    if (value.startsWith('-')) return null;

    if (!RegExp(r'^\d*([.]\d{0,2})?$').hasMatch(value)) return null;

    final parts = value.split('.');
    final dollarsText = parts.first.isEmpty ? '0' : parts.first;
    final centsText = parts.length > 1 ? parts[1] : '';
    final paddedCents = '${centsText}00'.substring(0, 2);

    final dollars = int.tryParse(dollarsText);
    final cents = int.tryParse(paddedCents);
    if (dollars == null || cents == null) return null;
    return dollars * 100 + cents;
  }

  String? tryNormalizeMoneyText(String input) {
    final cents = tryParseToCents(input);
    if (cents == null || cents < 0) return null;
    return centsToNormalizedText(cents);
  }

  String centsToNormalizedText(int cents) {
    final safe = cents < 0 ? 0 : cents;
    final dollars = safe ~/ 100;
    final remains = safe % 100;
    return '$dollars.${remains.toString().padLeft(2, '0')}';
  }

  int parseToCentsOrThrow(String input) {
    final cents = tryParseToCents(input);
    if (cents == null) {
      throw const FormatException('Invalid money format');
    }
    return cents;
  }

  String _sanitizeMoneyInput(String value) {
    return value.trim().replaceAll(RegExp(r'[\s,\$]'), '');
  }
}
