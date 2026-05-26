import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class ExportService {
  static Future<File> _saveToDownloads(
    String fileName,
    List<int> bytes,
  ) async {
    Directory dir;

    if (Platform.isAndroid) {
      dir = Directory('/storage/emulated/0/Download');

      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
    } else {
      dir = await getApplicationDocumentsDirectory();
    }

    final file = File(p.join(dir.path, fileName));

    await file.writeAsBytes(bytes);

    return file;
  }

  /// Exports a list of records to an Excel file and shares it.
  ///
  /// The [records] are a list of maps, where each map must contain
  /// 'name', 'phone', and 'scanCount' keys.
  static Future<void> exportToExcel(
      BuildContext context, List<Map<String, Object?>> records) async {
    try {
      final excel = Excel.createExcel();
      excel.rename('Sheet1', 'Scan Report');
      final sheet = excel['Scan Report'];

      // --- Header Row ---
      final headers = [
        'Name',
        'Phone',
        'Scan Count',
      ];
      sheet.appendRow(headers.map((header) => TextCellValue(header)).toList());

      // --- Data Rows ---
      for (final record in records) {
        sheet.appendRow([
          TextCellValue(record['name']?.toString() ?? ''),
          TextCellValue(record['phone']?.toString() ?? ''),
          IntCellValue((record['scanCount'] as num?)?.toInt() ?? 0),
        ]);
      }

      // --- Auto-fit columns for better readability ---
      for (var i = 0; i < headers.length; i++) {
        sheet.setColumnAutoFit(i);
      }

      // --- Save and Share ---
      final dateFormat = DateFormat('yyyy-MM-dd_HH-mm-ss');
      final timestamp = dateFormat.format(DateTime.now());
      final fileName = 'scan_report_$timestamp.xlsx';

      // Encode the Excel file
      final bytes = excel.encode();

      if (bytes != null) {
        final file = await _saveToDownloads(
          fileName,
          bytes,
        );

        // Show a confirmation SnackBar if the context is still mounted
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Saved report to ${file.path}'),
              duration: const Duration(seconds: 4),
            ),
          );
        }

        // Share the file
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'QR Scan Report',
          text: 'Exported ${records.length} records in a scan report.',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Failed to export report: $e');
      debugPrint(stackTrace.toString());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting report: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Exports a list of records to a CSV file and shares it.
  ///
  /// The [records] are a list of maps, where each map must contain
  /// 'name', 'phone', and 'scanCount' keys.
  static Future<void> exportToCSV(
      BuildContext context, List<Map<String, Object?>> records) async {
    try {
      // --- Header and Data Rows ---
      final List<List<dynamic>> rows = [
        ['Name', 'Phone', 'Scan Count'], // Header
      ];

      for (final record in records) {
        rows.add([
          record['name']?.toString() ?? '',
          record['phone']?.toString() ?? '',
          record['scanCount'],
        ]);
      }

      // --- Convert to CSV String ---
      final csvString = const ListToCsvConverter().convert(rows);

      // --- Save and Share ---
      final dateFormat = DateFormat('yyyy-MM-dd_HH-mm-ss');
      final timestamp = dateFormat.format(DateTime.now());
      final fileName = 'scan_report_$timestamp.csv';

      // Encode the CSV string to bytes
      final bytes = utf8.encode(csvString);

      // Use the existing _saveToDownloads helper
      final file = await _saveToDownloads(fileName, bytes);

      // Show confirmation SnackBar
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved report to ${file.path}'),
            duration: const Duration(seconds: 4),
          ),
        );
      }

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'QR Scan Report',
        text: 'Exported ${records.length} records in a scan report.',
      );
    } catch (e, stackTrace) {
      debugPrint('Failed to export CSV report: $e');
      debugPrint(stackTrace.toString());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting CSV report: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
