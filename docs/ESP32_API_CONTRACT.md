# Smart Helmet 2.0 — ESP32 Wi-Fi HTTP REST API Contract

**Document Version:** 1.0.0  
**Target Hardware:** ESP32 Dual-Core (FreeRTOS)  
**Client Application:** Smart Helmet 2.0 Mobile App (Flutter)  
**Protocol:** HTTP/1.1 REST over Wi-Fi  
**Default Host / AP IP:** `http://192.168.4.1:80` (SoftAP Mode: `ESP32_SmartHelmet_AP`)  

---

## 1. Network Topology & Modes

1. **Access Point (SoftAP) Mode (Default for Vehicle/Exhibition):**
   - **SSID:** `ESP32_SmartHelmet_2.0`
   - **Password:** `SmartHelmet2026`
   - **Static Gateway IP:** `192.168.4.1`
   - **Port:** `80`
   
2. **Station (STA) Mode (Local Router / Hotspot):**
   - Connects to rider's smartphone mobile hotspot or exhibition router via DHCP.
   - The assigned IP address (e.g. `192.168.1.150`) is entered into the mobile app's connection settings.

---

## 2. API Endpoints Specification

### 2.1. System Status Endpoint

#### `GET /api/status`
Returns general device telemetry, firmware version, battery state, and peripheral flags.

- **Request:**
  ```http
  GET /api/status HTTP/1.1
  Host: 192.168.4.1
  Accept: application/json
  ```

- **Response (HTTP 200 OK):**
  ```json
  {
    "device_name": "ESP32_SmartHelmet_2.0",
    "mac_address": "24:6F:28:B3:7A:9C",
    "firmware_version": "v2.1.0-Release",
    "battery_level": 88,
    "battery_voltage": 3.92,
    "is_charging": false,
    "wifi_rssi": -58,
    "uptime_seconds": 1845,
    "ignition_relay_active": true,
    "night_lights_active": false
  }
  ```

---

### 2.2. Safety Sensors Endpoint

#### `GET /api/sensors`
Returns pre-ride safety interlock readings (IR crown sensor, chin strap switch, MQ-3 alcohol breathalyzer, and environmental sensors).

- **Request:**
  ```http
  GET /api/sensors HTTP/1.1
  Host: 192.168.4.1
  Accept: application/json
  ```

- **Response (HTTP 200 OK):**
  ```json
  {
    "helmet_worn": true,
    "buckle_latched": true,
    "alcohol_ppm": 42.5,
    "alcohol_threshold_ppm": 200.0,
    "ignition_unlocked": true,
    "temperature_c": 28.4,
    "humidity_pct": 52.0,
    "timestamp_ms": 1729681200000
  }
  ```

*Note on Safety Interlock Logic:*
`ignition_unlocked` must only be `true` if `helmet_worn == true && alcohol_ppm < 200.0`. If either condition is violated, the ESP32 must trip the relay low and report `ignition_unlocked: false`.

---

### 2.3. Location & Motion Telemetry Endpoint

#### `GET /api/location`
Returns NEO-6M GPS coordinates and MPU6050 6-axis accelerometer/gyroscope readings.

- **Request:**
  ```http
  GET /api/location HTTP/1.1
  Host: 192.168.4.1
  Accept: application/json
  ```

- **Response (HTTP 200 OK):**
  ```json
  {
    "latitude": 18.52043,
    "longitude": 73.85674,
    "altitude_m": 562.0,
    "speed_kmh": 41.5,
    "heading_deg": 48.0,
    "satellites": 9,
    "fix_quality": 1,
    "accel_x": 0.12,
    "accel_y": -0.05,
    "accel_z": 9.81,
    "pitch_deg": 3.5,
    "roll_deg": -1.8,
    "impact_detected": false,
    "impact_force_g": 1.02,
    "trip_distance_km": 14.8,
    "trip_duration_sec": 1620,
    "max_speed_kmh": 68.0
  }
  ```

---

### 2.4. Safety Events & Blackbox Endpoint

#### `GET /api/events`
Returns recent crash events, alcohol lockout triggers, or emergency alerts logged in ESP32 RAM/SPIFFS flash storage.

- **Request:**
  ```http
  GET /api/events HTTP/1.1
  Host: 192.168.4.1
  Accept: application/json
  ```

