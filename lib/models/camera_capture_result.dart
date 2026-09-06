import 'package:image_picker/image_picker.dart';

import 'preview_connection.dart';

/// Result returned by the in-app camera sheet.
sealed class CameraCaptureResult {
  const CameraCaptureResult();
}

final class QrCameraCapture extends CameraCaptureResult {
  final PreviewConnection connection;

  const QrCameraCapture(this.connection);
}

final class PhotoCameraCapture extends CameraCaptureResult {
  final XFile file;

  const PhotoCameraCapture(this.file);
}
