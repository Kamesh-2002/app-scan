import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/encryption_service.dart';

class GenerateScreen extends StatefulWidget {
  const GenerateScreen({super.key});

  @override
  State<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends State<GenerateScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _qrKey = GlobalKey();

  String? _generatedQRData;
  bool _isSaving = false;
  bool _showQR = false;

  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _generate() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final qrData = EncryptionService.encodeContactToQR(
      _nameCtrl.text.trim(),
      _phoneCtrl.text.trim(),
    );

    setState(() {
      _generatedQRData = qrData;
      _showQR = true;
    });

    _animCtrl.reset();
    _animCtrl.forward();
    HapticFeedback.mediumImpact();
  }

  void _clear() {
    setState(() {
      _generatedQRData = null;
      _showQR = false;
      _nameCtrl.clear();
      _phoneCtrl.clear();
    });
    _animCtrl.reset();
  }

  Future<void> _shareQR() async {
    try {
      setState(() => _isSaving = true);
      final boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/qr_${_nameCtrl.text.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'QR Code - ${_nameCtrl.text}',
        text:
            'QR code for ${_nameCtrl.text} (${_phoneCtrl.text}), generated with App Scan.',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveToGallery() async {
    try {
      setState(() => _isSaving = true);
      final boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final dir;
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download');

        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
      } else {
        dir = await getApplicationDocumentsDirectory();
      }
      final fileName =
          'qr_${_nameCtrl.text.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(pngBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('Saved to: $fileName',
                    style: GoogleFonts.spaceGrotesk(fontSize: 13)),
              ],
            ),
            backgroundColor: const Color(0xFFF51424),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1118),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFF8C700).withOpacity(0.15),
                    const Color(0xFFF51424).withOpacity(0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: const Color(0xFFF8C700).withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8C700).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.add_box_rounded,
                        color: Color(0xFFF8C700), size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Generate QR Code',
                            style: GoogleFonts.spaceGrotesk(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700)),
                        Text('Contact data is encrypted before encoding',
                            style: GoogleFonts.spaceGrotesk(
                                color: Colors.white54,
                                fontSize: 12,
                                height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Form
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Label('Full Name'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameCtrl,
                    style: const TextStyle(color: Colors.white),
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      hintText: 'e.g. John Doe',
                      prefixIcon:
                          Icon(Icons.person_outline, color: Color(0xFFF8C700)),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Name is required';
                      }
                      if (v.trim().length < 2) {
                        return 'Name must be at least 2 characters';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 18),
                  _Label('Phone Number'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _phoneCtrl,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      hintText: 'e.g. 98765 43210',
                      prefixIcon:
                          Icon(Icons.phone_outlined, color: Color(0xFFF8C700)),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Phone number is required';
                      }
                      final digits = v.replaceAll(RegExp(r'\D'), '');
                      if (digits.length < 7) {
                        return 'Enter a valid phone number';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _generate(),
                  ),
                  const SizedBox(height: 24),

                  // Encryption info banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF51424).withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFFF51424).withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_rounded,
                            color: Color(0xFFF51424), size: 16),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'QR data is encrypted. Only App can decode it.',
                            style: GoogleFonts.spaceGrotesk(
                                color: Colors.white60,
                                fontSize: 12,
                                height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _generate,
                          icon: const Icon(Icons.qr_code_rounded, size: 20),
                          label: const Text('Generate QR'),
                        ),
                      ),
                      if (_showQR) ...[
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: _clear,
                          child: Container(
                            height: 52,
                            width: 52,
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.redAccent.withOpacity(0.3)),
                            ),
                            child: const Icon(Icons.refresh_rounded,
                                color: Colors.redAccent, size: 22),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // QR Code result
            if (_showQR && _generatedQRData != null) ...[
              const SizedBox(height: 32),
              FadeTransition(
                opacity: _fadeAnim,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: _QRResultCard(
                    qrKey: _qrKey,
                    qrData: _generatedQRData!,
                    name: _nameCtrl.text.trim(),
                    phone: _phoneCtrl.text.trim(),
                    isSaving: _isSaving,
                    onShare: _shareQR,
                    onSave: _saveToGallery,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.spaceGrotesk(
          color: Colors.white70,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3),
    );
  }
}

class _QRResultCard extends StatelessWidget {
  final GlobalKey qrKey;
  final String qrData;
  final String name;
  final String phone;
  final bool isSaving;
  final VoidCallback onShare;
  final VoidCallback onSave;

  const _QRResultCard({
    required this.qrKey,
    required this.qrData,
    required this.name,
    required this.phone,
    required this.isSaving,
    required this.onShare,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1A2535),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF8C700).withOpacity(0.12),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top label
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF8C700), Color(0xFFF51424)],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_rounded, color: Colors.white, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'AES-256 Encrypted QR Code',
                    style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // QR code widget wrapped for screenshot
                RepaintBoundary(
                  key: qrKey,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 220,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Color(0xFF0A1118),
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Color(0xFF0A1118),
                      ),
                      embeddedImage: const AssetImage('assets/app_logo.jpg'),
                      embeddedImageStyle: const QrEmbeddedImageStyle(
                        size: Size(36, 36),
                      ),
                      errorStateBuilder: (ctx, err) => const SizedBox(
                        width: 220,
                        height: 220,
                        child: Center(
                          child: Icon(Icons.qr_code_2_rounded,
                              size: 120, color: Color(0xFF0A1118)),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Contact info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1923),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    children: [
                      _InfoRow(
                          icon: Icons.person_rounded,
                          label: 'Name',
                          value: name,
                          color: const Color(0xFFF8C700)),
                      const Divider(color: Colors.white10, height: 20),
                      _InfoRow(
                          icon: Icons.phone_rounded,
                          label: 'Phone',
                          value: phone,
                          color: const Color(0xFFF51424)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: _ActionBtn(
                        icon: Icons.share_rounded,
                        label: 'Share',
                        color: const Color(0xFFF8C700),
                        onTap: isSaving ? null : onShare,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionBtn(
                        icon: Icons.save_alt_rounded,
                        label: 'Save',
                        color: const Color(0xFFF51424),
                        onTap: isSaving ? null : onSave,
                      ),
                    ),
                  ],
                ),

                if (isSaving) ...[
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Color(0xFFF51424)),
                      ),
                      const SizedBox(width: 8),
                      Text('Processing...',
                          style: GoogleFonts.spaceGrotesk(
                              color: Colors.white54, fontSize: 13)),
                    ],
                  ),
                ],

                const SizedBox(height: 14),
                // Hint about scanning
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF51424).withOpacity(0.07),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFFF51424).withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: Color(0xFFF51424), size: 15),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Scan this QR with the Scan tab to auto-decrypt the contact details.',
                          style: GoogleFonts.spaceGrotesk(
                              color: Colors.white60, fontSize: 12, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _InfoRow(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.spaceGrotesk(
                    color: Colors.white38, fontSize: 11)),
            Text(value,
                style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
          ],
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _ActionBtn(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: onTap == null ? 0.5 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(label,
                  style: GoogleFonts.spaceGrotesk(
                      color: color, fontWeight: FontWeight.w700, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}
