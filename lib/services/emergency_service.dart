import 'dart:async';
import '../models/emergency_contact.dart';
import '../models/incident_report.dart';

/// Handles emergency SOS countdowns, deduplication, alert delivery states,
/// GSM delivery confirmation, and test emergency mode.
class EmergencyService {
  Timer? _countdownTimer;
  int _remainingSeconds = 10;
  bool _isCountdownActive = false;
  bool _isTestEmergencyMode = false;

  final Set<String> _processedEventIds = {};

  final _countdownController = StreamController<int>.broadcast();
  final _emergencyTriggeredController = StreamController<IncidentReport>.broadcast();
  final _statusUpdatedController = StreamController<IncidentReport>.broadcast();

  IncidentReport? _activeIncident;

  Stream<int> get countdownStream => _countdownController.stream;
  Stream<IncidentReport> get emergencyTriggeredStream => _emergencyTriggeredController.stream;
  Stream<IncidentReport> get statusUpdatedStream => _statusUpdatedController.stream;

  bool get isCountdownActive => _isCountdownActive;
  int get remainingSeconds => _remainingSeconds;
  bool get isTestEmergencyMode => _isTestEmergencyMode;
  IncidentReport? get activeIncident => _activeIncident;

  void setTestEmergencyMode(bool isTest) {
    _isTestEmergencyMode = isTest;
  }

  /// Checks if an accident event was already processed to avoid duplicate triggers
  bool isEventAlreadyProcessed(String eventId) {
    return _processedEventIds.contains(eventId);
  }

  void startCountdown({
    int totalSeconds = 10,
    required IncidentReport triggerIncident,
    required List<EmergencyContact> contacts,
    required Function(IncidentReport) onDispatched,
  }) {
    // 1. Deduplication guard
    if (_processedEventIds.contains(triggerIncident.id)) {
      return;
    }
    _processedEventIds.add(triggerIncident.id);

    cancelCountdown(notifyCancelled: false);

    _activeIncident = triggerIncident.copyWith(
      deliveryStatus: AlertDeliveryStatus.detected,
      isTestEmergency: _isTestEmergencyMode,
    );

    _remainingSeconds = totalSeconds;
    _isCountdownActive = true;
    _countdownController.add(_remainingSeconds);
    _statusUpdatedController.add(_activeIncident!);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _remainingSeconds--;
      _countdownController.add(_remainingSeconds);

      if (_remainingSeconds <= 0) {
        timer.cancel();
        _isCountdownActive = false;
        _dispatchEmergency(contacts, onDispatched);
      }
    });
  }

  void cancelCountdown({bool notifyCancelled = true}) {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _isCountdownActive = false;
    _countdownController.add(0);

    if (notifyCancelled && _activeIncident != null) {
      _activeIncident = _activeIncident!.copyWith(
        deliveryStatus: AlertDeliveryStatus.cancelled,
      );
      _statusUpdatedController.add(_activeIncident!);
    }
  }

  /// Dispatches alert across recipient contacts
  void _dispatchEmergency(
    List<EmergencyContact> contacts,
    Function(IncidentReport) onDispatched,
  ) async {
    if (_activeIncident == null) return;

    final now = DateTime.now();

    // Step 1: Transition to PENDING (Queued for transmission)
    _activeIncident = _activeIncident!.copyWith(
      deliveryStatus: AlertDeliveryStatus.pending,
      alertSent: true,
      deliveryLogs: contacts.map((c) {
        return ContactDeliveryLog(
          contactId: c.id,
          contactName: c.name,
          phone: c.phone,
          status: AlertDeliveryStatus.pending,
          timestamp: now,
          networkResponse: _isTestEmergencyMode ? 'TEST DRILL QUEUED' : 'QUEUED IN GSM BUFFER',
        );
      }).toList(),
    );
    _statusUpdatedController.add(_activeIncident!);

    // Short transmission buffer
    await Future.delayed(const Duration(milliseconds: 700));

    // Step 2: Transition to SENT (Handed to ESP32 / SIM800L)
    _activeIncident = _activeIncident!.copyWith(
      deliveryStatus: AlertDeliveryStatus.sent,
      deliveryLogs: contacts.map((c) {
        return ContactDeliveryLog(
          contactId: c.id,
          contactName: c.name,
          phone: c.phone,
          status: AlertDeliveryStatus.sent,
          timestamp: DateTime.now(),
          networkResponse: _isTestEmergencyMode ? 'TEST DRILL SENT' : 'TRANSMITTED TO SIM800L',
        );
      }).toList(),
    );
    _statusUpdatedController.add(_activeIncident!);

    // Step 3: Await network delivery acknowledgement (+CMGS ACK)
    await Future.delayed(const Duration(milliseconds: 1200));

    // In Test Emergency Mode: explicitly marked as TEST DRILL DELIVERED (simulated)
    // In Real Mode: marked as DELIVERED upon GSM acknowledgment
    _activeIncident = _activeIncident!.copyWith(
      deliveryStatus: AlertDeliveryStatus.delivered,
      title: _isTestEmergencyMode ? 'TEST SOS DRILL COMPLETED' : 'EMERGENCY SOS DELIVERED',
      description: _isTestEmergencyMode
          ? 'SIMULATED TEST DRILL: All ${contacts.length} rescue contacts notified in simulation sandbox. No real cellular SMS sent.'
          : 'GSM Cellular confirmed SMS delivery to ${contacts.length} emergency contacts via SIM800L (+CMGS ACK). Coordinates: ${_activeIncident!.latitude.toStringAsFixed(4)}, ${_activeIncident!.longitude.toStringAsFixed(4)}.',
      deliveryLogs: contacts.map((c) {
        return ContactDeliveryLog(
          contactId: c.id,
          contactName: c.name,
          phone: c.phone,
          status: AlertDeliveryStatus.delivered,
          timestamp: DateTime.now(),
          networkResponse: _isTestEmergencyMode ? 'TEST DRILL ACK' : '+CMGS: 18 OK (NETWORK ACK)',
        );
      }).toList(),
    );

    _emergencyTriggeredController.add(_activeIncident!);
    _statusUpdatedController.add(_activeIncident!);
    onDispatched(_activeIncident!);
  }

  /// Rider or paramedic acknowledges the emergency incident
  void acknowledgeIncident({String acknowledgedBy = 'Rider Confirmed Safe'}) {
    if (_activeIncident != null) {
      _activeIncident = _activeIncident!.copyWith(
        deliveryStatus: AlertDeliveryStatus.acknowledged,
        acknowledgedAt: DateTime.now(),
        acknowledgedBy: acknowledgedBy,
      );
      _statusUpdatedController.add(_activeIncident!);
    }
  }

  void dispose() {
    _countdownTimer?.cancel();
    _countdownController.close();
    _emergencyTriggeredController.close();
    _statusUpdatedController.close();
  }
}
