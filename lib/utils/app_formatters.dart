import 'package:flutter/foundation.dart';

/// AppFormatters provides human-readable conversions for telemetry and timestamps.
class AppFormatters {
  static String formatSpeed(double speedKmh) {
    return '${speedKmh.toStringAsFixed(1)} km/h';
  }

  static String formatGForce(double gForce) {
    return '${gForce.toStringAsFixed(2)} G';
  }

  static String formatAlcohol(double ppm) {
    return '${ppm.toStringAsFixed(0)} ppm';
  }

  static String formatDistance(double km) {
    return '${km.toStringAsFixed(1)} km';
  }

  static String formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  static String formatCoordinates(double lat, double lng) {
    final latDir = lat >= 0 ? 'N' : 'S';
    final lngDir = lng >= 0 ? 'E' : 'W';
    return '${lat.abs().toStringAsFixed(4)}°$latDir, ${lng.abs().toStringAsFixed(4)}°$lngDir';
  }

  static String formatDateTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final second = dt.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  static String formatTime(DateTime dt) => formatDateTime(dt);

  static void openGoogleMaps(double lat, double lng) {
    debugPrint('[AppFormatters] Open in Google Maps: https://maps.google.com/?q=$lat,$lng');
  }

  static String formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}
