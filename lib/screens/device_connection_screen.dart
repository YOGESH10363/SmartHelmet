import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../models/helmet_state.dart';
import '../providers/app_state_provider.dart';
import '../widgets/common/custom_app_bar.dart';
import '../widgets/common/custom_button.dart';
import '../widgets/common/glow_container.dart';
import '../widgets/common/status_badge.dart';

/// Screen: ESP32 Wi-Fi REST Connection & Diagnostic Center.
class DeviceConnectionScreen extends StatefulWidget {
  final AppStateProvider stateProvider;

  const DeviceConnectionScreen({super.key, required this.stateProvider});

  @override
  State<DeviceConnectionScreen> createState() => _DeviceConnectionScreenState();
}

class _DeviceConnectionScreenState extends State<DeviceConnectionScreen> {
  late final TextEditingController _ipController;
  late final TextEditingController _portController;

  bool _isConnecting = false;
  bool _isTestingApi = false;
  String? _testResultText;
  bool? _testResultSuccess;

  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController(text: widget.stateProvider.esp32IpAddress);
    _portController = TextEditingController(text: widget.stateProvider.esp32Port.toString());
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  void _handleConnect() async {
    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 80;

    if (ip.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid IP address (e.g., 192.168.4.1)')),
      );
      return;
    }

    setState(() {
      _isConnecting = true;
      _testResultText = null;
    });

    final success = await widget.stateProvider.connectToEsp32(ip, port: port);

