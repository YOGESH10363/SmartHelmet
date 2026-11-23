# Smart Helmet 2.0 — IoT-Based Smart Safety Helmet Mobile Application

**Academic Innovation & Technology Exhibition 2026**  
*Department of IoT & Embedded Systems*

---

## 1. Project Overview

**Smart Helmet 2.0** is an enterprise-grade IoT safety and telemetry system designed to reduce two-wheeler fatalities through proactive prevention and autonomous reactive emergency care.

### Key Pillars:
1. **Mandatory Helmet Wearing Verification:** Optical infrared sensors and chin buckle switches verify helmet presence before authorizing the vehicle's engine.
2. **Breath Alcohol Interlock (DUI Prevention):** Integrated MQ-3 electrochemical sensor monitors breath alcohol. If alcohol exceeds 200 PPM, the 12V motorcycle starter relay cuts ignition immediately.
3. **Autonomous Collision & Fall Detection:** A 6-axis MPU6050 accelerometer and gyroscope register peak impact forces above 4.2 G and critical tilt angles (>65°), initiating an automated emergency SOS countdown.
4. **Autonomous Emergency SOS Dispatch:** Transmits distress alerts with live NEO-6M GPS coordinates to emergency contacts, ambulance services, and local police via SIM800L GSM and Wi-Fi.
5. **Commercial Telemetry Cockpit:** Displays real-time speed, artificial horizon tilt, heading, satellite tracking, and battery health in a dark premium cyber-inspired interface.

---

## 2. Technology Stack & Architecture

- **Framework:** Flutter 3.50.1 / Dart 3.14.0
- **Design System:** Material 3 with Dark Premium Technology Palette (`#080C16`, `#00E5FF`, `#00E676`, `#FF1744`)
- **State Management:** Reactive `ChangeNotifier` and `ListenableBuilder` (Zero third-party bloatware, zero version conflicts)
- **IoT Communication Layer:** Dual-Mode Architecture:
  - **Physical ESP32 Mode:** HTTP/1.1 REST API over Wi-Fi (SoftAP or Station LAN)
  - **Exhibition Demo Mode:** Real-time simulated telemetry for indoor exhibition halls where physical hardware is off or Wi-Fi is unavailable
- **Hardware Integration:** ESP32 Dual-Core (FreeRTOS), MQ-3, MPU6050, NEO-6M GPS, SIM800L GSM, 12V Relay

---

## 3. Project Directory Structure

```
SmartHelmet/
├── android/                   # Android native project (compileSdk 34, minSdk 24, Kotlin JVM 17)
│   ├── app/
│   │   ├── build.gradle.kts   # Android build configuration
│   │   └── src/main/AndroidManifest.xml # Permissions (Bluetooth, GPS, Internet, SMS, Call)
│   └── gradle/wrapper/        # Gradle 9.7.1 wrapper
├── docs/
│   └── ESP32_API_CONTRACT.md  # Official HTTP REST API schema & C++ Arduino firmware code
├── lib/
│   ├── constants/
│   │   ├── app_colors.dart    # Cyber cyan, navy black, safe green, alert red
│   │   ├── app_text_styles.dart # Modern tech typography
│   │   ├── app_constants.dart # Thresholds (200 PPM, 4.2 G, 10s SOS)
│   │   └── app_theme.dart     # Material 3 dark theme
│   ├── models/
│   │   ├── helmet_state.dart  # Connection, RSSI, battery, firmware
│   │   ├── sensor_data.dart   # Helmet IR, MQ-3 alcohol, relay, GSM status
│   │   ├── telemetry_data.dart# Speed, MPU6050 vectors, GPS, history buffer
│   │   ├── emergency_contact.dart # Contact directory
│   │   ├── incident_report.dart # Safety audit logs
│   │   └── user_profile.dart  # Rider credentials & blood group
│   ├── services/
│   │   ├── iot_service.dart   # Abstract IoT interface contract
│   │   ├── mock_iot_service.dart # High-fidelity exhibition simulator
│   │   ├── esp32_rest_service.dart # Wi-Fi HTTP REST client (GET/POST)
│   │   ├── emergency_service.dart # 10s countdown & dispatch manager
│   │   └── storage_service.dart # Persistence & incident blackbox
│   ├── providers/
│   │   └── app_state_provider.dart # Central reactive coordinator
│   ├── widgets/
│   │   ├── common/            # GlowContainer, StatusBadge, CustomButton, StatCard, CustomAppBar
│   │   ├── dashboard/         # SpeedometerGauge, HelmetStatusCard, AlcoholStatusCard
│   │   ├── telemetry/         # AccelerationChart, GyroHorizonCard, GForceMeter
│   │   └── emergency/         # SosCountdownDialog
│   ├── screens/
│   │   ├── splash_screen.dart # Screen 1: Animated branding & startup
│   │   ├── welcome_screen.dart# Screen 2: Feature onboarding
│   │   ├── login_screen.dart  # Screen 3: Rider ID authentication
│   │   ├── registration_screen.dart # Screen 4: Device & rider enrollment
│   │   ├── dashboard_screen.dart # Screen 5: Home Cockpit HUD
│   │   ├── device_connection_screen.dart # Screen 6: ESP32 Wi-Fi Gateway
│   │   ├── helmet_safety_screen.dart # Screen 7: Interlock & checklist
│   │   ├── accident_monitoring_screen.dart # Screen 8: MPU6050 & crash live feeds
│   │   ├── gps_tracking_screen.dart # Screen 9: NEO-6M radar map
│   │   ├── emergency_sos_screen.dart # Screen 10: SOS central & rescue contacts
│   │   ├── history_reports_screen.dart # Screen 11: Safety audit blackbox
│   │   ├── settings_screen.dart # Screen 12: Calibration & thresholds
│   │   ├── about_project_screen.dart # Screen 13: Academic exhibition presentation
│   │   ├── profile_screen.dart # Profile & quick module shortcuts
│   │   └── main_navigation_shell.dart # 5-Tab persistent navigation bar
│   └── main.dart              # Application entry point
├── test/
│   ├── widget_test.dart       # Widget navigation test suite
│   └── unit_test.dart         # Pure Dart domain & interlock test suite
└── pubspec.yaml               # Flutter package configuration
```

