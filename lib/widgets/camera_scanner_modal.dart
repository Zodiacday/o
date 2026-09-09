import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/camera_capture_result.dart';
import '../models/preview_connection.dart';
import '../theme/app_theme.dart';
import 'camera_mode_selector.dart';

/// Minimal in-app camera sheet for QR scanning and optional photo capture.
class CameraScannerModal extends StatefulWidget {
  final bool cameraEnabled;

  const CameraScannerModal({super.key, this.cameraEnabled = true});

  static Future<CameraCaptureResult?> show(BuildContext context) {
    return showModalBottomSheet<CameraCaptureResult>(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.58),
      builder: (_) => const CameraScannerModal(),
    );
  }

  @override
  State<CameraScannerModal> createState() => _CameraScannerModalState();
}

class _CameraScannerModalState extends State<CameraScannerModal> {
  MobileScannerController? _scannerController;
  CameraController? _photoController;
  CameraMode _mode = CameraMode.scan;
  XFile? _capturedPhoto;
  String? _errorMessage;
  bool _isBusy = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _scannerController = _createScannerController();
  }

  @override
  void dispose() {
    final scannerController = _scannerController;
    if (scannerController != null) {
      unawaited(scannerController.dispose());
    }
    final photoController = _photoController;
    if (photoController != null) {
      unawaited(photoController.dispose());
    }
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_mode != CameraMode.scan || _isProcessing) return;

    for (final barcode in capture.barcodes) {
      final connection = PreviewConnection.tryParse(barcode.rawValue ?? '');
      if (connection == null) continue;

      _isProcessing = true;
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop(QrCameraCapture(connection));
      return;
    }
  }

  Future<void> _setMode(CameraMode nextMode) async {
    if (_mode == nextMode || _isBusy || _capturedPhoto != null) return;

    if (!widget.cameraEnabled) {
      setState(() => _mode = nextMode);
      return;
    }

    setState(() {
      _mode = nextMode;
      _errorMessage = null;
      _isBusy = true;
    });

    try {
      if (nextMode == CameraMode.scan) {
        await _disposePhotoController();
        await _initializeScannerController();
      } else {
        await _disposeScannerController();
        await _initializePhotoController();
      }
    } on CameraException catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Camera access is unavailable.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Camera access is unavailable.';
        });
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  MobileScannerController _createScannerController() {
    return MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );
  }

  Future<void> _initializeScannerController() async {
    final controller = _createScannerController();
    if (!mounted) {
      await controller.dispose();
      return;
    }
    setState(() => _scannerController = controller);
  }

  Future<void> _disposeScannerController() async {
    final controller = _scannerController;
    _scannerController = null;
    if (controller != null) await controller.dispose();
  }

  Future<void> _initializePhotoController() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw CameraException('NoCamera', 'No camera is available.');
    }

    final rearCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
    final controller = CameraController(
      rearCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await controller.initialize();
      try {
        await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
      } catch (_) {
        // Certain test environments or devices may not support orientation locking.
      }
      if (!mounted) {
        await controller.dispose();
        return;
      }
      _photoController = controller;
    } catch (_) {
      await controller.dispose();
      rethrow;
    }
  }

  Future<void> _disposePhotoController() async {
    final controller = _photoController;
    _photoController = null;
    if (controller != null) {
      try {
        await controller.unlockCaptureOrientation();
      } catch (_) {}
      await controller.dispose();
    }
  }

  Future<void> _takePhoto() async {
    final controller = _photoController;
    if (_mode != CameraMode.photo ||
        controller == null ||
        !controller.value.isInitialized ||
        _isBusy) {
      return;
    }

    setState(() => _isBusy = true);
    try {
      final photo = await controller.takePicture();
      if (mounted) {
        HapticFeedback.mediumImpact();
        setState(() => _capturedPhoto = photo);
      }
    } on CameraException catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'The photo could not be captured.');
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  void _retakePhoto() {
    HapticFeedback.lightImpact();
    setState(() => _capturedPhoto = null);
  }

  void _usePhoto() {
    final photo = _capturedPhoto;
    if (photo == null) return;

    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(PhotoCameraCapture(photo));
  }

  void _close() {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final sheetHeight = MediaQuery.sizeOf(context).height * 0.64;

    return Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        key: const ValueKey('previewport-camera-sheet'),
        height: sheetHeight,
        width: double.infinity,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: Stack(
              children: [
                Positioned.fill(child: _buildPreview()),
                _buildTopControls(),
                _buildBottomControls(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    if (!widget.cameraEnabled) {
      return const ColoredBox(color: Colors.black);
    }

    if (_errorMessage != null) {
      return _CameraError(message: _errorMessage!, onClose: _close);
    }

    final photo = _capturedPhoto;
    if (photo != null) {
      return FutureBuilder<Uint8List>(
        future: photo.readAsBytes(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.cyan),
            );
          }
          return Image.memory(snapshot.data!, fit: BoxFit.cover);
        },
      );
    }

    if (_mode == CameraMode.scan) {
      final scannerController = _scannerController;
      if (scannerController == null) {
        return const Center(
          child: CircularProgressIndicator(color: AppTheme.cyan),
        );
      }
      return MobileScanner(
        controller: scannerController,
        onDetect: _onDetect,
        errorBuilder: (context, error) => _CameraError(
          message: 'Camera access is unavailable.',
          onClose: _close,
        ),
      );
    }

    final photoController = _photoController;
    if (photoController == null || !photoController.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.cyan),
      );
    }

    final previewSize = photoController.value.previewSize;
    // Sensor previewSize is landscape (width > height, e.g. 1920 x 1080).
    // In portrait orientation, width is the smaller dimension and height is the larger.
    final pWidth = previewSize != null ? previewSize.height : 9.0;
    final pHeight = previewSize != null ? previewSize.width : 16.0;

    return ClipRect(
      key: const ValueKey('previewport-photo-preview'),
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: pWidth,
            height: pHeight,
            child: CameraPreview(photoController),
          ),
        ),
      ),
    );
  }

  Widget _buildTopControls() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 58,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 11),
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.58),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 14, top: 5),
                  child: Semantics(
                    button: true,
                    label: 'Close camera',
                    hint: 'Returns to the PreviewPort home screen',
                    child: IconButton(
                      onPressed: _close,
                      tooltip: 'Close camera',
                      icon: const Icon(
                        CupertinoIcons.xmark,
                        color: Colors.white,
                        size: 19,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    final photoTaken = _capturedPhoto != null;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
          child: photoTaken
              ? _buildPhotoConfirmation()
              : _buildCameraControls(),
        ),
      ),
    );
  }

  Widget _buildCameraControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CameraModeSelector(value: _mode, onChanged: _setMode),
        if (_mode == CameraMode.photo) ...[
          const SizedBox(height: 14),
          Semantics(
            button: true,
            label: 'Take photo',
            hint: 'Captures a photo for review',
            child: GestureDetector(
              onTap: _takePhoto,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.cyan,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.lightBlue.withValues(alpha: 0.82),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.cyan.withValues(alpha: 0.32),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt_outlined,
                  size: 28,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPhotoConfirmation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        OutlinedButton(
          onPressed: _retakePhoto,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: BorderSide(color: Colors.white.withValues(alpha: 0.45)),
            minimumSize: const Size(110, 44),
          ),
          child: const Text('Retake'),
        ),
        const SizedBox(width: 12),
        FilledButton(
          onPressed: _usePhoto,
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.cyan,
            foregroundColor: Colors.black,
            minimumSize: const Size(110, 44),
          ),
          child: const Text('Use Photo'),
        ),
      ],
    );
  }
}

class _CameraError extends StatelessWidget {
  final String message;
  final VoidCallback onClose;

  const _CameraError({required this.message, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.camera_fill,
              size: 36,
              color: AppTheme.textMuted,
            ),
            const SizedBox(height: 12),
            const Text(
              'Camera unavailable',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(onPressed: onClose, child: const Text('Close')),
          ],
        ),
      ),
    );
  }
}
