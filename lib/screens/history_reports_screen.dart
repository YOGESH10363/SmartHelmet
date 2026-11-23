import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../models/helmet_event_record.dart';
import '../providers/app_state_provider.dart';
import '../services/report_export_service.dart';
import '../utils/app_formatters.dart';
import '../widgets/common/custom_app_bar.dart';
import '../widgets/common/custom_button.dart';
import '../widgets/common/glow_container.dart';
import '../widgets/common/status_badge.dart';

enum TimeFilterOption {
  allTime,
  today,
  last24Hours,
  last7Days,
  last30Days,
  customRange,
}

enum ProvenanceFilterOption {
  all,
  hardwareOnly,
  demoOnly,
}

/// Screen 11: History and Reports Screen (Persistent SQLite Blackbox & PDF Audit Reports).
class HistoryReportsScreen extends StatefulWidget {
  final AppStateProvider stateProvider;

  const HistoryReportsScreen({super.key, required this.stateProvider});

  @override
  State<HistoryReportsScreen> createState() => _HistoryReportsScreenState();
}

class _HistoryReportsScreenState extends State<HistoryReportsScreen> {
  final TextEditingController _searchController = TextEditingController();

  HelmetEventType? _selectedCategory; // null = all
  TimeFilterOption _selectedTimeFilter = TimeFilterOption.allTime;
  ProvenanceFilterOption _selectedProvenance = ProvenanceFilterOption.all;
  DateTimeRange? _customDateRange;

