/// Represents a currency option for display purposes.
class Currency {
  final String code;
  final String symbol;
  final String name;

  const Currency({
    required this.code,
    required this.symbol,
    required this.name,
  });

  /// All supported currencies.
  static const List<Currency> supportedCurrencies = [
    Currency(code: 'INR', symbol: '\u20B9', name: 'Indian Rupee'),
    Currency(code: 'USD', symbol: '\u0024', name: 'US Dollar'),
    Currency(code: 'EUR', symbol: '\u20AC', name: 'Euro'),
    Currency(code: 'GBP', symbol: '\u00A3', name: 'British Pound'),
    Currency(code: 'AED', symbol: 'AED', name: 'UAE Dirham'),
    Currency(code: 'PKR', symbol: 'PKR', name: 'Pakistani Rupee'),
  ];

  /// Default currency (Indian Rupee).
  static const Currency defaultCurrency = Currency(
    code: 'INR',
    symbol: '\u20B9',
    name: 'Indian Rupee',
  );

  /// Find currency by code.
  static Currency fromCode(String code) {
    return supportedCurrencies.firstWhere(
      (c) => c.code == code,
      orElse: () => defaultCurrency,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Currency &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => '$symbol ($code)';
}