- **Response (HTTP 200 OK):**
  ```json
  {
    "events_count": 2,
    "events": [
      {
        "id": "EVT-101",
        "type": "ALCOHOL_LOCKOUT",
        "severity": "HIGH",
        "detail": "Alcohol 245 ppm detected during pre-ride check. Ignition locked.",
        "timestamp_sec": 1200
      },
      {
        "id": "EVT-102",
        "type": "IMPACT_SPIKE",
        "severity": "CRITICAL",
        "detail": "5.8G impact registered by MPU6050 with 72 deg tilt.",
        "timestamp_sec": 1800
      }
    ]
  }
  ```

---

### 2.5. Emergency Distress Broadcast Endpoint

#### `POST /api/sos`
Instructs the ESP32 to immediately activate its onboard piezoelectric alarm buzzer, flash high-lumen warning LEDs, and transmit emergency SMS via SIM800L GSM modem.

- **Request:**
  ```http
  POST /api/sos HTTP/1.1
  Host: 192.168.4.1
  Content-Type: application/json

  {
    "alert_type": "CRASH_SOS",
    "latitude": 18.52043,
    "longitude": 73.85674,
    "impact_g": 6.4,
    "timestamp": "2026-11-23T19:30:00Z"
  }
  ```

- **Response (HTTP 200 OK):**
  ```json
  {
    "status": "SOS_DISPATCHED",
    "buzzer_active": true,
    "gsm_sms_sent": true,
    "message": "Alarm activated and SMS dispatched to emergency contacts."
  }
  ```

---

### 2.6. Engine Ignition Relay Control Endpoint

#### `POST /api/ignition`
Manually command the 12V starter motor relay (overridden by safety rules).

- **Request:**
  ```http
  POST /api/ignition HTTP/1.1
  Host: 192.168.4.1
  Content-Type: application/json

  {
    "unlock": true
  }
  ```

- **Response (HTTP 200 OK):**
  ```json
  {
    "success": true,
    "ignition_unlocked": true,
    "relay_state": "CLOSED"
  }
  ```

---

### 2.7. Helmet Night LED Lights Endpoint

#### `POST /api/lights`
Toggle the rear LED safety strips for night visibility.

- **Request:**
  ```http
  POST /api/lights HTTP/1.1
  Host: 192.168.4.1
  Content-Type: application/json

  {
    "active": true
  }
  ```

- **Response (HTTP 200 OK):**
  ```json
  {
    "success": true,
    "night_lights_active": true
  }
  ```

---

## 3. Reference ESP32 Arduino C++ Code Skeleton

```cpp
#include <WiFi.h>
#include <WebServer.h>
#include <ArduinoJson.h>

const char* ssid = "ESP32_SmartHelmet_2.0";
const char* password = "SmartHelmet2026";

WebServer server(80);

void handleStatus() {
  StaticJsonDocument<256> doc;
  doc["device_name"] = "ESP32_SmartHelmet_2.0";
  doc["mac_address"] = WiFi.macAddress();
  doc["firmware_version"] = "v2.1.0-Release";
  doc["battery_level"] = 92;
  doc["wifi_rssi"] = WiFi.RSSI();
  doc["night_lights_active"] = false;

  String response;
  serializeJson(doc, response);
  server.send(200, "application/json", response);
}

void handleSensors() {
  StaticJsonDocument<256> doc;
  doc["helmet_worn"] = digitalRead(18) == LOW; // Active-low IR crown sensor
  doc["buckle_latched"] = digitalRead(19) == LOW; // Chin buckle microswitch
  doc["alcohol_ppm"] = analogRead(34) * (500.0 / 4095.0); // MQ-3 analog read
  doc["ignition_unlocked"] = (doc["helmet_worn"] && doc["alcohol_ppm"] < 200.0);
  doc["temperature_c"] = 28.5;
  doc["humidity_pct"] = 54.0;

  String response;
  serializeJson(doc, response);
  server.send(200, "application/json", response);
}

void setup() {
  Serial.begin(115200);
  pinMode(18, INPUT_PULLUP); // IR sensor
  pinMode(19, INPUT_PULLUP); // Buckle switch
  pinMode(23, OUTPUT);       // 12V Relay

  WiFi.softAP(ssid, password);
  Serial.print("Access Point IP: ");
  Serial.println(WiFi.softAPIP());

  server.on("/api/status", HTTP_GET, handleStatus);
  server.on("/api/sensors", HTTP_GET, handleSensors);
  // Add additional endpoints...
  server.begin();
}

void loop() {
  server.handleClient();
}
```
