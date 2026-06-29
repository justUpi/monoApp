class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> initNotification() async {}
  Future<void> scheduleQuestNotification({
    required int questLevel,
    required String questTitle,
  }) async {}
  Future<void> cancelQuestNotification() async {}
}
