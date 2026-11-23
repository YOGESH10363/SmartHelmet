import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/helmet_event_record.dart';
import '../models/user_profile.dart';
import 'pdf_report_generator.dart';

/// Result bundle after generating a safety audit PDF report.
class ReportExportResult {
  final bool success;
  final String fileName;
  final String? filePath;
  final Uint8List fileBytes;
  final int eventCount;
  final String summaryText;
  final String? errorMessage;

  const ReportExportResult({
    required this.success,
    required this.fileName,
    this.filePath,
    required this.fileBytes,
    required this.eventCount,
    required this.summaryText,
    this.errorMessage,
  });
}

/// Service that coordinates PDF report generation, file persistence, and export workflows.
class ReportExportService {
  static final ReportExportService _instance = ReportExportService._internal();
  static ReportExportService get instance => _instance;

  ReportExportService._internal();

  /// Generate a valid PDF 1.4 document containing the filtered event audit log
  Future<ReportExportResult> generatePdfReport({
    required List<HelmetEventRecord> events,
    required UserProfile profile,
    String? esp32Ip,
    bool includeDisclaimer = true,
  }) async {
    try {
      final now = DateTime.now();
      final dateSlug = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
      final fileName = 'SmartHelmet_Audit_Report_$dateSlug.pdf';

      final hardwareEvents = events.where((e) => !e.isDemo).length;
      final demoEvents = events.where((e) => e.isDemo).length;

      // Generate standard PDF 1.4 binary bytes
      final Uint8List pdfBytes = PdfReportGenerator.generate(
        events: events,
        profile: profile,
        esp32Ip: esp32Ip,
      );

      // Attempt to save to disk if on mobile/desktop
      String? savedPath;
      if (!kIsWeb) {
        try {
          Directory dir;
          try {
            dir = await getApplicationDocumentsDirectory();
          } catch (_) {
            dir = Directory.systemTemp;
          }
          final file = File(p.join(dir.path, fileName));
          await file.writeAsBytes(pdfBytes, flush: true);
          savedPath = file.path;
          debugPrint('[ReportExportService] Saved PDF audit report to: $savedPath');
        } catch (e) {
          debugPrint('[ReportExportService] File persistence note: $e');
        }
      }

      final summary = 'Smart Helmet 2.0 Safety Audit Report generated with ${events.length} events ($hardwareEvents Physical ESP32, $demoEvents Demo Simulator). File: $fileName';

      return ReportExportResult(
        success: true,
        fileName: fileName,
        filePath: savedPath,
        fileBytes: pdfBytes,
        eventCount: events.length,
        summaryText: summary,
      );
    } catch (e) {
      debugPrint('[ReportExportService] Error: $e');
      return ReportExportResult(
        success: false,
        fileName: 'report_error.pdf',
        fileBytes: Uint8List(0),
        eventCount: 0,
        summaryText: 'Failed to generate PDF report: $e',
        errorMessage: e.toString(),
      );
    }
  }
}
