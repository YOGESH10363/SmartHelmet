import 'emergency_contact.dart';

enum IncidentType {
  crashDetected,
  sosManualTrigger,
  alcoholInterlock,
  helmetRemovedInRide,
  overSpeedWarning,
  selfTestPassed,
  testEmergencyDrill,
}

enum IncidentSeverity {
  low,
  medium,
  high,
  critical,
}

enum AlertDeliveryStatus {
  detected,    // Anomaly identified, verification countdown active
  pending,     // Countdown expired, transmitting to ESP32 / GSM queue
  sent,        // Handed off to SIM800L GSM modem
  delivered,   // Confirmed delivered by GSM network ACK (+CMGS)
  failed,      // SIM800L error / no cellular signal / network timeout
  cancelled,   // Cancelled by rider during countdown (false alarm)
  acknowledged // Incident acknowledged / help arrived
}

/// Detailed SMS delivery log per recipient
class ContactDeliveryLog {
  final String contactId;
  final String contactName;
  final String phone;
  final AlertDeliveryStatus status;
  final DateTime timestamp;
  final String? networkResponse; // e.g. "+CMGS: 42 (ACK)" or "SIM800L: NO CARRIER"

  const ContactDeliveryLog({
    required this.contactId,
    required this.contactName,
    required this.phone,
    required this.status,
    required this.timestamp,
    this.networkResponse,
  });

  ContactDeliveryLog copyWith({
    String? contactId,
    String? contactName,
    String? phone,
    AlertDeliveryStatus? status,
    DateTime? timestamp,
    String? networkResponse,
  }) {
    return ContactDeliveryLog(
      contactId: contactId ?? this.contactId,
      contactName: contactName ?? this.contactName,
      phone: phone ?? this.phone,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      networkResponse: networkResponse ?? this.networkResponse,
    );
  }
}

/// IncidentReport logs real-time safety events with coordinates, delivery status, and acknowledgement.
class IncidentReport {
  final String id;
  final IncidentType type;
  final IncidentSeverity severity;
  final String title;
  final String description;
  final double latitude;
  final double longitude;
  final bool hasGpsCoordinates;
  final double speedKmh;
  final double peakGForce;
  final double tiltAngleDeg;
  final DateTime timestamp;
  final bool alertSent;
  final AlertDeliveryStatus deliveryStatus;
  final bool isTestEmergency;
  final DateTime? acknowledgedAt;
  final String? acknowledgedBy;
  final List<ContactDeliveryLog> deliveryLogs;

  const IncidentReport({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.hasGpsCoordinates = true,
    required this.speedKmh,
    required this.peakGForce,
    this.tiltAngleDeg = 0.0,
    required this.timestamp,
    this.alertSent = false,
    this.deliveryStatus = AlertDeliveryStatus.detected,
    this.isTestEmergency = false,
    this.acknowledgedAt,
    this.acknowledgedBy,
    this.deliveryLogs = const [],
  });

  bool get isAcknowledged => acknowledgedAt != null;

  IncidentReport copyWith({
    String? id,
    IncidentType? type,
    IncidentSeverity? severity,
    String? title,
    String? description,
    double? latitude,
    double? longitude,
    bool? hasGpsCoordinates,
    double? speedKmh,
    double? peakGForce,
    double? tiltAngleDeg,
    DateTime? timestamp,
    bool? alertSent,
    AlertDeliveryStatus? deliveryStatus,
    bool? isTestEmergency,
    DateTime? acknowledgedAt,
    String? acknowledgedBy,
    List<ContactDeliveryLog>? deliveryLogs,
  }) {
    return IncidentReport(
      id: id ?? this.id,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      title: title ?? this.title,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      hasGpsCoordinates: hasGpsCoordinates ?? this.hasGpsCoordinates,
      speedKmh: speedKmh ?? this.speedKmh,
      peakGForce: peakGForce ?? this.peakGForce,
      tiltAngleDeg: tiltAngleDeg ?? this.tiltAngleDeg,
      timestamp: timestamp ?? this.timestamp,
      alertSent: alertSent ?? this.alertSent,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      isTestEmergency: isTestEmergency ?? this.isTestEmergency,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      acknowledgedBy: acknowledgedBy ?? this.acknowledgedBy,
      deliveryLogs: deliveryLogs ?? this.deliveryLogs,
    );
  }
}
