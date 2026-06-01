class MoneyParserService {
  int? tryParseToCents(String input) {
    final value = input.trim();
    if (value.isEmpty) return null;
    if (value.startsWith('-')) return null;

    final normalized = value.replaceAll(r'$', '');
    if (!RegExp(r'^\d*([.]\d{0,2})?$').hasMatch(normalized)) return null;

    final parts = normalized.split('.');
    final dollarsText = parts.first.isEmpty ? '0' : parts.first;
    final centsText = parts.length > 1 ? parts[1] : '';
    final paddedCents = '${centsText}00'.substring(0, 2);

    final dollars = int.tryParse(dollarsText);
    final cents = int.tryParse(paddedCents);
    if (dollars == null || cents == null) return null;
    return dollars * 100 + cents;
  }

  int parseToCentsOrThrow(String input) {
    final cents = tryParseToCents(input);
    if (cents == null) {
      throw const FormatException('Invalid money format');
    }
    return cents;
  }
}
