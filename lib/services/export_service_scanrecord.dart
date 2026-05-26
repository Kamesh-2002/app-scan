import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/scan_record.dart';

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

  static Future<void> exportToCSV(
      BuildContext context, List<ScanRecord> records) async {
    final List<List<dynamic>> rows = [
      [
        '#',
        'Name',
        'Phone',
        'Raw Data',
        'Encrypted',
        'Scan Count',
        'Last Scanned'
      ],
    ];

    for (int i = 0; i < records.length; i++) {
      final r = records[i];
      rows.add([
        i + 1,
        r.decryptedName ?? '',
        r.decryptedPhone ?? '',
        r.rawData,
        r.isEncrypted ? 'Yes' : 'No',
        DateFormat('dd/MM/yyyy HH:mm').format(r.scannedAt),
      ]);
    }

    final csv = const ListToCsvConverter().convert(rows);
    final fileName =
        'app_scan_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';

    final file = await _saveToDownloads(
      fileName,
      csv.codeUnits,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved to ${file.path}'),
        ),
      );
    }
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'App Scan - QR Scan Data Export',
      text: 'Exported ${records.length} scan records from App Scan.',
    );
  }

  static Future<void> exportToExcel(
      BuildContext context, List<ScanRecord> records) async {
    final excel = Excel.createExcel();
    excel.rename('Sheet1', 'Scan Records');
    final sheet = excel['Scan Records'];

    // Header row
    final headers = [
      '#',
      'Name',
      'Phone',
      'Raw Data',
      'Encrypted',
      'Scan Count',
      'Last Scanned'
    ];

    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#1A7A6E'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
    );

    for (int col = 0; col < headers.length; col++) {
      final cell =
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
      cell.value = TextCellValue(headers[col]);
      cell.cellStyle = headerStyle;
    }

    // Data rows
    for (int i = 0; i < records.length; i++) {
      final r = records[i];
      final rowData = [
        (i + 1).toString(),
        r.decryptedName ?? '',
        r.decryptedPhone ?? '',
        r.rawData,
        r.isEncrypted ? 'Yes' : 'No',
        DateFormat('dd/MM/yyyy HH:mm').format(r.scannedAt),
      ];

      final rowStyle = CellStyle(
        backgroundColorHex: i % 2 == 0
            ? ExcelColor.fromHexString('#1A2535')
            : ExcelColor.fromHexString('#0F1923'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      );

      for (int col = 0; col < rowData.length; col++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: i + 1),
        );
        cell.value = TextCellValue(rowData[col]);
        cell.cellStyle = rowStyle;
      }
    }

    // Set column widths
    sheet.setColumnWidth(0, 5);
    sheet.setColumnWidth(1, 20);
    sheet.setColumnWidth(2, 18);
    sheet.setColumnWidth(3, 40);
    sheet.setColumnWidth(4, 12);
    sheet.setColumnWidth(5, 12);
    sheet.setColumnWidth(6, 22);

    final fileName =
        'app_scan_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';

    final bytes = excel.encode();

    if (bytes != null) {
      final file = await _saveToDownloads(
        fileName,
        bytes,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to ${file.path}'),
          ),
        );
      }
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'App Scan - QR Scan Data Export',
        text: 'Exported ${records.length} scan records from App Scan.',
      );
    }
  }
}
