import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'kalsin_main';
  static const _channelName = 'KalsınApp Bildirimleri';

  Future<void> init() async {
    try {
      const android = AndroidInitializationSettings('@mipmap/launcher_icon');
      const ios = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      await _plugin.initialize(
        const InitializationSettings(android: android, iOS: ios),
      );

      // Android 13+ izin iste
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (_) {
      // Bildirim izni verilmemiş ya da sistem hatası — uygulama çalışmaya devam eder
    }
  }

  /// Günlük tasarruf hatırlatması — her gün saat 20:00
  Future<void> scheduleDailyReminder() async {
    try {
      await _plugin.periodicallyShow(
        1,
        'Bugün tasarruf ettin mi? 💚',
        'Her "Kalsın" seni hedefe bir adım yaklaştırır!',
        RepeatInterval.daily,
        _notifDetails(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (_) {
      // İzin yoksa veya zamanlama başarısız — sessizce geç
    }
  }

  /// Streak tehlikede bildirimi — streak > 0 iken çağır
  Future<void> showStreakWarning(int streak) async {
    try {
      await _plugin.show(
        2,
        'Seriniz tehlikede! 🔥',
        '$streak günlük serinizi kaybetmemek için bugün bir tasarruf ekle!',
        _notifDetails(),
      );
    } catch (_) {}
  }

  /// Yeni tasarruf eklenince motivasyon bildirimi
  Future<void> showSavingAdded(double amount) async {
    try {
      await _plugin.show(
        3,
        'Harika! ₺${amount.toStringAsFixed(0)} biriktirdin 🎉',
        'Böyle devam et, hedefe giderek yaklaşıyorsun!',
        _notifDetails(),
      );
    } catch (_) {}
  }

  /// Hedefe ulaşıldığında kutlama bildirimi
  Future<void> showGoalReached(String goalTitle) async {
    try {
      await _plugin.show(
        4,
        '🎯 Hedefe ulaştın!',
        '"$goalTitle" hedefini tamamladın! Yeni bir hedef belirle.',
        _notifDetails(),
      );
    } catch (_) {}
  }

  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }

  NotificationDetails _notifDetails() => const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
        ),
        iOS: DarwinNotificationDetails(),
      );
}
