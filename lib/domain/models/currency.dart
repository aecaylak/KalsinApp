class AppCurrency {
  final String code;
  final String name;
  final String symbol;
  final String flag;

  const AppCurrency({
    required this.code,
    required this.name,
    required this.symbol,
    required this.flag,
  });
}

const List<AppCurrency> kCurrencies = [
  // Türkiye
  AppCurrency(code: 'TRY', name: 'Türk Lirası',        symbol: '₺',    flag: '🇹🇷'),
  // Dünya
  AppCurrency(code: 'USD', name: 'Amerikan Doları',     symbol: '\$',   flag: '🇺🇸'),
  AppCurrency(code: 'EUR', name: 'Euro',                symbol: '€',    flag: '🇪🇺'),
  AppCurrency(code: 'GBP', name: 'İngiliz Sterlini',   symbol: '£',    flag: '🇬🇧'),
  AppCurrency(code: 'CHF', name: 'İsviçre Frangı',     symbol: 'Fr',   flag: '🇨🇭'),
  AppCurrency(code: 'JPY', name: 'Japon Yeni',          symbol: '¥',    flag: '🇯🇵'),
  AppCurrency(code: 'CAD', name: 'Kanada Doları',       symbol: 'C\$',  flag: '🇨🇦'),
  AppCurrency(code: 'AUD', name: 'Avustralya Doları',   symbol: 'A\$',  flag: '🇦🇺'),
  AppCurrency(code: 'SAR', name: 'Suudi Riyali',        symbol: '﷼',   flag: '🇸🇦'),
  // Türk Cumhuriyetleri
  AppCurrency(code: 'AZN', name: 'Azerbaycan Manatı',  symbol: '₼',    flag: '🇦🇿'),
  AppCurrency(code: 'KZT', name: 'Kazak Tengesi',       symbol: '₸',    flag: '🇰🇿'),
  AppCurrency(code: 'UZS', name: 'Özbek Somu',          symbol: "so'm", flag: '🇺🇿'),
  AppCurrency(code: 'TMT', name: 'Türkmen Manatı',      symbol: 'T',    flag: '🇹🇲'),
  AppCurrency(code: 'KGS', name: 'Kırgız Somu',         symbol: 'с',    flag: '🇰🇬'),
];

AppCurrency currencyByCode(String code) =>
    kCurrencies.firstWhere((c) => c.code == code, orElse: () => kCurrencies.first);