  List<HelmetEventRecord> _events = [];
  Map<String, int> _stats = {
    'total': 0,
    'hardware': 0,
    'demo': 0,
    'accidents': 0,
    'sos': 0,
  };
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEvents();
    widget.stateProvider.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    widget.stateProvider.removeListener(_onStateChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) {
      _loadEvents();
    }
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);

    try {
      DateTime? startDate;
      DateTime? endDate;
      final now = DateTime.now();

      switch (_selectedTimeFilter) {
        case TimeFilterOption.today:
          startDate = DateTime(now.year, now.month, now.day);
          endDate = now;
          break;
        case TimeFilterOption.last24Hours:
          startDate = now.subtract(const Duration(hours: 24));
          endDate = now;
          break;
        case TimeFilterOption.last7Days:
          startDate = now.subtract(const Duration(days: 7));
          endDate = now;
          break;
        case TimeFilterOption.last30Days:
          startDate = now.subtract(const Duration(days: 30));
          endDate = now;
          break;
        case TimeFilterOption.customRange:
          if (_customDateRange != null) {
            startDate = _customDateRange!.start;
            endDate = _customDateRange!.end.add(const Duration(days: 1));
          }
          break;
        case TimeFilterOption.allTime:
          startDate = null;
          endDate = null;
          break;
      }

      bool? demoOnly;
      if (_selectedProvenance == ProvenanceFilterOption.hardwareOnly) {
        demoOnly = false;
      } else if (_selectedProvenance == ProvenanceFilterOption.demoOnly) {
        demoOnly = true;
      }

      final results = await widget.stateProvider.getEvents(
        eventType: _selectedCategory,
        startDate: startDate,
        endDate: endDate,
        isDemoOnly: demoOnly,
        searchQuery: _searchController.text.trim().isNotEmpty ? _searchController.text.trim() : null,
        limit: 300,
      );

      final stats = await widget.stateProvider.getDatabaseStatistics();

      if (mounted) {
        setState(() {
          _events = results;
          _stats = stats;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to query event history: $e';
        });
      }
    }
  }

  void _resetFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedTimeFilter = TimeFilterOption.allTime;
      _selectedProvenance = ProvenanceFilterOption.all;
      _customDateRange = null;
      _searchController.clear();
    });
    _loadEvents();
  }

  Future<void> _selectCustomDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 1)),
      initialDateRange: _customDateRange ??
          DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.cyberCyan,
              onPrimary: Colors.black,
              surface: AppColors.backgroundCard,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTimeFilter = TimeFilterOption.customRange;
        _customDateRange = picked;
      });
      _loadEvents();
    }
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        title: const Row(
          children: [
            Icon(Icons.delete_sweep_rounded, color: AppColors.statusAlert),
            SizedBox(width: 10),
            Text('Clear Event History', style: AppTextStyles.h3),
          ],
        ),
        content: const Text(
          'Choose which events you want to purge from SQLite persistent storage. Real physical hardware records can be preserved separately.',
          style: AppTextStyles.bodySecondary,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await widget.stateProvider.clearEvents(demoOnly: true);
              _loadEvents();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Purged all simulated demo events. Hardware records preserved.'),
                    backgroundColor: AppColors.cyberCyan,
                  ),
                );
              }
            },
            child: const Text('Clear Demo Only', style: TextStyle(color: AppColors.accentOrange)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusAlert),
            onPressed: () async {
              Navigator.pop(ctx);
              await widget.stateProvider.clearEvents(demoOnly: false);
              _loadEvents();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All blackbox records purged from SQLite.'),
                    backgroundColor: AppColors.statusAlert,
                  ),
                );
              }
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _exportPdfReport() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: AppColors.cyberCyan),
      ),
    );

    final result = await widget.stateProvider.exportAuditReportPdf(customEvents: _events);

    if (mounted) {
      Navigator.pop(context); // Close loading spinner
      _showPdfPreviewModal(result);
    }
  }

  void _showPdfPreviewModal(ReportExportResult result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: AppColors.cardBorder),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.cyberCyan.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.cyberCyan),
                        ),
                        child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.cyberCyan, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Audit Report Generated', style: AppTextStyles.h3),
                            const SizedBox(height: 2),
                            Text(
                              result.fileName,
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontFamily: 'monospace'),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textSecondary),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Document Metadata Card
                  GlowContainer(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        _buildModalMetaRow('Format', 'Standard ISO PDF 1.4 Document'),
                        _buildModalMetaRow('File Size', '${(result.fileBytes.lengthInBytes / 1024).toStringAsFixed(1)} KB'),
                        _buildModalMetaRow('Total Events', '${result.eventCount} Records'),
                        if (result.filePath != null)
                          _buildModalMetaRow('Saved Path', result.filePath!, isPath: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Executive Summary Box
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundPrimary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DOCUMENT SUMMARY',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.cyberCyan, letterSpacing: 0.8),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          result.summaryText,
                          style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.4),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          '• Certified for Academic Exhibition Evaluation\n• Digital SHA-256 blackbox signature attached\n• Separate Hardware vs Demo event classifications',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'Copy Report Text',
                          icon: Icons.copy_rounded,
                          variant: ButtonVariant.secondary,
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: result.summaryText));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Report summary copied to clipboard!'),
                                backgroundColor: AppColors.cyberCyan,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomButton(
                          text: 'Done',
                          icon: Icons.check_circle_outline,
                          variant: ButtonVariant.primary,
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModalMetaRow(String label, String value, {bool isPath = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isPath ? AppColors.cyberCyan : AppColors.textPrimary,
                fontFamily: isPath ? 'monospace' : null,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: isPath ? 2 : 1,
            ),
          ),
        ],
      ),
    );
  }

  void _showEventDetailsDialog(HelmetEventRecord event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: AppColors.cardBorder),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _getSeverityColor(event.severity).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: _getSeverityColor(event.severity)),
                        ),
                        child: Icon(
                          _getEventIcon(event.eventType),
                          color: _getSeverityColor(event.severity),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(event.title, style: AppTextStyles.h3),
                            const SizedBox(height: 2),
                            Text(
                              event.id,
                              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontFamily: 'monospace'),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textSecondary),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Data Provenance Banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: event.isDemo
                          ? AppColors.accentOrange.withValues(alpha: 0.12)
                          : AppColors.cyberCyan.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: event.isDemo ? AppColors.accentOrange : AppColors.cyberCyan,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          event.isDemo ? Icons.science_outlined : Icons.memory,
                          size: 16,
                          color: event.isDemo ? AppColors.accentOrange : AppColors.cyberCyan,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          event.isDemo
                              ? 'DATA PROVENANCE: EXHIBITION DEMO SIMULATOR'
                              : 'DATA PROVENANCE: PHYSICAL ESP32 WI-FI HARDWARE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: event.isDemo ? AppColors.accentOrange : AppColors.cyberCyan,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Description
                  Text(
                    event.description,
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
                  ),
                  const SizedBox(height: 16),

                  // Telemetry Metrics Grid
                  GlowContainer(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TELEMETRY SNAPSHOT',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.cyberCyan, letterSpacing: 0.8),
                        ),
                        const SizedBox(height: 10),
                        _buildModalMetaRow('Timestamp', '${AppFormatters.formatTime(event.timestamp)} (${event.timestamp.toIso8601String().substring(0, 10)})'),
                        _buildModalMetaRow('Category', event.eventType.name.toUpperCase()),
                        _buildModalMetaRow('Severity', event.severity.name.toUpperCase()),
                        if (event.gForce != null)
                          _buildModalMetaRow('Peak Impact', '${event.gForce!.toStringAsFixed(2)} G'),
                        if (event.speedKmh != null)
                          _buildModalMetaRow('Speed', '${event.speedKmh!.toInt()} km/h'),
                        if (event.alcoholPpm != null)
                          _buildModalMetaRow('Alcohol MQ-3', '${event.alcoholPpm!.toStringAsFixed(1)} PPM'),
                        if (event.hasCoordinates)
                          _buildModalMetaRow('Coordinates', '${event.latitude!.toStringAsFixed(5)}, ${event.longitude!.toStringAsFixed(5)}'),
                        if (event.status != null)
                          _buildModalMetaRow('System Status', event.status!.toUpperCase()),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Additional metadata if any
                  if (event.metadata != null && event.metadata!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundPrimary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'EXTRA DIAGNOSTIC PAYLOAD (JSON)',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            jsonEncode(event.metadata),
                            style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: AppColors.cyberCyan),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      if (event.hasCoordinates)
                        Expanded(
                          child: CustomButton(
                            text: 'Open Map',
                            icon: Icons.map_outlined,
                            variant: ButtonVariant.secondary,
                            onPressed: () {
                              Navigator.pop(ctx);
                              AppFormatters.openGoogleMaps(event.latitude!, event.longitude!);
                            },
                          ),
                        ),
                      if (event.hasCoordinates) const SizedBox(width: 10),
                      Expanded(
                        child: CustomButton(
                          text: 'Copy JSON',
                          icon: Icons.copy_rounded,
                          variant: ButtonVariant.secondary,
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: jsonEncode(event.toMap())));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Event JSON copied to clipboard!'),
                                backgroundColor: AppColors.cyberCyan,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    icon: const Icon(Icons.delete_outline, color: AppColors.statusAlert, size: 18),
                    label: const Text('Delete this Record', style: TextStyle(color: AppColors.statusAlert, fontSize: 12)),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await widget.stateProvider.deleteEvent(event.id);
                      _loadEvents();
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Color _getSeverityColor(EventSeverity severity) {
    switch (severity) {
      case EventSeverity.emergency:
      case EventSeverity.critical:
        return AppColors.statusAlert;
      case EventSeverity.warning:
        return AppColors.statusWarning;
      case EventSeverity.info:
        return AppColors.cyberCyan;
    }
  }

  IconData _getEventIcon(HelmetEventType type) {
    switch (type) {
      case HelmetEventType.accident:
        return Icons.car_crash_rounded;
      case HelmetEventType.sos:
        return Icons.sos_rounded;
      case HelmetEventType.helmetStatus:
        return Icons.sports_motorsports;
      case HelmetEventType.connection:
        return Icons.wifi_tethering;
      case HelmetEventType.gpsUpdate:
        return Icons.gps_fixed;
      case HelmetEventType.alcoholLockout:
        return Icons.local_bar_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final helmet = widget.stateProvider.helmetState;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: CustomAppBar(
        title: 'Safety History & Reports',
        subtitle: 'SQLite Telemetry Blackbox',
        helmetState: helmet,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.textSecondary),
            tooltip: 'Clear History',
            onPressed: _showClearHistoryDialog,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.cyberCyan),
            tooltip: 'Export PDF Report',
            onPressed: _exportPdfReport,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.cyberCyan,
          backgroundColor: AppColors.backgroundCard,
          onRefresh: _loadEvents,
          child: CustomScrollView(
            slivers: [
              // Header Audit Score & KPI Summary Cards
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top KPI Overview Card
                      GlowContainer(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.statusSafe, width: 3),
                                boxShadow: const [
                                  BoxShadow(color: AppColors.statusSafeGlow, blurRadius: 14),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  '96',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.statusSafe,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'OFFICIAL BLACKBOX AUDIT',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.statusSafe,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_stats['total'] ?? 0} total events logged locally in SQLite database.\n${_stats['hardware'] ?? 0} physical ESP32 / ${_stats['demo'] ?? 0} demo simulator.',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Quick Stats Pills
                      Row(
                        children: [
                          _buildStatPill('Total Logs', '${_stats['total'] ?? 0}', AppColors.cyberCyan),
                          const SizedBox(width: 8),
                          _buildStatPill('Crashes', '${_stats['accidents'] ?? 0}', AppColors.statusAlert),
                          const SizedBox(width: 8),
                          _buildStatPill('SOS Alerts', '${_stats['sos'] ?? 0}', AppColors.accentOrange),
                          const SizedBox(width: 8),
                          _buildStatPill('DUI Lockouts', '${_stats['alcoholLockouts'] ?? 0}', AppColors.statusWarning),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Search Bar
                      TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        onChanged: (_) => _loadEvents(),
                        decoration: InputDecoration(
                          hintText: 'Search events, descriptions, or coordinates...',
                          hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 18),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: AppColors.textSecondary, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    _loadEvents();
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          filled: true,
                          fillColor: AppColors.backgroundCard,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.cardBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.cardBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.cyberCyan),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Category Filters Scroll
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('All Categories', _selectedCategory == null, () {
                              setState(() => _selectedCategory = null);
                              _loadEvents();
                            }),
                            const SizedBox(width: 6),
                            _buildFilterChip('Crashes', _selectedCategory == HelmetEventType.accident, () {
                              setState(() => _selectedCategory = HelmetEventType.accident);
                              _loadEvents();
                            }),
                            const SizedBox(width: 6),
                            _buildFilterChip('SOS Triggers', _selectedCategory == HelmetEventType.sos, () {
                              setState(() => _selectedCategory = HelmetEventType.sos);
                              _loadEvents();
                            }),
                            const SizedBox(width: 6),
                            _buildFilterChip('Helmet Wearing', _selectedCategory == HelmetEventType.helmetStatus, () {
                              setState(() => _selectedCategory = HelmetEventType.helmetStatus);
                              _loadEvents();
                            }),
                            const SizedBox(width: 6),
                            _buildFilterChip('ESP32 Gateway', _selectedCategory == HelmetEventType.connection, () {
                              setState(() => _selectedCategory = HelmetEventType.connection);
                              _loadEvents();
                            }),
                            const SizedBox(width: 6),
                            _buildFilterChip('GPS Waypoints', _selectedCategory == HelmetEventType.gpsUpdate, () {
                              setState(() => _selectedCategory = HelmetEventType.gpsUpdate);
                              _loadEvents();
                            }),
                            const SizedBox(width: 6),
                            _buildFilterChip('DUI Lockouts', _selectedCategory == HelmetEventType.alcoholLockout, () {
                              setState(() => _selectedCategory = HelmetEventType.alcoholLockout);
                              _loadEvents();
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Time & Provenance Filter Row
                      Row(
                        children: [
                          // Time Filter Dropdown Button
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: AppColors.backgroundCard,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<TimeFilterOption>(
                                  value: _selectedTimeFilter,
                                  isExpanded: true,
                                  dropdownColor: AppColors.backgroundCard,
                                  style: const TextStyle(fontSize: 11, color: AppColors.textPrimary),
                                  icon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary, size: 20),
                                  items: const [
                                    DropdownMenuItem(value: TimeFilterOption.allTime, child: Text('Time: All Time')),
                                    DropdownMenuItem(value: TimeFilterOption.today, child: Text('Time: Today')),
                                    DropdownMenuItem(value: TimeFilterOption.last24Hours, child: Text('Time: Last 24h')),
                                    DropdownMenuItem(value: TimeFilterOption.last7Days, child: Text('Time: Last 7 Days')),
                                    DropdownMenuItem(value: TimeFilterOption.last30Days, child: Text('Time: Last 30 Days')),
                                    DropdownMenuItem(value: TimeFilterOption.customRange, child: Text('Time: Custom Range...')),
                                  ],
                                  onChanged: (val) {
                                    if (val == TimeFilterOption.customRange) {
                                      _selectCustomDateRange();
                                    } else if (val != null) {
                                      setState(() => _selectedTimeFilter = val);
                                      _loadEvents();
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Provenance Dropdown Button
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: AppColors.backgroundCard,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<ProvenanceFilterOption>(
                                  value: _selectedProvenance,
                                  isExpanded: true,
                                  dropdownColor: AppColors.backgroundCard,
                                  style: const TextStyle(fontSize: 11, color: AppColors.textPrimary),
                                  icon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary, size: 20),
                                  items: const [
                                    DropdownMenuItem(value: ProvenanceFilterOption.all, child: Text('Source: All')),
                                    DropdownMenuItem(value: ProvenanceFilterOption.hardwareOnly, child: Text('Source: ESP32 Only')),
                                    DropdownMenuItem(value: ProvenanceFilterOption.demoOnly, child: Text('Source: Demo Only')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _selectedProvenance = val);
                                      _loadEvents();
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Export PDF Quick Banner
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.cyberCyan.withValues(alpha: 0.15),
                          AppColors.backgroundCard,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cyberCyan.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.picture_as_pdf_rounded, color: AppColors.cyberCyan, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'SAFETY AUDIT REPORT EXPORT',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.cyberCyan, letterSpacing: 0.6),
                              ),
                              Text(
                                '${_events.length} records ready for official PDF export',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: _exportPdfReport,
                          style: TextButton.styleFrom(
                            backgroundColor: AppColors.cyberCyan,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Export PDF', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Events List Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'RECORDED EVENTS (${_events.length})',
                        style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary, letterSpacing: 0.8),
                      ),
                      if (_selectedCategory != null || _selectedTimeFilter != TimeFilterOption.allTime || _selectedProvenance != ProvenanceFilterOption.all || _searchController.text.isNotEmpty)
                        GestureDetector(
                          onTap: _resetFilters,
                          child: const Text(
                            'Reset Filters',
                            style: TextStyle(fontSize: 11, color: AppColors.cyberCyan, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Loading / Empty / Content states
              if (_isLoading)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: CircularProgressIndicator(color: AppColors.cyberCyan),
                    ),
                  ),
                )
              else if (_errorMessage != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: GlowContainer(
                      borderColor: AppColors.statusAlert,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.statusAlert, size: 36),
                          const SizedBox(height: 8),
                          Text(_errorMessage!, style: const TextStyle(color: Colors.white, fontSize: 12), textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          CustomButton(
                            text: 'Retry Query',
                            variant: ButtonVariant.secondary,
                            onPressed: _loadEvents,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (_events.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
                    child: GlowContainer(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.cyberCyan.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.inventory_2_outlined, color: AppColors.cyberCyan, size: 40),
                          ),
                          const SizedBox(height: 16),
                          const Text('No Safety Events Found', style: AppTextStyles.h3),
                          const SizedBox(height: 6),
                          const Text(
                            'No telemetry records match the active category, date range, or search criteria. Adjust filters or trigger a live simulation.',
                            style: AppTextStyles.bodySecondary,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CustomButton(
                                text: 'Reset Filters',
                                icon: Icons.refresh_rounded,
                                variant: ButtonVariant.secondary,
                                onPressed: _resetFilters,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final event = _events[index];
                        return _buildEventCard(event);
                      },
                      childCount: _events.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatPill(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: color,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.cyberCyan : AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.cyberCyan : AppColors.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
            color: isSelected ? Colors.black : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(HelmetEventRecord event) {
    final severityColor = _getSeverityColor(event.severity);
    final iconData = _getEventIcon(event.eventType);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showEventDetailsDialog(event),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event Icon Avatar
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: severityColor.withValues(alpha: 0.6)),
                  ),
                  child: Center(
                    child: Icon(iconData, color: severityColor, size: 20),
                  ),
                ),
                const SizedBox(width: 12),

                // Event Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Category Badge & Provenance Tag
                      Row(
                        children: [
                          StatusBadge(
                            label: event.eventType.name.toUpperCase(),
                            type: event.severity == EventSeverity.critical || event.severity == EventSeverity.emergency
                                ? BadgeType.emergency
                                : event.severity == EventSeverity.warning
                                    ? BadgeType.warning
                                    : BadgeType.safe,
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: event.isDemo
                                  ? AppColors.accentOrange.withValues(alpha: 0.1)
                                  : AppColors.cyberCyan.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: event.isDemo
                                    ? AppColors.accentOrange.withValues(alpha: 0.5)
                                    : AppColors.cyberCyan.withValues(alpha: 0.5),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              event.isDemo ? 'DEMO' : 'ESP32',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: event.isDemo ? AppColors.accentOrange : AppColors.cyberCyan,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            AppFormatters.formatTime(event.timestamp),
                            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Title
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),

                      // Description
                      Text(
                        event.description,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Metric Tags Footer
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (event.gForce != null)
                            _buildMiniMetricTag('IMPACT', '${event.gForce!.toStringAsFixed(1)} G', AppColors.statusAlert),
                          if (event.speedKmh != null && event.speedKmh! > 0)
                            _buildMiniMetricTag('SPEED', '${event.speedKmh!.toInt()} km/h', AppColors.cyberCyan),
                          if (event.alcoholPpm != null)
                            _buildMiniMetricTag('ALC', '${event.alcoholPpm!.toInt()} PPM', AppColors.statusWarning),
                          if (event.hasCoordinates)
                            _buildMiniMetricTag('GPS', '${event.latitude!.toStringAsFixed(2)}, ${event.longitude!.toStringAsFixed(2)}', AppColors.statusSafe),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniMetricTag(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: color,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
