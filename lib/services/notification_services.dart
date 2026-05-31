import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Inisialisasi awal notifikasi
  Future<void> initNotification() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(initializationSettings);

    // ini untuk me-request izin ke OS (Android & iOS)
    await requestPermissions();
  }

  Future<void> requestPermissions() async {
    // Jalankan request permission khusus Android 13 (API 33) ke atas
    final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission(); // Penting untuk zonedSchedule akurat
    }
  }

  // Fungsi Utama: Menjadwalkan notifikasi berdasarkan Level Quest
  Future<void> scheduleQuestNotification({required int questLevel, required String questTitle}) async {
    // Tentukan durasi berdasarkan level (1: 1 jam, 2: 2 jam, 3: 3 jam)
    int hours = questLevel == 3 ? 3 : (questLevel == 2 ? 2 : 1);

    // Hitung waktu spesifik di masa depan menggunakan timezone lokal perangkat
    final tz.TZDateTime scheduledTime = tz.TZDateTime.now(tz.local).add(Duration(hours: hours));

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'mono_quest_channel',
      'Quest Reminders',
      channelDescription: 'Notifikasi pengingat batas waktu quest aktif',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    // Batalkan notifikasi quest lama (jika ada) agar tidak menumpuk sebelum membuat yang baru
    await cancelQuestNotification();

    // Jadwalkan Notifikasi
    await _notificationsPlugin.zonedSchedule(
      0, // ID Notifikasi (tetap 0 karena Mono fokus pada satu quest dalam satu waktu)
      'Quest Waktu Habis!',
      'Kamu sudah fokus pada "$questTitle" selama $hours jam. Waktunya istirahat atau evaluasi!',
      scheduledTime,
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // Fungsi untuk membatalkan notifikasi jika quest diselesaikan lebih cepat
  Future<void> cancelQuestNotification() async {
    await _notificationsPlugin.cancel(0);
  }
}