    if (mounted) {
      setState(() => _isConnecting = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connected to ESP32 at http://$ip:$port'),
            backgroundColor: AppColors.statusSafe,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to reach ESP32 at $ip:$port (Check Wi-Fi connection)'),
            backgroundColor: AppColors.statusEmergency,
          ),
        );
      }
    }
  }

  void _handleDisconnect() async {
    await widget.stateProvider.disconnectEsp32();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ESP32 Disconnected.'),
          backgroundColor: AppColors.backgroundCardLight,
        ),
      );
    }
  }

  void _testEndpoints() async {
    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 80;

    setState(() {
      _isTestingApi = true;
      _testResultText = 'Pinging http://$ip:$port/api/status...';
      _testResultSuccess = null;
    });

    final result = await widget.stateProvider.testEsp32Connection(ip, port);

    if (mounted) {
      setState(() {
        _isTestingApi = false;
        _testResultSuccess = result['success'] == true;
        if (_testResultSuccess!) {
          _testResultText = 'HTTP 200 OK (${result['latency_ms']} ms)\nResponse: ${result['data']}';
        } else {
          _testResultText = 'Host Unreachable (${result['latency_ms']} ms)\nReason: ${result['error']}';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final helmet = widget.stateProvider.helmetState;
    final isDemoMode = widget.stateProvider.isDemoMode;

    BadgeType badgeType;
    String statusLabel;

    if (isDemoMode) {
      badgeType = BadgeType.info;
      statusLabel = 'DEMO MODE ACTIVE';
    } else {
      switch (helmet.connectionStatus) {
        case ConnectionStatus.connected:
          badgeType = BadgeType.safe;
          statusLabel = 'CONNECTED (WI-FI)';
          break;
        case ConnectionStatus.connecting:
          badgeType = BadgeType.info;
          statusLabel = 'CONNECTING...';
          break;
        case ConnectionStatus.reconnecting:
          badgeType = BadgeType.warning;
          statusLabel = 'RECONNECTING (RETRY)';
          break;
        case ConnectionStatus.disconnected:
        case ConnectionStatus.error:
        case ConnectionStatus.scanning:
          badgeType = BadgeType.offline;
          statusLabel = 'DISCONNECTED';
          break;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: CustomAppBar(
        title: 'ESP32 Wi-Fi IoT Gateway',
        subtitle: 'HTTP REST API Layer',
        helmetState: helmet,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Connection Status Header Card
              GlowContainer(
                borderColor: badgeType == BadgeType.safe
                    ? AppColors.statusSafe.withOpacity(0.4)
                    : (badgeType == BadgeType.warning
                        ? AppColors.statusWarning.withOpacity(0.4)
                        : AppColors.borderSubtle),
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: (isDemoMode ? AppColors.cyanAccent : (helmet.isConnected ? AppColors.statusSafe : AppColors.statusOffline)).withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isDemoMode ? Icons.hub_outlined : Icons.wifi_tethering,
                                color: isDemoMode ? AppColors.cyanAccent : (helmet.isConnected ? AppColors.statusSafe : AppColors.statusOffline),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isDemoMode ? 'Exhibition Simulator' : helmet.deviceName,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isDemoMode ? 'Local High-Fidelity Simulation' : widget.stateProvider.esp32BaseUrl,
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontFamily: 'monospace'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        StatusBadge(label: statusLabel, type: badgeType),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(color: AppColors.borderSubtle),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatusPill(
                          label: 'PROTOCOL',
                          value: isDemoMode ? 'MOCK STREAM' : 'HTTP/1.1 REST',
                          color: AppColors.cyanAccent,
                        ),
                        Container(width: 1, height: 24, color: AppColors.borderSubtle),
                        _StatusPill(
                          label: 'POLL FREQ',
                          value: '1.0 SEC (1 Hz)',
                          color: AppColors.textSecondary,
                        ),
                        Container(width: 1, height: 24, color: AppColors.borderSubtle),
                        _StatusPill(
                          label: 'TIMEOUT',
                          value: '3000 MS',
                          color: AppColors.statusWarning,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // Switch between Physical ESP32 and Demo Mode
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: !isDemoMode ? AppColors.cyanAccent.withOpacity(0.12) : Colors.transparent,
                        side: BorderSide(
                          color: !isDemoMode ? AppColors.cyanAccent : AppColors.borderSubtle,
                        ),
                      ),
                      onPressed: () {
                        if (isDemoMode) {
                          _handleConnect();
                        }
                      },
                      icon: const Icon(Icons.wifi, size: 16),
                      label: const Text('Real ESP32 Mode'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: isDemoMode ? AppColors.cyanAccent.withOpacity(0.12) : Colors.transparent,
                        side: BorderSide(
                          color: isDemoMode ? AppColors.cyanAccent : AppColors.borderSubtle,
                        ),
                      ),
                      onPressed: () {
                        if (!isDemoMode) {
                          widget.stateProvider.switchToDemoMode();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Switched to Exhibition Demo Mode.'),
                              backgroundColor: AppColors.cyanAccent,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.hub_outlined, size: 16),
                      label: const Text('Demo Mode'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // ESP32 Network Settings Inputs
              const Text(
                'ESP32 WI-FI REST CONFIGURATION',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.cyanAccent, letterSpacing: 0.8),
              ),
              const SizedBox(height: 10),
              GlowContainer(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _ipController,
                            style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                            decoration: const InputDecoration(
                              labelText: 'ESP32 IP Address',
                              hintText: '192.168.4.1',
                              prefixIcon: Icon(Icons.dns_outlined, color: AppColors.cyanAccent),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: _portController,
                            style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Port',
                              hintText: '80',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Quick Preset Buttons
                    Row(
                      children: [
                        const Text('Presets: ', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                        GestureDetector(
                          onTap: () {
                            _ipController.text = '192.168.4.1';
                            _portController.text = '80';
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundSecondary,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.borderSubtle),
                            ),
                            child: const Text('ESP32 AP (192.168.4.1)', style: TextStyle(fontSize: 10, color: AppColors.cyanAccent)),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            _ipController.text = '192.168.1.150';
                            _portController.text = '80';
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundSecondary,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.borderSubtle),
                            ),
                            child: const Text('Router LAN (192.168.1.150)', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Connect & Disconnect Buttons
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: helmet.isConnected && !isDemoMode ? 'RECONNECT' : 'CONNECT TO ESP32',
                            variant: ButtonVariant.primary,
                            icon: Icons.link,
                            isLoading: _isConnecting,
                            onPressed: _handleConnect,
                          ),
                        ),
                        if (helmet.isConnected && !isDemoMode) ...[
                          const SizedBox(width: 10),
                          CustomButton(
                            text: 'DISCONNECT',
                            variant: ButtonVariant.danger,
                            icon: Icons.link_off,
                            onPressed: _handleDisconnect,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // Diagnostic Tool: Ping / Test Endpoints
              const Text(
                'ENDPOINT VERIFICATION & DIAGNOSTICS',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.cyanAccent, letterSpacing: 0.8),
              ),
              const SizedBox(height: 10),
              GlowContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomButton(
                      text: 'PING /api/status ENDPOINT',
                      variant: ButtonVariant.secondary,
                      icon: Icons.sensors,
                      width: double.infinity,
                      isLoading: _isTestingApi,
                      onPressed: _testEndpoints,
                    ),
                    if (_testResultText != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundSecondary,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _testResultSuccess == true
                                ? AppColors.statusSafe
                                : (_testResultSuccess == false ? AppColors.statusEmergency : AppColors.cyanAccent),
                          ),
                        ),
                        child: Text(
                          _testResultText!,
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: _testResultSuccess == true
                                ? AppColors.statusSafe
                                : (_testResultSuccess == false ? AppColors.statusEmergency : Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // Documented API Endpoints Reference for Exhibition Reviewers
              const Text(
                'REGISTERED ESP32 REST ENDPOINTS',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.cyanAccent, letterSpacing: 0.8),
              ),
              const SizedBox(height: 10),
              GlowContainer(
                padding: const EdgeInsets.all(16),
                child: const Column(
                  children: [
                    _EndpointRow(method: 'GET', path: '/api/status', desc: 'Battery, WiFi RSSI, Firmware, Relay status'),
                    Divider(color: AppColors.borderSubtle, height: 16),
                    _EndpointRow(method: 'GET', path: '/api/sensors', desc: 'Helmet IR, MQ-3 alcohol PPM, Buckle switch'),
                    Divider(color: AppColors.borderSubtle, height: 16),
                    _EndpointRow(method: 'GET', path: '/api/location', desc: 'GPS Lat/Lng, speed, heading, MPU6050 G-force'),
                    Divider(color: AppColors.borderSubtle, height: 16),
                    _EndpointRow(method: 'GET', path: '/api/events', desc: 'Recent crash impacts & safety interlock logs'),
                    Divider(color: AppColors.borderSubtle, height: 16),
                    _EndpointRow(method: 'POST', path: '/api/sos', desc: 'Trigger helmet distress buzzer & SIM800L SMS'),
                    Divider(color: AppColors.borderSubtle, height: 16),
                    _EndpointRow(method: 'POST', path: '/api/ignition', desc: 'Relay command {"unlock": true/false}'),
                    Divider(color: AppColors.borderSubtle, height: 16),
                    _EndpointRow(method: 'POST', path: '/api/lights', desc: 'Helmet LED night lights {"active": true/false}'),
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

class _StatusPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatusPill({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color, fontFamily: 'monospace')),
      ],
    );
  }
}

class _EndpointRow extends StatelessWidget {
  final String method;
  final String path;
  final String desc;

  const _EndpointRow({required this.method, required this.path, required this.desc});

  @override
  Widget build(BuildContext context) {
    final isPost = method == 'POST';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: (isPost ? AppColors.statusWarning : AppColors.cyanAccent).withOpacity(0.18),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            method,
            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: isPost ? AppColors.statusWarning : AppColors.cyanAccent),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(path, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'monospace')),
              const SizedBox(height: 2),
              Text(desc, style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}
