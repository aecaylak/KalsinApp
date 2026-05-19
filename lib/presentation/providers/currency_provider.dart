import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/currency.dart';
import 'user_provider.dart';

/// Kullanıcının seçtiği para birimini döner. Profil yoksa TRY.
final currencyProvider = Provider<AppCurrency>((ref) {
  final profile = ref.watch(userProvider);
  return currencyByCode(profile?.currencyCode ?? 'TRY');
});
