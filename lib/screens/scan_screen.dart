import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/scan_record.dart';
import '../services/database_service.dart';
import '../services/encryption_service.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  MobileScannerController? _controller;
  bool _isProcessing = false;
  bool _isScannerActive = false;
  ScanRecord? _lastScanned;
  bool _torchOn = false;

  void _startScanner() {
    setState(() {
      _isScannerActive = true;
      _controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
      );
    });
  }

  void _stopScanner() {
    _controller?.dispose();
    setState(() {
      _isScannerActive = false;
      _controller = null;
    });
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final raw = barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) return;

    setState(() => _isProcessing = true);
    HapticFeedback.mediumImpact();

    // Try to decrypt
    final contactData = EncryptionService.decodeContactFromQR(raw);
    final isEncrypted = contactData != null;

    final record = ScanRecord(
      rawData: raw,
      decryptedName: contactData?['name'],
      decryptedPhone: contactData?['phone'],
      isEncrypted: isEncrypted,
      scannedAt: DateTime.now(),
    );

    final saved = await DatabaseService.instance.insertOrUpdateScan(record);

    if (mounted) {
      setState(() {
        _lastScanned = saved;
        _isProcessing = false;
      });
      _showResultSheet(saved);
    }
  }

  void _showResultSheet(ScanRecord record) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A2535),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _ScanResultSheet(
        record: record,
        stopScanner: _stopScanner,
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1118),
      body: _isScannerActive ? _buildScannerView() : _buildIdleView(),
    );
  }

  Widget _buildIdleView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00D4AA).withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
                borderRadius: BorderRadius.circular(80),
              ),
              child: const Icon(
                Icons.qr_code_scanner_rounded,
                size: 80,
                color: Color(0xFF00D4AA),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Ready to Scan',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Scan QR codes\nPoint your camera at QR code.',
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 15,
                color: Colors.white54,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 200,
              child: ElevatedButton.icon(
                onPressed: _startScanner,
                icon: const Icon(Icons.camera_alt_rounded),
                label: const Text('Start Scanning'),
              ),
            ),
            if (_lastScanned != null) ...[
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => _showResultSheet(_lastScanned!),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2535),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFF00D4AA).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: Color(0xFF00D4AA), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Last scanned',
                                style: GoogleFonts.spaceGrotesk(
                                    color: Colors.white54, fontSize: 12)),
                            Text(
                              _lastScanned!.displayTitle,
                              style: GoogleFonts.spaceGrotesk(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00D4AA).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '×${_lastScanned!.numScanCount}',
                          style: GoogleFonts.spaceGrotesk(
                              color: const Color(0xFF00D4AA),
                              fontWeight: FontWeight.w700,
                              fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScannerView() {
    return Stack(
      children: [
        MobileScanner(
          controller: _controller!,
          onDetect: _onDetect,
        ),
        // Overlay
        CustomPaint(
          painter: _ScanOverlayPainter(),
          child: const SizedBox.expand(),
        ),
        // Top controls
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _ControlButton(
                    icon: Icons.close_rounded,
                    onTap: _stopScanner,
                  ),
                  Text(
                    'Scanning...',
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                  ),
                  _ControlButton(
                    icon: _torchOn
                        ? Icons.flashlight_on_rounded
                        : Icons.flashlight_off_rounded,
                    onTap: () {
                      _controller?.toggleTorch();
                      setState(() => _torchOn = !_torchOn);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        // Bottom hint
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                'Align QR code within the frame',
                style: GoogleFonts.spaceGrotesk(
                    color: Colors.white70, fontSize: 14),
              ),
            ),
          ),
        ),
        if (_isProcessing)
          Container(
            color: Colors.black45,
            child: const Center(
              child: CircularProgressIndicator(color: Color(0xFF00D4AA)),
            ),
          ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ControlButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

class _ScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black54;
    final scanSize = size.width * 0.7;
    final left = (size.width - scanSize) / 2;
    final top = (size.height - scanSize) / 2;
    final scanRect = Rect.fromLTWH(left, top, scanSize, scanSize);

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);

    // Corner brackets
    final borderPaint = Paint()
      ..color = const Color(0xFF00D4AA)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const cornerLen = 28.0;
    final r = 16.0;

    // Top-left
    canvas.drawPath(
        Path()
          ..moveTo(left + cornerLen, top + r)
          ..lineTo(left + r, top + r)
          ..arcToPoint(Offset(left + r, top + r), radius: Radius.circular(r))
          ..lineTo(left + r, top + cornerLen),
        borderPaint);
    // Draw corners manually
    _drawCorner(canvas, borderPaint, left, top, r, cornerLen, 1, 1);
    _drawCorner(canvas, borderPaint, left + scanSize, top, r, cornerLen, -1, 1);
    _drawCorner(canvas, borderPaint, left, top + scanSize, r, cornerLen, 1, -1);
    _drawCorner(canvas, borderPaint, left + scanSize, top + scanSize, r,
        cornerLen, -1, -1);
  }

  void _drawCorner(Canvas canvas, Paint paint, double x, double y, double r,
      double len, double dx, double dy) {
    final path = Path();
    path.moveTo(x + dx * len, y + dy * r);
    path.lineTo(x + dx * r, y + dy * r);
    path.lineTo(x + dx * r, y + dy * len);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScanResultSheet extends StatelessWidget {
  final ScanRecord record;
  final VoidCallback stopScanner;
  const _ScanResultSheet({required this.record, required this.stopScanner});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: record.isEncrypted
                      ? const Color(0xFF7B61FF).withOpacity(0.15)
                      : const Color(0xFF00D4AA).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  record.isEncrypted
                      ? Icons.lock_rounded
                      : Icons.qr_code_rounded,
                  color: record.isEncrypted
                      ? const Color(0xFF7B61FF)
                      : const Color(0xFF00D4AA),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.isEncrypted
                          ? 'Encrypted QR Scanned'
                          : 'QR Code Scanned',
                      style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 17),
                    ),
                    Text(
                      'Scanned ${record.numScanCount} time${record.numScanCount! > 1 ? 's' : ''}',
                      style: GoogleFonts.spaceGrotesk(
                          color: Colors.white54, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D4AA).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '×${record.numScanCount}',
                  style: GoogleFonts.spaceGrotesk(
                      color: const Color(0xFF00D4AA),
                      fontWeight: FontWeight.w800,
                      fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white12),
          const SizedBox(height: 16),
          if (record.decryptedName != null && record.decryptedName!.isNotEmpty)
            _InfoRow(
                label: 'Name',
                value: record.decryptedName!,
                icon: Icons.person_outline),
          if (record.decryptedPhone != null &&
              record.decryptedPhone!.isNotEmpty)
            _InfoRow(
                label: 'Phone',
                value: record.decryptedPhone!,
                icon: Icons.phone_outlined),
          // _InfoRow(
          //     label: 'Data',
          //     value: record.rawData.length > 60
          //         ? '${record.rawData.substring(0, 60)}...'
          //         : record.rawData,
          //     icon: Icons.data_object_rounded),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                stopScanner();
                Navigator.pop(context);
              },
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _InfoRow(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF00D4AA), size: 18),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.spaceGrotesk(
                      color: Colors.white54, fontSize: 12)),
              Text(value,
                  style: GoogleFonts.spaceGrotesk(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}
