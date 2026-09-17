import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:toastification/toastification.dart';
import '../models/camera_capture_result.dart';
import '../models/preview_connection.dart';
import '../theme/app_theme.dart';
import '../widgets/app_toast.dart';
import '../widgets/camera_scanner_modal.dart';
import '../widgets/manual_url_modal.dart';

/// PreviewPort camera and QR scanning service.
/// Presents an in-app iOS-style camera surface for live QR detection while
/// retaining image-based scanning for the gallery fallback.
class NativeCameraService {
  static final ImagePicker _picker = ImagePicker();

  /// Opens the in-app camera scanner used by the primary Scan action.
  static Future<CameraCaptureResult?> scanWithNativeCamera(
    BuildContext context,
  ) async {
    HapticFeedback.lightImpact();

    // On Web, preserve the clipboard/manual URL fallback.
    if (kIsWeb) {
      return _showWebTestingSheet(context);
    }

    return CameraScannerModal.show(context);
  }

  /// Opens the native photo gallery to scan a saved QR code screenshot
  static Future<PreviewConnection?> scanFromGallery(
    BuildContext context,
  ) async {
    HapticFeedback.lightImpact();

    if (kIsWeb) {
      final result = await _showWebTestingSheet(context);
      return result is QrCameraCapture ? result.connection : null;
    }

    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.gallery);

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
    final controller = MobileScannerController(
      formats: const [BarcodeFormat.qrCode],
    );

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

  static Future<CameraCaptureResult?> _showWebTestingSheet(
    BuildContext context,
  ) {
    return showModalBottomSheet<CameraCaptureResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
        decoration: const BoxDecoration(
          color: Color(0xFF000000),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 34,
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppTheme.textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Connect preview',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Camera preview is available on iPhone and Android.',
                          style: GoogleFonts.inter(
                            color: AppTheme.textSecondary,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(
                      PhosphorIconsRegular.x,
                      size: 19,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildWebConnectionAction(
                icon: PhosphorIconsRegular.clipboardText,
                title: 'Paste from clipboard',
                subtitle: 'Use a URL already copied from your terminal.',
                onTap: () async {
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  final text = data?.text?.trim();
                  final conn = PreviewConnection.tryParse(text ?? '');
                  if (conn != null) {
                    HapticFeedback.mediumImpact();
                    if (ctx.mounted) {
                      Navigator.of(ctx).pop(QrCameraCapture(conn));
                    }
                  } else if (ctx.mounted) {
                    _showToast(
                      ctx,
                      text != null && text.isNotEmpty
                          ? 'Invalid URL'
                          : 'Clipboard is empty',
                      'Copy an http:// or https:// URL first',
                      type: ToastificationType.warning,
                    );
                  }
                },
              ),
              const Divider(height: 1, color: Color(0xFF141A26)),
              _buildWebConnectionAction(
                icon: PhosphorIconsRegular.keyboard,
                title: 'Enter URL',
                subtitle: 'Type the preview address manually.',
                onTap: () {
                  Navigator.of(ctx).pop();
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => ManualUrlModal(
                      onConnect: (url) {
                        final conn = PreviewConnection(
                          url: url,
                          projectName: 'Manual Link',
                        );
                        Navigator.of(context).pop(QrCameraCapture(conn));
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildWebConnectionAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Bounceable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.textMuted),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: AppTheme.textSecondary,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              PhosphorIconsRegular.caretRight,
              size: 16,
              color: AppTheme.textMuted,
            ),
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
    if (type == ToastificationType.success) {
      AppToast.success(context, title: title, description: description);
    } else if (type == ToastificationType.error) {
      AppToast.error(context, title: title, description: description);
    } else {
      AppToast.warning(context, title: title, description: description);
    }
  }
}
