import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../providers/app_state_provider.dart';
import '../utils/app_formatters.dart';
import '../widgets/common/custom_app_bar.dart';
import '../widgets/common/custom_button.dart';
import '../widgets/common/glow_container.dart';
import '../widgets/common/stat_card.dart';
import '../widgets/common/status_badge.dart';
import 'device_connection_screen.dart';

/// Screen 9: GPS Tracking Screen with NEO-6M satellite telemetry, map, and Google Maps integration.
class GpsTrackingScreen extends StatefulWidget {
  final AppStateProvider stateProvider;

  const GpsTrackingScreen({super.key, required this.stateProvider});

  @override
  State<GpsTrackingScreen> createState() => _GpsTrackingScreenState();
}

class _GpsTrackingScreenState extends State<GpsTrackingScreen> {
  bool _isRefreshing = false;
  double _zoomLevel = 1.0;

  void _handleRefreshLocation() async {
    setState(() => _isRefreshing = true);
    final success = await widget.stateProvider.refreshGpsLocation();

    if (mounted) {
      setState(() => _isRefreshing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'GPS fix refreshed from helmet hardware.' : 'GPS refresh completed.',
          ),
          backgroundColor: AppColors.backgroundCardLight,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _openInGoogleMaps() {
    final telemetry = widget.stateProvider.telemetryData;
    if (!telemetry.areCoordinatesValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot open Google Maps: GPS coordinates are invalid or fix is unavailable.'),
          backgroundColor: AppColors.statusEmergency,
        ),
      );
      return;
    }

    final url = 'https://www.google.com/maps/search/?api=1&query=${telemetry.latitude},${telemetry.longitude}';
    Clipboard.setData(ClipboardData(text: url));

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundCard,
          title: const Row(
            children: [
              Icon(Icons.map, color: AppColors.cyanAccent),
              SizedBox(width: 8),
              Text('Google Maps Link', style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Coordinates Link copied to clipboard:\n',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Text(
                  url,
                  style: const TextStyle(fontSize: 11, color: AppColors.cyanAccent, fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'You can paste this directly into Google Maps or any browser to view the helmet location.',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
          actions: [
            CustomButton(
              text: 'Close',
              height: 38,
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final telemetry = widget.stateProvider.telemetryData;
    final helmet = widget.stateProvider.helmetState;
    final isDemoMode = widget.stateProvider.isDemoMode;
    final areCoordsValid = telemetry.areCoordinatesValid;

    // Determine status badge
    BadgeType signalBadgeType;
    String signalStatusText;

    if (!telemetry.isGpsFixValid || telemetry.gpsSatellites == 0) {
      signalBadgeType = BadgeType.emergency;
      signalStatusText = 'NO GPS FIX (0 SATS)';
    } else if (telemetry.gpsSatellites < 4) {
      signalBadgeType = BadgeType.warning;
      signalStatusText = 'WEAK 2D FIX (${telemetry.gpsSatellites} SATS)';
    } else {
      signalBadgeType = BadgeType.safe;
      signalStatusText = '3D FIX LOCKED (${telemetry.gpsSatellites} SATS)';
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: CustomAppBar(
        title: 'GPS Tracking Telemetry',
        subtitle: 'NEO-6M Geolocation & Navigation Hub',
        helmetState: helmet,
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.cyanAccent),
                  )
                : const Icon(Icons.refresh, color: AppColors.cyanAccent),
            tooltip: 'Refresh GPS Fix',
            onPressed: _isRefreshing ? null : _handleRefreshLocation,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Data Provenance & Source Transparency Banner
              GlowContainer(
                borderColor: isDemoMode ? AppColors.cyanAccent.withOpacity(0.35) : AppColors.statusSafe.withOpacity(0.4),
                glowColor: isDemoMode ? AppColors.cyanGlow : AppColors.statusSafeGlow,
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(
                      isDemoMode ? Icons.hub_outlined : Icons.gps_fixed,
                      color: isDemoMode ? AppColors.cyanAccent : AppColors.statusSafe,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isDemoMode
                                ? 'DATA SOURCE: DEMO LOCATION PRESET'
                                : 'DATA SOURCE: LIVE ESP32 NEO-6M HARDWARE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: isDemoMode ? AppColors.cyanAccent : AppColors.statusSafe,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isDemoMode
                                ? 'Exhibition demo coordinates (Pune, Maharashtra). Not live tracking.'
                                : (areCoordsValid
                                    ? 'Real-time satellite coordinates streamed from physical helmet GPS.'
                                    : 'Hardware connected, but waiting for satellite constellation fix.'),
                            style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    if (isDemoMode)
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => DeviceConnectionScreen(stateProvider: widget.stateProvider),
                            ),
                          );
                        },
                        child: const Text('CONNECT', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.cyanAccent)),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // 2. Interactive Map / Tactical Radar Visualizer
              GlowContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.map_outlined, color: AppColors.cyanAccent, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'TACTICAL GPS POSITION MAP',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        StatusBadge(label: signalStatusText, type: signalBadgeType),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Visual Map Canvas with Zoom & Center Controls
                    Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          height: 240,
                          decoration: BoxDecoration(
                            color: const Color(0xFF070D1B),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: areCoordsValid ? AppColors.cyanAccent.withOpacity(0.3) : AppColors.statusEmergency.withOpacity(0.3),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: areCoordsValid ? AppColors.cyanGlow : AppColors.statusEmergencyGlow,
                                blurRadius: 16,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: areCoordsValid
                                ? CustomPaint(
                                    painter: _TacticalGpsMapPainter(
                                      heading: telemetry.headingDegrees,
                                      zoom: _zoomLevel,
                                      waypoints: telemetry.waypointTrail,
                                    ),
                                  )
                                : const _GpsUnavailableOverlay(),
                          ),
                        ),

                        // Map Zoom Controls Overlay
                        Positioned(
                          right: 12,
                          top: 12,
                          child: Column(
                            children: [
                              _MapControlButton(
                                icon: Icons.add,
                                onTap: () => setState(() => _zoomLevel = (_zoomLevel + 0.3).clamp(0.7, 2.5)),
                                tooltip: 'Zoom In',
                              ),
                              const SizedBox(height: 6),
                              _MapControlButton(
                                icon: Icons.remove,
                                onTap: () => setState(() => _zoomLevel = (_zoomLevel - 0.3).clamp(0.7, 2.5)),
                                tooltip: 'Zoom Out',
                              ),
                              const SizedBox(height: 6),
                              _MapControlButton(
                                icon: Icons.my_location,
                                onTap: () => setState(() => _zoomLevel = 1.0),
                                tooltip: 'Recenter on Helmet',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Formatted Current Coordinates Box
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundSecondary,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.place,
                                color: areCoordsValid ? AppColors.statusSafe : AppColors.statusEmergency,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'CURRENT FIX:',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          Text(
                            areCoordsValid
                                ? '${telemetry.latitude.toStringAsFixed(5)}° N, ${telemetry.longitude.toStringAsFixed(5)}° E'
                                : '--.-----° N, ---.-----° E',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                              color: areCoordsValid ? AppColors.cyanAccent : AppColors.statusEmergency,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // 3. Primary GPS Action Buttons
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'REFRESH LOCATION',
                      variant: ButtonVariant.primary,
                      icon: Icons.refresh,
                      isLoading: _isRefreshing,
                      onPressed: _handleRefreshLocation,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomButton(
                      text: 'OPEN IN GOOGLE MAPS',
                      variant: ButtonVariant.secondary,
                      icon: Icons.open_in_new,
                      onPressed: _openInGoogleMaps,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 4. GPS Detailed Metrics Grid
              const Text(
                'NEO-6M SATELLITE TELEMETRY METRICS',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.cyanAccent, letterSpacing: 0.8),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'ALTITUDE',
                      value: areCoordsValid ? telemetry.altitudeMeters.toStringAsFixed(0) : '--',
                      unit: 'METERS',
                      icon: Icons.terrain,
                      accentColor: AppColors.blueLight,
                      subtitle: 'Height Above MSL',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'BEARING HEADING',
                      value: '${telemetry.headingDegrees.toInt()}°',
                      unit: 'NE',
                      icon: Icons.explore,
                      accentColor: AppColors.cyanAccent,
                      subtitle: 'Compass Direction',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'SPEED OVER GROUND',
                      value: areCoordsValid ? telemetry.speedKmh.toStringAsFixed(1) : '--',
                      unit: 'KM/H',
                      icon: Icons.speed,
                      accentColor: AppColors.statusSafe,
                      subtitle: 'GPS Doppler Speed',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'SATELLITES & HDOP',
                      value: '${telemetry.gpsSatellites}',
                      unit: 'HDOP: ${telemetry.hdopAccuracy}',
                      icon: Icons.satellite_alt,
                      accentColor: areCoordsValid ? AppColors.statusSafe : AppColors.statusEmergency,
                      subtitle: areCoordsValid ? 'High Precision Fix' : 'Waiting for Fix',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Timestamp of last location update
              Center(
                child: Text(
                  'Last location fix received: ${AppFormatters.formatDateTime(telemetry.timestamp)} (${AppFormatters.formatDate(telemetry.timestamp)})',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontFamily: 'monospace'),
                ),
              ),

              const SizedBox(height: 22),

              // 5. Location Permission & Privacy Notice
              GlowContainer(
                borderColor: AppColors.borderHighlight,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.privacy_tip_outlined, color: AppColors.cyanAccent, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'LOCATION PERMISSION & PRIVACY POLICY',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.cyanAccent, letterSpacing: 0.8),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• GPS telemetry is received directly from the onboard ESP32 NEO-6M satellite hardware over local Wi-Fi.\n'
                      '• Real-time location is computed strictly on-device and is never transmitted to cloud ad trackers.\n'
                      '• During an automated accident or manual SOS event, coordinates are dispatched strictly to your verified emergency contacts and emergency rescue hotlines.',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.45),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  const _MapControlButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.backgroundCard.withOpacity(0.85),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderHighlight),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Icon(icon, size: 18, color: AppColors.cyanAccent),
        ),
      ),
    );
  }
}

class _GpsUnavailableOverlay extends StatelessWidget {
  const _GpsUnavailableOverlay();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.statusEmergency.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_off, color: AppColors.statusEmergency, size: 36),
            ),
            const SizedBox(height: 12),
            const Text(
              'GPS SATELLITE FIX UNAVAILABLE',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.statusEmergency),
            ),
            const SizedBox(height: 4),
            const Text(
              'The NEO-6M module has not yet locked onto satellite constellation. Move the helmet outdoors with clear line-of-sight to open sky.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }
}

class _TacticalGpsMapPainter extends CustomPainter {
  final double heading;
  final double zoom;
  final List<Map<String, double>> waypoints;

