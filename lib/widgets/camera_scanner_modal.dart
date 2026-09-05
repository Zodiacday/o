import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:toastification/toastification.dart';
import '../models/preview_connection.dart';
import 'manual_url_modal.dart';

/// Native Apple iOS Camera & QR Code Scanner Viewfinder
/// Implements Apple's signature #FFD60A yellow reticle brackets,
/// tap-to-focus animation, frosted glass HUD controls, and native hardware pipeline.
class CameraScannerModal extends StatefulWidget {
  const CameraScannerModal({super.key});

  static Future<PreviewConnection?> show(BuildContext context) {
    return showModalBottomSheet<PreviewConnection>(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const CameraScannerModal(),
    );
  }

  @override
  State<CameraScannerModal> createState() => _CameraScannerModalState();
}

class _CameraScannerModalState extends State<CameraScannerModal>
    with TickerProviderStateMixin {
  late final MobileScannerController _scannerController;
  late final AnimationController _scanLineController;
  late final Animation<double> _scanLineAnimation;

  // Tap to focus state
  Offset? _tapFocusPosition;
  late final AnimationController _focusBoxController;
  late final Animation<double> _focusScaleAnimation;
  late final Animation<double> _focusOpacityAnimation;

  bool _isProcessing = false;
  bool _torchOn = false;
  bool _cameraError = false;
  int _zoomLevel = 1; // 1x or 2x
  String? _detectedUrl;

  static const Color kAppleYellow = Color(0xFFFFD60A);
  static const Color kAppleFrostedBg = Color(0x661C1C1E);
  static const Color kMilledBorder = Color(0xFF1E2638);

  @override
  void initState() {
    super.initState();

    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    // Continuous scanning line animation
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _scanLineAnimation = Tween<double>(begin: 0.08, end: 0.92).animate(
      CurvedAnimation(
        parent: _scanLineController,
        curve: Curves.easeInOut,
      ),
    );

    // Tap to focus animation controller
    _focusBoxController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _focusScaleAnimation = Tween<double>(begin: 1.35, end: 1.0).animate(
      CurvedAnimation(
        parent: _focusBoxController,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOutBack),
      ),
    );

    _focusOpacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _focusBoxController,
        curve: const Interval(0.70, 1.0, curve: Curves.easeIn),
      ),
    );

    _focusBoxController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _tapFocusPosition = null);
      }
    });
  }

  @override
  void dispose() {
    _focusBoxController.dispose();
    _scanLineController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue ?? '';
      final connection = PreviewConnection.tryParse(raw);
      if (connection != null) {
        _isProcessing = true;
        HapticFeedback.heavyImpact();

        setState(() => _detectedUrl = connection.url);

        // Apple-style brief confirmation tick before launching
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) {
            Navigator.of(context).pop(connection);
          }
        });
        break;
      }
    }
  }

  void _handleTapToFocus(TapDownDetails details) {
    HapticFeedback.selectionClick();
    setState(() {
      _tapFocusPosition = details.localPosition;
    });
    _focusBoxController.forward(from: 0.0);
  }

  void _toggleZoom() {
    HapticFeedback.selectionClick();
    setState(() {
      _zoomLevel = _zoomLevel == 1 ? 2 : 1;
    });
    try {
      _scannerController.setZoomScale(_zoomLevel == 1 ? 0.0 : 0.5);
    } catch (_) {}
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();

    final connection = PreviewConnection.tryParse(text ?? '');
    if (connection != null) {
      HapticFeedback.mediumImpact();
      if (mounted) {
        Navigator.of(context).pop(connection);
      }
    } else {
      if (mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.warning,
          style: ToastificationStyle.flat,
          title: Text(
            text != null && text.isNotEmpty
                ? 'Invalid URL in Clipboard'
                : 'Clipboard is Empty',
          ),
          description: const Text(
            'Copy a valid preview URL (http:// or previewport://) first',
          ),
          alignment: Alignment.topCenter,
          autoCloseDuration: const Duration(seconds: 3),
          primaryColor: kAppleYellow,
          backgroundColor: const Color(0xFF000000),
          foregroundColor: Colors.white,
        );
      }
    }
  }

  void _openManualInput() {
    Navigator.of(context).pop();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF000000),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => ManualUrlModal(
        onConnect: (url, {title}) {
          final conn = PreviewConnection(
            url: url,
            projectName: title ?? 'Manual Link',
          );
          Navigator.of(context).pop(conn);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final sheetHeight = media.size.height * 0.90;

    return Container(
      height: sheetHeight,
      decoration: const BoxDecoration(
        color: Color(0xFF000000),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: kMilledBorder, width: 1),
          left: BorderSide(color: kMilledBorder, width: 1),
          right: BorderSide(color: kMilledBorder, width: 1),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Column(
          children: [
            // 1. Apple Grabber Bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 38,
                height: 4.5,
                decoration: BoxDecoration(
                  color: const Color(0xFF3A3A3C),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),

            // 2. Apple Camera Frosted Top Controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Flash / Torch Toggle Button
                  Bounceable(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _scannerController.toggleTorch();
                      setState(() => _torchOn = !_torchOn);
                    },
                    child: _buildFrostedCircle(
                      isActive: _torchOn,
                      child: Icon(
                        _torchOn
                            ? CupertinoIcons.bolt_fill
                            : CupertinoIcons.bolt_slash_fill,
                        size: 17,
                        color: _torchOn ? kAppleYellow : Colors.white,
                      ),
                    ),
                  ),

                  // Center Apple Zoom Indicator (1x / 2x)
                  Bounceable(
                    onTap: _toggleZoom,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: kAppleFrostedBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${_zoomLevel}x',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),

                  // Close Button
                  Bounceable(
                    onTap: () => Navigator.of(context).pop(),
                    child: _buildFrostedCircle(
                      child: const Icon(
                        CupertinoIcons.xmark,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // 3. Apple Camera Viewfinder Lens
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0D14),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: kMilledBorder, width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(19),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Camera Stream
                      MobileScanner(
                        controller: _scannerController,
                        onDetect: _onDetect,
                        errorBuilder: (context, error) {
                          _cameraError = true;
                          return _buildCameraFallback();
                        },
                      ),

                      // Gesture Detector for Native Tap-to-Focus
                      GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTapDown: _handleTapToFocus,
                      ),

                      // Active Tap-To-Focus Yellow Reticle Box
                      if (_tapFocusPosition != null)
                        AnimatedBuilder(
                          animation: _focusBoxController,
                          builder: (context, child) {
                            final scale = _focusScaleAnimation.value;
                            final opacity = _focusOpacityAnimation.value;
                            const boxSize = 64.0;

                            return Positioned(
                              left: _tapFocusPosition!.dx - (boxSize / 2),
                              top: _tapFocusPosition!.dy - (boxSize / 2),
                              child: Opacity(
                                opacity: opacity,
                                child: Transform.scale(
                                  scale: scale,
                                  child: Container(
                                    width: boxSize,
                                    height: boxSize,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: kAppleYellow,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                      // Signature Apple Yellow QR Tracking Brackets
                      if (!_cameraError) ...[
                        Center(
                          child: SizedBox(
                            width: 260,
                            height: 260,
                            child: Stack(
                              children: [
                                const Positioned.fill(
                                  child: CustomPaint(
                                    painter: _AppleYellowBracketsPainter(),
                                  ),
                                ),
                                // Smooth Vertical Laser Scan Bar
                                AnimatedBuilder(
                                  animation: _scanLineAnimation,
                                  builder: (context, _) {
                                    return Positioned(
                                      top: 260 * _scanLineAnimation.value,
                                      left: 18,
                                      right: 18,
                                      child: Container(
                                        height: 2,
                                        decoration: BoxDecoration(
                                          color: kAppleYellow,
                                          boxShadow: [
                                            BoxShadow(
                                              color: kAppleYellow.withValues(
                                                alpha: 0.6,
                                              ),
                                              blurRadius: 8,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Native Apple QR Link Detection Banner
                        if (_detectedUrl != null)
                          Positioned(
                            bottom: 24,
                            left: 20,
                            right: 20,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: kAppleYellow,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.5),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      CupertinoIcons.globe,
                                      size: 15,
                                      color: Colors.black,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        _detectedUrl!,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(
                                      CupertinoIcons.arrow_right_circle_fill,
                                      size: 15,
                                      color: Colors.black,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // 4. Apple Camera Bottom Control Shelf
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              color: const Color(0xFF000000),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Camera Mode Selector: "QR CODE" with Apple Yellow dot
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: kAppleYellow,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'QR CODE SCANNER',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: kAppleYellow,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Shelf Buttons Row: Clipboard, Shutter Mark, Camera Flip
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Quick Clipboard Paste Shortcut
                      Bounceable(
                        onTap: _pasteFromClipboard,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: kAppleFrostedBg,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  width: 1,
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  LucideIcons.clipboard,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Paste',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF8E8E93),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Iconic Apple Dual-Ring Shutter Mark
                      Bounceable(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          _scannerController.start();
                        },
                        child: Container(
                          width: 66,
                          height: 66,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 3.5,
                            ),
                          ),
                          child: Center(
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(
                                  CupertinoIcons.viewfinder,
                                  color: Colors.black,
                                  size: 26,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Camera Flip Button (Front / Back)
                      Bounceable(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          _scannerController.switchCamera();
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: kAppleFrostedBg,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  width: 1,
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  CupertinoIcons.camera_rotate,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Flip',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF8E8E93),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Manual Entry Link
                  Bounceable(
                    onTap: _openManualInput,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Can\'t scan? Enter port or URL manually',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF8E8E93),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            CupertinoIcons.chevron_right,
                            size: 11,
                            color: Color(0xFF8E8E93),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrostedCircle({required Widget child, bool isActive = false}) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: isActive
            ? kAppleYellow.withValues(alpha: 0.2)
            : kAppleFrostedBg,
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive ? kAppleYellow : Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Center(child: child),
    );
  }

  Widget _buildCameraFallback() {
    return Container(
      color: const Color(0xFF000000),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: kAppleFrostedBg,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: const Center(
                child: Icon(
                  CupertinoIcons.camera_fill,
                  size: 24,
                  color: Color(0xFF8E8E93),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Camera Not Detected',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'On iOS or Android devices, native AVFoundation/CameraX activates automatically. For browser testing, use Paste or Enter Manually below.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF8E8E93),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Signature Apple iOS Yellow QR Tracking Brackets Painter
class _AppleYellowBracketsPainter extends CustomPainter {
  const _AppleYellowBracketsPainter();

  static const Color yellow = Color(0xFFFFD60A);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = yellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;
    const arm = 38.0;
    const radius = 10.0;

    // Top-Left Corner
    final pathTL = Path()
      ..moveTo(0, arm)
      ..lineTo(0, radius)
      ..arcToPoint(const Offset(radius, 0), radius: const Radius.circular(radius))
      ..lineTo(arm, 0);
    canvas.drawPath(pathTL, paint);

    // Top-Right Corner
    final pathTR = Path()
      ..moveTo(w - arm, 0)
      ..lineTo(w - radius, 0)
      ..arcToPoint(Offset(w, radius), radius: const Radius.circular(radius))
      ..lineTo(w, arm);
    canvas.drawPath(pathTR, paint);

    // Bottom-Left Corner
    final pathBL = Path()
      ..moveTo(0, h - arm)
      ..lineTo(0, h - radius)
      ..arcToPoint(Offset(radius, h), radius: const Radius.circular(radius))
      ..lineTo(arm, h);
    canvas.drawPath(pathBL, paint);

    // Bottom-Right Corner
    final pathBR = Path()
      ..moveTo(w - arm, h)
      ..lineTo(w - radius, h)
      ..arcToPoint(Offset(w, h - radius), radius: const Radius.circular(radius))
      ..lineTo(w, h - arm);
    canvas.drawPath(pathBR, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
