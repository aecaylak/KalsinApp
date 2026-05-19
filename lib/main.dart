import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app/app.dart';
import 'core/services/notification_service.dart';
import 'data/repositories/savings_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // AdMob SDK başlat
  await MobileAds.instance.initialize();

  // Bildirim servisi başlat
  await NotificationService.instance.init();
  await NotificationService.instance.scheduleDailyReminder();

  // Türkçe tarih formatı için yerel ayarları başlat
  await initializeDateFormatting('tr_TR', null);

  // Hive ve adaptörleri başlat
  await SavingsRepository.init();
  // We no longer seed mock data, users start with Onboarding.

  runApp(
    // Riverpod'un tüm Provider'ları kapsayan kök widget'ı
    const ProviderScope(
      child: KalsinApp(),
    ),
  );
}
