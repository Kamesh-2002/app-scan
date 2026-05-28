import 'package:app_scan/services/export_service_scanrecord.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/scan_record.dart';
import '../services/database_service.dart';
import '../services/export_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, Object?>> _records = [];
  List<Map<String, Object?>> _filtered = [];
  bool _isLoading = true;
  bool _isExporting = false;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRecords();
    _searchCtrl.addListener(_filterRecords);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    final records = await DatabaseService.instance.getScansCountGroup();
    if (mounted) {
      setState(() {
        _records = records;
        _filtered = records;
        _isLoading = false;
      });
    }
  }

  void _filterRecords() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _records.where((r) {
        final name = r["name"] as String?;
        final phone = r["phone"] as String?;
        final nameMatches = name?.toLowerCase().contains(q) ?? false;
        final phoneMatches = phone?.toLowerCase().contains(q) ?? false;
        return nameMatches || phoneMatches;
      }).toList();
    });
  }

  // Future<void> _deleteRecord(ScanRecord record) async {
  //   final confirmed = await showDialog<bool>(
  //     context: context,
  //     builder: (ctx) => AlertDialog(
  //       backgroundColor: const Color(0xFF1A2535),
  //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  //       title: Text('Delete Record',
  //           style: GoogleFonts.spaceGrotesk(
  //               color: Colors.white, fontWeight: FontWeight.w700)),
  //       content: Text('Remove "${record.displayTitle}" from history?',
  //           style: GoogleFonts.spaceGrotesk(color: Colors.white70)),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(ctx, false),
  //           child:
  //               const Text('Cancel', style: TextStyle(color: Colors.white54)),
  //         ),
  //         ElevatedButton(
  //           onPressed: () => Navigator.pop(ctx, true),
  //           style: ElevatedButton.styleFrom(
  //               backgroundColor: Colors.redAccent,
  //               foregroundColor: Colors.white),
  //           child: const Text('Delete'),
  //         ),
  //       ],
  //     ),
  //   );
  //   if (confirmed == true && record.id != null) {
  //     await DatabaseService.instance.deleteScan(record.id!);
  //     _loadRecords();
  //   }
  // }

  // Future<void> _clearAll() async {
  //   final confirmed = await showDialog<bool>(
  //     context: context,
  //     builder: (ctx) => AlertDialog(
  //       backgroundColor: const Color(0xFF1A2535),
  //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  //       title: Text('Clear All History',
  //           style: GoogleFonts.spaceGrotesk(
  //               color: Colors.white, fontWeight: FontWeight.w700)),
  //       content: Text(
  //           'This will permanently delete all ${_records.length} scan records. This cannot be undone.',
  //           style: GoogleFonts.spaceGrotesk(color: Colors.white70)),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(ctx, false),
  //           child:
  //               const Text('Cancel', style: TextStyle(color: Colors.white54)),
  //         ),
  //         ElevatedButton(
  //           onPressed: () => Navigator.pop(ctx, true),
  //           style: ElevatedButton.styleFrom(
  //               backgroundColor: Colors.redAccent,
  //               foregroundColor: Colors.white),
  //           child: const Text('Clear All'),
  //         ),
  //       ],
  //     ),
  //   );
  //   if (confirmed == true) {
  //     await DatabaseService.instance.clearAllScans();
  //     _loadRecords();
  //   }
  // }

  void _showExportSheet(List<Map<String, Object?>>? sheetMapRecords,
      List<ScanRecord>? sheetScanRecords, bool isScan) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A2535),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Export Scan Data',
                style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('${_records.length} records will be exported',
                style: GoogleFonts.spaceGrotesk(
                    color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 24),
            _ExportOption(
              icon: Icons.table_chart_rounded,
              color: const Color(0xFF00D4AA),
              title: 'Export as CSV',
              subtitle: 'Compatible with spreadsheet apps',
              onTap: () async {
                Navigator.pop(ctx);
                setState(() => _isExporting = true);
                if (isScan) {
                  await ExportServiceScanRecord.exportToCSV(
                      context, sheetScanRecords!);
                } else {
                  await ExportService.exportToCSV(context, sheetMapRecords!);
                }
                if (mounted) setState(() => _isExporting = false);
              },
            ),
            const SizedBox(height: 12),
            _ExportOption(
              icon: Icons.grid_on_rounded,
              color: const Color(0xFF7B61FF),
              title: 'Export as Excel',
              subtitle: 'Styled .xlsx with formatted columns',
              onTap: () async {
                Navigator.pop(ctx);
                setState(() => _isExporting = true);
                if (isScan) {
                  await ExportServiceScanRecord.exportToExcel(
                      context, sheetScanRecords!);
                } else {
                  await ExportService.exportToExcel(context, sheetMapRecords!);
                }
                if (mounted) setState(() => _isExporting = false);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showDetailSheet(Map<String, Object?> record) async {
    final records = await DatabaseService.instance.getScansByNameAndPhone(
        record["name"] as String, record["phone"] as String);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A2535),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        minChildSize: 0.35,
        maxChildSize: 0.85,
        builder: (_, scrollCtrl) => SingleChildScrollView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D4AA).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.lock_rounded,
                      color: const Color(0xFF7B61FF),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Encrypted Contact",
                          style: GoogleFonts.spaceGrotesk(
                              color: Colors.white54, fontSize: 13),
                        ),
                        Text(
                          record["name"] as String,
                          style: GoogleFonts.spaceGrotesk(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  _ActionIconBtn(
                    icon: Icons.upload_rounded,
                    color: const Color(0xFF00D4AA),
                    onTap: () {
                      _showExportSheet(null, records, true);
                    },
                    tooltip: 'Export',
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Scan count badge
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF00D4AA).withOpacity(0.15),
                      const Color(0xFF7B61FF).withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFF00D4AA).withOpacity(0.25)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Scans',
                            style: GoogleFonts.spaceGrotesk(
                                color: Colors.white54, fontSize: 13)),
                        Text(
                          '${records.length} time${records.length > 1 ? 's' : ''}',
                          style: GoogleFonts.spaceGrotesk(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    const Icon(Icons.qr_code_scanner_rounded,
                        color: Color(0xFF00D4AA), size: 36),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _DetailRow(
                  label: 'Name',
                  value: record["name"] as String,
                  icon: Icons.person_outline),
              _DetailRow(
                  label: 'Phone',
                  value: record["phone"] as String,
                  icon: Icons.phone_outlined),
              const SizedBox(height: 24),

              Text(
                'Scan History',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white10,
                  ),
                ),
                child: ListView.separated(
                  itemCount: records.length,
                  padding: const EdgeInsets.all(12),
                  itemBuilder: (context, index) {
                    final scan = records[index];

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            color: Color(0xFF00D4AA),
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              DateFormat('dd MMM yy HH:mm:ss').format(scan.scannedAt),
                              style: GoogleFonts.spaceGrotesk(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalScans = _records.fold<int>(
      0,
      (sum, r) => sum + ((r["scanCount"] as num?)?.toInt() ?? 0),
    );
    return Scaffold(
      backgroundColor: const Color(0xFF0A1118),
      body: Column(
        children: [
          // Stats + actions bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: [
                // Stats row
                Row(
                  children: [
                    _StatChip(
                      label: 'Unique QRs',
                      value: '${_records.length}',
                      color: const Color(0xFF00D4AA),
                      icon: Icons.qr_code_2_rounded,
                    ),
                    const SizedBox(width: 10),
                    _StatChip(
                      label: 'Total Scans',
                      value: '$totalScans',
                      color: const Color(0xFF7B61FF),
                      icon: Icons.bar_chart_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Search + action buttons
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search records...',
                          prefixIcon: const Icon(Icons.search,
                              color: Colors.white38, size: 20),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_records.isNotEmpty)
                      _ActionIconBtn(
                        icon: Icons.upload_rounded,
                        color: const Color(0xFF00D4AA),
                        onTap: () {
                          _showExportSheet(_records, null, false);
                        },
                        tooltip: 'Export',
                      ),
                    // if (_records.isNotEmpty) ...[
                    //   const SizedBox(width: 6),
                    //   _ActionIconBtn(
                    //     icon: Icons.delete_sweep_rounded,
                    //     color: Colors.redAccent,
                    //     onTap: _clearAll,
                    //     tooltip: 'Clear All',
                    //   ),
                    // ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00D4AA)))
                : _filtered.isEmpty
                    ? _buildEmpty(onRefresh: _loadRecords)
                    : RefreshIndicator(
                        onRefresh: _loadRecords,
                        color: const Color(0xFF00D4AA),
                        backgroundColor: const Color(0xFF1A2535),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: _filtered.length,
                          itemBuilder: (ctx, i) => _ScanTile(
                            record: _filtered[i],
                            onTap: () => _showDetailSheet(_filtered[i]),
                            // onDelete: () => _deleteRecord(_filtered[i]),
                          ),
                        ),
                      ),
          ),
        ],
      ),
      // Export overlay
      floatingActionButton: _isExporting
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2535),
                borderRadius: BorderRadius.circular(30),
                border:
                    Border.all(color: const Color(0xFF00D4AA).withOpacity(0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFF00D4AA)),
                  ),
                  const SizedBox(width: 10),
                  Text('Exporting...',
                      style: GoogleFonts.spaceGrotesk(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildEmpty({required Future<void> Function() onRefresh}) {
  final hasSearch = _searchCtrl.text.isNotEmpty;

  return RefreshIndicator(
    onRefresh: onRefresh,
    color: Colors.white,
    backgroundColor: Colors.black,
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  hasSearch
                      ? Icons.search_off_rounded
                      : Icons.history_rounded,
                  size: 64,
                  color: Colors.white24,
                ),
                const SizedBox(height: 16),
                Text(
                  hasSearch
                      ? 'No matching records'
                      : 'No scans yet',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white54,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  hasSearch
                      ? 'Try a different search term'
                      : 'Scan a QR code to get started',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white38,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _StatChip(
      {required this.label,
      required this.value,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: GoogleFonts.spaceGrotesk(
                          color: color,
                          fontWeight: FontWeight.w800,
                          fontSize: 16)),
                  Text(label,
                      style: GoogleFonts.spaceGrotesk(
                          color: Colors.white54, fontSize: 10),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionIconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;
  const _ActionIconBtn(
      {required this.icon,
      required this.color,
      required this.onTap,
      required this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}

class _ScanTile extends StatelessWidget {
  final Map<String, Object?> record;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  const _ScanTile({required this.record, required this.onTap, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2535),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Color(0xFF00D4AA).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.qr_code_rounded,
                color: const Color.fromARGB(255, 255, 255, 255),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record["name"] as String,
                    style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    record["phone"] as String,
                    style: GoogleFonts.spaceGrotesk(
                        color: Colors.white54, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D4AA).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '×${record["scanCount"]}',
                    style: GoogleFonts.spaceGrotesk(
                        color: const Color(0xFF00D4AA),
                        fontWeight: FontWeight.w800,
                        fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ExportOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ExportOption(
      {required this.icon,
      required this.color,
      required this.title,
      required this.subtitle,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                  Text(subtitle,
                      style: GoogleFonts.spaceGrotesk(
                          color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: color, size: 16),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _DetailRow(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF00D4AA), size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.spaceGrotesk(
                        color: Colors.white54, fontSize: 12)),
                Text(value,
                    style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
