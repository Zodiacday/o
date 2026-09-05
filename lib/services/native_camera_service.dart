import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:toastification/toastification.dart';
import '../models/preview_connection.dart';
import '../widgets/manual_url_modal.dart';

/// Native Operating System Camera & Scanner Service
/// Opens 100% native iOS (UIImagePickerController) and Android Camera intents,
/// exactly matching ChatGPT and Apple's native camera presentation.
class NativeCameraService {
  static final ImagePicker _picker = ImagePicker();

  /// Launches the native OS camera (iOS UIImagePickerController / Android Camera intent)
  static Future<PreviewConnection?> scanWithNativeCamera(
    BuildContext context,
  ) async {
    HapticFeedback.lightImpact();

    // On Web, show native platform instructions & quick connection dock
    if (kIsWeb) {
      return _showWebTestingSheet(context);
    }

    try {
      // 1. Opens 100% genuine native Apple iOS / Android camera
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
      );

      // User canceled or dismissed native camera sheet
      if (photo == null) {
        return null;
      }

      // 2. Decode QR payload using Apple Vision (iOS) or ML Kit (Android)
      if (!context.mounted) return null;
      return await _decodePhoto(context, photo.path);
    } catch (e) {
      if (context.mounted) {
        _showToast(
          context,
          'Camera Error',
          e.toString(),
          type: ToastificationType.error,
        );
      }
      return null;
    }
  }

  /// Opens the native photo gallery to scan a saved QR code screenshot
  static Future<PreviewConnection?> scanFromGallery(
    BuildContext context,
  ) async {
    HapticFeedback.lightImpact();

    if (kIsWeb) {
      return _showWebTestingSheet(context);
    }

    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
      );

      if (photo == null || !context.mounted) return null;
      return await _decodePhoto(context, photo.path);
    } catch (e) {
      if (context.mounted) {
        _showToast(
          context,
          'Gallery Error',
          e.toString(),
          type: ToastificationType.error,
        );
      }
      return null;
    }
  }

  static Future<PreviewConnection?> _decodePhoto(
    BuildContext context,
    String path,
  ) async {
    final controller = MobileScannerController();

    try {
      final BarcodeCapture? capture = await controller.analyzeImage(path);

      if (capture != null && capture.barcodes.isNotEmpty) {
        for (final barcode in capture.barcodes) {
          final raw = barcode.rawValue ?? '';
          final connection = PreviewConnection.tryParse(raw);
          if (connection != null) {
            HapticFeedback.heavyImpact();
            if (context.mounted) {
              _showToast(
                context,
                'QR Code Recognized',
                'Connecting to ${connection.projectName ?? connection.url}',
                type: ToastificationType.success,
              );
            }
            return connection;
          }
        }

        if (context.mounted) {
          _showToast(
            context,
            'Unrecognized QR Code',
            'Photo contains a QR code, but not a valid preview URL.',
            type: ToastificationType.warning,
          );
        }
      } else {
        if (context.mounted) {
          _showToast(
            context,
            'No QR Code Detected',
            'Please align the camera with the QR code and snap again.',
            type: ToastificationType.warning,
          );
        }
      }
    } finally {
      controller.dispose();
    }

    return null;
  }

  static Future<PreviewConnection?> _showWebTestingSheet(
    BuildContext context,
  ) {
    return showModalBottomSheet<PreviewConnection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF000000),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: Color(0xFF1E2638), width: 1),
            left: BorderSide(color: Color(0xFF1E2638), width: 1),
            right: BorderSide(color: Color(0xFF1E2638), width: 1),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF263347),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF000000),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF1E2638),
                      width: 1,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      LucideIcons.camera,
                      size: 18,
                      color: Color(0xFF00E5FF),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Native OS Camera Configured',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'iOS UIImagePickerController · Android Camera Intent',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Text(
              'On real iPhone & Android devices, tapping "Tap to Scan" opens the 100% native camera sheet (exactly like ChatGPT). For testing on desktop web, use instant clipboard or manual entry below:',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF94A3B8),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: Bounceable(
                    onTap: () async {
                      final data = await Clipboard.getData(Clipboard.kTextPlain);
                      final text = data?.text?.trim();
                      final conn = PreviewConnection.tryParse(text ?? '');
                      if (conn != null) {
                        HapticFeedback.mediumImpact();
                        if (ctx.mounted) {
                          Navigator.of(ctx).pop(conn);
                        }
                      } else {
                        if (ctx.mounted) {
                          _showToast(
                            ctx,
                            text != null && text.isNotEmpty
                                ? 'Invalid Clipboard URL'
                                : 'Clipboard is Empty',
                            'Copy an http:// or previewport:// URL first',
                            type: ToastificationType.warning,
                          );
                        }
                      }
                    },
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF000000),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF1E2638),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            LucideIcons.clipboard,
                            size: 15,
                            color: Color(0xFF00E5FF),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Paste Clipboard',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                Expanded(
                  child: Bounceable(
                    onTap: () {
                      Navigator.of(ctx).pop();
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: const Color(0xFF000000),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        builder: (_) => ManualUrlModal(
                          onConnect: (url, {title}) {
                            final conn = PreviewConnection(
                              url: url,
                              projectName: title ?? 'Manual Link',
                            );
                            Navigator.of(context).pop(conn);
                          },
                        ),
                      );
                    },
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF000000),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF1E2638),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            LucideIcons.keyboard,
                            size: 15,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Enter Manually',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  static void _showToast(
    BuildContext context,
    String title,
    String description, {
    required ToastificationType type,
  }) {
    toastification.show(
      context: context,
      type: type,
      style: ToastificationStyle.flat,
      title: Text(title),
      description: Text(description),
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 3),
      primaryColor: type == ToastificationType.success
          ? const Color(0xFF00E5FF)
          : (type == ToastificationType.error
              ? const Color(0xFFEF4444)
              : const Color(0xFFFFD60A)),
      backgroundColor: const Color(0xFF000000),
      foregroundColor: Colors.white,
    );
  }
}