---

## 4. How to Run the Application

### Prerequisites
- **Flutter SDK:** 3.24+ (installed at `D:\flutter`)
- **Java JDK:** 17 (Microsoft OpenJDK at `C:\Program Files\Microsoft\jdk-17.0.21.102-hotspot`)
- **Android SDK:** Platform 34 (at `C:\Users\YOGESH\AppData\Local\Android\Sdk`)

### Option A: Run on Connected Android Device or Emulator
```powershell
# 1. Connect Android phone via USB with USB Debugging enabled
flutter devices

# 2. Run debug app on Android device
flutter run -d <device-id>
```

### Option B: Run in Chrome / Microsoft Edge Web Browser
```powershell
flutter run -d edge
# or
flutter run -d chrome
```

### Option C: Run Automated Tests
```powershell
# Static analysis (verifies zero warnings or errors)
flutter analyze

# Domain logic & sensor interlock test suite
dart run test/unit_test.dart
```

---

## 5. ESP32 Wi-Fi HTTP REST API Specification

The mobile application communicates with the ESP32 via HTTP REST on `http://192.168.4.1:80`:

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/status` | Device battery level, firmware version, and Wi-Fi RSSI |
| `GET` | `/api/sensors` | Crown optical IR, chin buckle switch, and MQ-3 alcohol PPM |
| `GET` | `/api/location` | GPS Lat/Lng, altitude, speed, heading, and MPU6050 G-force |
| `GET` | `/api/events` | Recent accident impacts and safety interlock logs |
| `POST` | `/api/sos` | Trigger emergency acoustic siren and SIM800L SMS broadcast |
| `POST` | `/api/ignition` | Remote relay command `{"unlock": true/false}` |
| `POST` | `/api/lights` | Toggle helmet night safety LED strips `{"active": true/false}` |

Full schema specifications and a working Arduino C++ skeleton are documented in [`docs/ESP32_API_CONTRACT.md`](docs/ESP32_API_CONTRACT.md).

---

## 6. Academic Exhibition Features

- **Data Provenance Transparency:** Clear distinction between `LIVE ESP32 HARDWARE STREAM` and `DEMO SIMULATOR FEED`.
- **Interactive Simulation Testing Controls:**
  - Wear / Remove Helmet toggle (instantly demonstrates engine interlock cut-off).
  - Alcohol PPM slider (demonstrates 200 PPM DUI lockout).
  - Test Crash Impact button (initiates 10-second pulsating SOS countdown with cancellation and dispatch options).
- **Exportable Safety Reports:** Export ride logs and safety incident audits as PDF/CSV.
#   S m a r t H e l m e t  
 