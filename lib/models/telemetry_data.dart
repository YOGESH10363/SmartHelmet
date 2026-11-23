import 'dart:math';
import '../constants/app_constants.dart';

/// Captures motion, accelerometer, gyroscope, and GPS telemetry.
class TelemetryData {
  final double speedKmh;
  final double accelX; // in m/s^2
  final double accelY;
  final double accelZ;
  final double pitchAngle; // in degrees
  final double rollAngle;  // in degrees
  final double latitude;
  final double longitude;
  final double altitudeMeters;
  final double headingDegrees;
  final int gpsSatellites;
  final bool isImpactDetected;
  final double lastImpactForceG;
  final double tripDistanceKm;
  final int tripDurationSeconds;
  final double maxSpeedKmh;
  final DateTime timestamp;
  final bool isRealHardware;
  final bool isGpsFixValid;
  final double hdopAccuracy;

  // History buffer for live strip chart
  final List<double> historyGForce;
  final List<double> historyAccelX;
  final List<double> historyAccelY;
  final List<double> historyAccelZ;

  // Geographic waypoint breadcrumb trail
  final List<Map<String, double>> waypointTrail;

  const TelemetryData({
    this.speedKmh = 42.5,
    this.accelX = 0.2,
    this.accelY = 0.1,
    this.accelZ = 9.8,
    this.pitchAngle = 4.0,
    this.rollAngle = -2.5,
    this.latitude = 18.52043,
    this.longitude = 73.85674,
    this.altitudeMeters = 560.0,
    this.headingDegrees = 45.0,
    this.gpsSatellites = 9,
    this.isImpactDetected = false,
    this.lastImpactForceG = 1.02,
    this.tripDistanceKm = 14.8,
    this.tripDurationSeconds = 1620,
    this.maxSpeedKmh = 68.0,
    required this.timestamp,
    this.isRealHardware = false,
    this.isGpsFixValid = true,
    this.hdopAccuracy = 1.1,
    this.historyGForce = const [1.0, 1.02, 0.98, 1.01, 1.05, 1.0, 0.99, 1.02, 1.04, 1.0],
    this.historyAccelX = const [0.1, 0.15, -0.05, 0.2, 0.1, -0.1, 0.05, 0.12, 0.08, 0.1],
    this.historyAccelY = const [-0.05, 0.1, -0.1, 0.08, 0.02, -0.05, 0.03, -0.08, 0.05, 0.0],
    this.historyAccelZ = const [9.8, 9.82, 9.78, 9.81, 9.85, 9.8, 9.79, 9.82, 9.84, 9.81],
    this.waypointTrail = const [
      {'lat': 18.5180, 'lng': 73.8540},
      {'lat': 18.5190, 'lng': 73.8550},
      {'lat': 18.5198, 'lng': 73.8558},
      {'lat': 18.52043, 'lng': 73.85674},
    ],
  });

  /// Validates whether received coordinates represent a genuine physical location
  bool get areCoordinatesValid {
    if (!isGpsFixValid) return false;
    if (latitude == 0.0 && longitude == 0.0) return false; // Null Island
    return latitude >= -90.0 && latitude <= 90.0 && longitude >= -180.0 && longitude <= 180.0;
  }

  /// Computed instantaneous G-Force magnitude.
  double get totalGForce {
    final magnitude = sqrt((accelX * accelX) + (accelY * accelY) + (accelZ * accelZ));
    return double.parse((magnitude / 9.80665).toStringAsFixed(2));
  }

  /// Whether current motion exceeds safety accident threshold.
  bool get isDangerousMotion {
    return totalGForce >= AppConstants.gForceAccidentThreshold ||
        pitchAngle.abs() >= AppConstants.tiltAngleAccidentThreshold ||
        rollAngle.abs() >= AppConstants.tiltAngleAccidentThreshold;
  }

  /// Human-readable GPS signal status
  String get gpsSignalStatus {
    if (!isGpsFixValid || gpsSatellites == 0) return 'NO SATELLITE FIX (0 SATS)';
    if (gpsSatellites < 4) return 'WEAK 2D FIX ($gpsSatellites SATS)';
    return 'EXCELLENT 3D FIX ($gpsSatellites SATS)';
  }

  TelemetryData copyWith({
    double? speedKmh,
    double? accelX,
    double? accelY,
    double? accelZ,
    double? pitchAngle,
    double? rollAngle,
    double? latitude,
    double? longitude,
    double? altitudeMeters,
    double? headingDegrees,
    int? gpsSatellites,
    bool? isImpactDetected,
    double? lastImpactForceG,
    double? tripDistanceKm,
    int? tripDurationSeconds,
    double? maxSpeedKmh,
    DateTime? timestamp,
    bool? isRealHardware,
    bool? isGpsFixValid,
    double? hdopAccuracy,
    List<double>? historyGForce,
    List<double>? historyAccelX,
    List<double>? historyAccelY,
    List<double>? historyAccelZ,
    List<Map<String, double>>? waypointTrail,
  }) {
    return TelemetryData(
      speedKmh: speedKmh ?? this.speedKmh,
      accelX: accelX ?? this.accelX,
      accelY: accelY ?? this.accelY,
      accelZ: accelZ ?? this.accelZ,
      pitchAngle: pitchAngle ?? this.pitchAngle,
      rollAngle: rollAngle ?? this.rollAngle,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitudeMeters: altitudeMeters ?? this.altitudeMeters,
      headingDegrees: headingDegrees ?? this.headingDegrees,
      gpsSatellites: gpsSatellites ?? this.gpsSatellites,
      isImpactDetected: isImpactDetected ?? this.isImpactDetected,
      lastImpactForceG: lastImpactForceG ?? this.lastImpactForceG,
      tripDistanceKm: tripDistanceKm ?? this.tripDistanceKm,
      tripDurationSeconds: tripDurationSeconds ?? this.tripDurationSeconds,
      maxSpeedKmh: maxSpeedKmh ?? this.maxSpeedKmh,
      timestamp: timestamp ?? this.timestamp,
      isRealHardware: isRealHardware ?? this.isRealHardware,
      isGpsFixValid: isGpsFixValid ?? this.isGpsFixValid,
      hdopAccuracy: hdopAccuracy ?? this.hdopAccuracy,
      historyGForce: historyGForce ?? this.historyGForce,
      historyAccelX: historyAccelX ?? this.historyAccelX,
      historyAccelY: historyAccelY ?? this.historyAccelY,
      historyAccelZ: historyAccelZ ?? this.historyAccelZ,
      waypointTrail: waypointTrail ?? this.waypointTrail,
    );
  }
}
