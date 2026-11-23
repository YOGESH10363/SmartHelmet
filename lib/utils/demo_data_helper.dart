import '../models/emergency_contact.dart';
import '../models/incident_report.dart';

/// DemoDataHelper provides realistic exhibition demo data.
class DemoDataHelper {
  static List<EmergencyContact> getInitialContacts() {
    return const [
      EmergencyContact(
        id: 'cnt-01',
        name: 'Parent / Primary Guardian',
        phone: '+91 98220 11223',
        relationship: 'Father',
        isPrimary: true,
        notifyViaSms: true,
        notifyViaCall: true,
      ),
      EmergencyContact(
        id: 'cnt-02',
        name: 'Anita Sharma',
        phone: '+91 98440 99887',
        relationship: 'Sister',
        isPrimary: false,
        notifyViaSms: true,
        notifyViaCall: false,
      ),
      EmergencyContact(
        id: 'cnt-03',
        name: 'City Trauma Emergency Care',
        phone: '108',
        relationship: 'Hospital Ambulatory',
        isPrimary: false,
        notifyViaSms: true,
        notifyViaCall: true,
      ),
      EmergencyContact(
        id: 'cnt-04',
        name: 'Highway Patrol Emergency Police',
        phone: '112',
        relationship: 'Police Dispatch',
        isPrimary: false,
        notifyViaSms: true,
        notifyViaCall: true,
      ),
    ];
  }

  static List<IncidentReport> getInitialIncidents() {
    final now = DateTime.now();
    return [
      IncidentReport(
        id: 'inc-001',
        type: IncidentType.selfTestPassed,
        severity: IncidentSeverity.low,
        title: 'Pre-Ride Safety Self-Test OK',
        description: 'Helmet strap locked, MQ-3 alcohol 42 ppm (< 200 ppm safe limit). Engine ignition interlock released.',
        latitude: 18.5204,
        longitude: 73.8567,
        speedKmh: 0.0,
        peakGForce: 1.01,
        timestamp: now.subtract(const Duration(minutes: 32)),
        alertSent: false,
      ),
      IncidentReport(
        id: 'inc-002',
        type: IncidentType.overSpeedWarning,
        severity: IncidentSeverity.medium,
        title: 'Speed Threshold Alert (84.2 km/h)',
        description: 'Vehicle exceeded 80 km/h safe limit on expressway stretch. Auditory chime emitted to helmet speaker.',
        latitude: 18.5312,
        longitude: 73.8645,
        speedKmh: 84.2,
        peakGForce: 1.34,
        timestamp: now.subtract(const Duration(minutes: 18)),
        alertSent: false,
      ),
      IncidentReport(
        id: 'inc-003',
        type: IncidentType.alcoholInterlock,
        severity: IncidentSeverity.high,
        title: 'Alcohol Prevention Interlock',
        description: 'Pre-ride breath alcohol detected at 265 ppm (above 200 ppm limit). Engine relay locked successfully.',
        latitude: 18.5140,
        longitude: 73.8410,
        speedKmh: 0.0,
        peakGForce: 1.0,
        timestamp: now.subtract(const Duration(hours: 4, minutes: 12)),
        alertSent: true,
      ),
      IncidentReport(
        id: 'inc-004',
        type: IncidentType.crashDetected,
        severity: IncidentSeverity.critical,
        title: 'Fall & Severe Impact Detected (Simulated)',
        description: '6.4 G high-impact shock registered by MPU6050 accelerometer with 78° tilt. SOS countdown initiated.',
        latitude: 18.5089,
        longitude: 73.8291,
        speedKmh: 45.0,
        peakGForce: 6.4,
        timestamp: now.subtract(const Duration(days: 1, hours: 2)),
        alertSent: true,
      ),
    ];
  }
}
