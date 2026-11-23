import 'package:flutter/material.dart';

/// AppColors defines the central color palette for Smart Helmet 2.0.
/// Follows a dark navy/black background with electric blue/cyan accents,
/// safe green indicators, and danger red alerts.
class AppColors {
  // Background Colors
  static const Color backgroundPrimary = Color(0xFF080C16);
  static const Color backgroundSecondary = Color(0xFF0F172A);
  static const Color backgroundCard = Color(0xFF131D36);
  static const Color backgroundCardLight = Color(0xFF1B284A);
  static const Color backgroundElevated = Color(0xFF202E52);

  // Accent & Brand Colors
  static const Color cyanAccent = Color(0xFF00E5FF);
  static const Color cyberCyan = cyanAccent;
  static const Color electricBlue = Color(0xFF0070F3);
  static const Color cyanGlow = Color(0x3300E5FF);
  static const Color blueLight = Color(0xFF38BDF8);
  static const Color blueDark = Color(0xFF0369A1);
  static const Color accentOrange = Color(0xFFFF9100);

  // Status & Safety Colors
  static const Color statusSafe = Color(0xFF00E676);       // Crisp Green for Safe
  static const Color statusSafeGlow = Color(0x3300E676);
  static const Color statusWarning = Color(0xFFFFAB00);    // Amber for Caution
  static const Color statusWarningGlow = Color(0x33FFAB00);
  static const Color statusEmergency = Color(0xFFFF1744);  // Neon Red for Alerts/SOS
  static const Color statusAlert = statusEmergency;
  static const Color statusEmergencyGlow = Color(0x33FF1744);
  static const Color statusOffline = Color(0xFF64748B);    // Slate grey

  // Typography Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textCyan = Color(0xFF00E5FF);

  // Borders & Dividers
  static const Color borderSubtle = Color(0xFF1E293B);
  static const Color cardBorder = borderSubtle;
  static const Color borderHighlight = Color(0xFF2E3E66);
  static const Color borderNeon = Color(0xFF00E5FF);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00E5FF), Color(0xFF0070F3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emergencyGradient = LinearGradient(
    colors: [Color(0xFFFF1744), Color(0xFFB71C1C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient safeGradient = LinearGradient(
    colors: [Color(0xFF00E676), Color(0xFF009624)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF131D36), Color(0xFF0F172A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF162544), Color(0xFF0A0F1D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
