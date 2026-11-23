import 'dart:async';
import '../models/app_notification.dart';
import '../models/helmet_event_record.dart';

/// Notification service managing real-time in-app alerts, heads-up banners, and alert history.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;

  NotificationService._internal();

  final List<AppNotification> _notifications = [];
  final StreamController<AppNotification> _notificationController =
      StreamController<AppNotification>.broadcast();

  Stream<AppNotification> get notificationStream => _notificationController.stream;
  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Dispatch an alert notification
  void notify({
    required String title,
    required String body,
    required EventSeverity severity,
    bool isDemo = false,
    String? actionRoute,
    Map<String, dynamic>? payload,
  }) {
    final notification = AppNotification(
      id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch}-${_notifications.length}',
      timestamp: DateTime.now(),
      title: title,
      body: body,
      severity: severity,
      isDemo: isDemo,
      actionRoute: actionRoute,
      payload: payload,
    );

    _notifications.insert(0, notification);
    if (_notifications.length > 50) {
      _notifications.removeLast();
    }

    _notificationController.add(notification);
    // Log alert notification
    print('[Notification] ${severity.name.toUpperCase()}: $title - $body');
  }

  /// Mark specific notification as read
  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
    }
  }

  /// Mark all notifications as read
  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
  }

  /// Clear all notifications
  void clearAll() {
    _notifications.clear();
  }

  void dispose() {
    _notificationController.close();
  }
}
