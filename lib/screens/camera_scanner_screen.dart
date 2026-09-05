import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/preview_connection.dart';
import '../theme/app_theme.dart';

class CameraScannerScreen extends StatefulWidget {
  const CameraScannerScreen({super.key});

  @override
  State<CameraScannerScreen> createState() => _CameraScannerScreenState();
}

class _CameraScannerScreenState extends State<CameraScannerScreen>
    with SingleTickerProviderStateMixin {
  late final MobileScannerController _scannerController;
  late final AnimationController _animController;
  late final Animation<double> _scanLineAnimation;
  bool _isProcessing = false;
  bool _torchOn = false;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _scanLineAnimation = Tween<double>(begin: 0.08, end: 0.92).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    for (final barcode in capture.barcodes) {
      final connection = PreviewConnection.tryParse(barcode.rawValue ?? '');
      if (connection != null) {
        _isProcessing = true;
        HapticFeedback.mediumImpact();
        Navigator.of(context).pop(connection);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Live Camera Viewfinder
          Positioned.fill(
            child: MobileScanner(
              controller: _scannerController,
              onDetect: _onDetect,
              errorBuilder: (context, error) {
                return Container(
                  color: AppTheme.background,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.camera_alt_outlined,
                          size: 48,
                          color: AppTheme.textMuted,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Camera Access Required',
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Enable camera permission to scan development QR codes.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: AppTheme.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Back to Home'),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 2. Translucent Cutout Overlay
          Positioned.fill(
            child: CustomPaint(painter: _MinimalOverlayPainter()),
          ),

          // 3. Subtle Scan Line
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _scanLineAnimation,
              builder: (context, _) {
                final scanBoxSize = min(media.size.width * 0.70, 260.0);
                final topOffset = (media.size.height - scanBoxSize) / 2 - 30;
                final leftOffset = (media.size.width - scanBoxSize) / 2;

                return Positioned(
                  top: topOffset + (scanBoxSize * _scanLineAnimation.value),
                  left: leftOffset + 16,
                  width: scanBoxSize - 32,
                  child: Container(
                    height: 2.0,
                    decoration: BoxDecoration(
                      color: AppTheme.lightBlue,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.lightBlue.withValues(alpha: 0.6),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 4. Minimalist Header Controls
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Close / Back Button
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    Text(
                      'Scan QR',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),

                    // Controls: Torch & Camera Flip
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _scannerController.toggleTorch();
                            setState(() => _torchOn = !_torchOn);
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Icon(
                              _torchOn
                                  ? Icons.flash_on_rounded
                                  : Icons.flash_off_rounded,
                              size: 16,
                              color: _torchOn
                                  ? AppTheme.warning
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _scannerController.switchCamera();
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: const Icon(
                              Icons.flip_camera_ios_rounded,
                              size: 16,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 5. Instruction Label
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text(
                  'Point camera at terminal QR code',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MinimalOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final boxSize = min(size.width * 0.70, 260.0);
    final left = (size.width - boxSize) / 2;
    final top = (size.height - boxSize) / 2 - 30;
    final scanRect = Rect.fromLTWH(left, top, boxSize, boxSize);

    // Dimmed background outside the cutout
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutoutPath = Path()
      ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(16)));

    final overlayPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );
    final overlayPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;
    canvas.drawPath(overlayPath, overlayPaint);

    // Hairline Light Blue Corners
    final cornerPaint = Paint()
      ..color = AppTheme.lightBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    const cornerLength = 20.0;
    const r = 16.0;

    // Top-Left
    final tl = Path()
      ..moveTo(left, top + cornerLength)
      ..lineTo(left, top + r)
      ..arcToPoint(Offset(left + r, top), radius: const Radius.circular(r))
      ..lineTo(left + cornerLength, top);
    canvas.drawPath(tl, cornerPaint);

    // Top-Right
    final tr = Path()
      ..moveTo(left + boxSize - cornerLength, top)
      ..lineTo(left + boxSize - r, top)
      ..arcToPoint(
        Offset(left + boxSize, top + r),
        radius: const Radius.circular(r),
      )
      ..lineTo(left + boxSize, top + cornerLength);
    canvas.drawPath(tr, cornerPaint);

    // Bottom-Left
    final bl = Path()
      ..moveTo(left, top + boxSize - cornerLength)
      ..lineTo(left, top + boxSize - r)
      ..arcToPoint(
        Offset(left + r, top + boxSize),
        radius: const Radius.circular(r),
      )
      ..lineTo(left + cornerLength, top + boxSize);
    canvas.drawPath(bl, cornerPaint);

    // Bottom-Right
    final br = Path()
      ..moveTo(left + boxSize - cornerLength, top + boxSize)
      ..lineTo(left + boxSize - r, top + boxSize)
      ..arcToPoint(
        Offset(left + boxSize, top + boxSize - r),
        radius: const Radius.circular(r),
      )
      ..lineTo(left + boxSize, top + boxSize - cornerLength);
    canvas.drawPath(br, cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