  _TacticalGpsMapPainter({
    required this.heading,
    required this.zoom,
    required this.waypoints,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // 1. Grid Background lines
    final gridPaint = Paint()
      ..color = AppColors.cyanAccent.withOpacity(0.07)
      ..strokeWidth = 1.0;

    final step = 28.0 * zoom;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 2. Radar range rings (scaled by zoom)
    final ringPaint = Paint()
      ..color = AppColors.cyanAccent.withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawCircle(center, 40 * zoom, ringPaint);
    canvas.drawCircle(center, 80 * zoom, ringPaint);
    canvas.drawCircle(center, 120 * zoom, ringPaint);

    // Crosshairs
    final crossPaint = Paint()
      ..color = AppColors.cyanAccent.withOpacity(0.25)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(center.dx, 10), Offset(center.dx, size.height - 10), crossPaint);
    canvas.drawLine(Offset(10, center.dy), Offset(size.width - 10, center.dy), crossPaint);

    // 3. Breadcrumb polyline trail
    if (waypoints.isNotEmpty) {
      final trailPaint = Paint()
        ..color = AppColors.cyanAccent.withOpacity(0.7)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final path = Path();
      for (int i = 0; i < waypoints.length; i++) {
        // Offset relative to center
        final relX = (i - waypoints.length + 1) * (26.0 * zoom);
        final relY = (waypoints.length - 1 - i) * (14.0 * zoom);
        final pt = Offset(center.dx + relX, center.dy + relY);

        if (i == 0) {
          path.moveTo(pt.dx, pt.dy);
        } else {
          path.lineTo(pt.dx, pt.dy);
        }
      }
      canvas.drawPath(path, trailPaint);
    }

    // 4. Center Rider Beacon Dot
    final glowPaint = Paint()
      ..color = AppColors.statusSafe.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(center, 14, glowPaint);

    final dotPaint = Paint()..color = AppColors.statusSafe;
    canvas.drawCircle(center, 6, dotPaint);

    final innerDot = Paint()..color = Colors.white;
    canvas.drawCircle(center, 2.5, innerDot);

    // 5. Heading orientation pointer
    final angle = heading * (pi / 180.0);
    final arrowTip = Offset(center.dx + 26 * cos(angle), center.dy + 26 * sin(angle));
    final arrowPaint = Paint()
      ..color = AppColors.cyanAccent
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, arrowTip, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant _TacticalGpsMapPainter oldDelegate) {
    return oldDelegate.heading != heading || oldDelegate.zoom != zoom || oldDelegate.waypoints != waypoints;
  }
}
