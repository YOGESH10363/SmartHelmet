import 'helmet_event_record.dart';

/// Notification payload for real-time safety, connectivity, and telemetry alerts.
class AppNotification {
  final String id;
  final DateTime timestamp;
  final String title;
  final String body;
  final EventSeverity severity;
  final bool isRead;
  final bool isDemo;
  final String? actionRoute;
  final Map<String, dynamic>? payload;

  const AppNotification({
    required this.id,
    required this.timestamp,
    required this.title,
    required this.body,
    required this.severity,
    this.isRead = false,
    this.isDemo = false,
    this.actionRoute,
    this.payload,
  });

  AppNotification copyWith({
    String? id,
    DateTime? timestamp,
    String? title,
    String? body,
    EventSeverity? severity,
    bool? isRead,
    bool? isDemo,
    String? actionRoute,
    Map<String, dynamic>? payload,
  }) {
    return AppNotification(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      title: title ?? this.title,
      body: body ?? this.body,
      severity: severity ?? this.severity,
      isRead: isRead ?? this.isRead,
      isDemo: isDemo ?? this.isDemo,
      actionRoute: actionRoute ?? this.actionRoute,
      payload: payload ?? this.payload,
    );
  }
}
