class PreviewDiagnostic {
  final String stage;
  final String message;
  final String? file;
  final int? line;
  final int? column;
  final String? codeFrame;

  const PreviewDiagnostic({
    required this.stage,
    required this.message,
    this.file,
    this.line,
    this.column,
    this.codeFrame,
  });

  static PreviewDiagnostic? fromJson(Object? value) {
    if (value is! Map) return null;
    if (value['type'] != 'diagnostic') return null;

    final stage = _string(value['stage']);
    final message = _string(value['message']);
    if (stage == null || message == null) return null;

    final line = _positiveInt(value['line']);
    final column = _positiveInt(value['column']);
    return PreviewDiagnostic(
      stage: stage,
      message: message,
      file: _nonEmptyString(value['file']),
      line: line,
      column: column,
      codeFrame: _nonEmptyString(value['codeFrame']),
    );
  }

  factory PreviewDiagnostic.localError({
    required String message,
    String stage = 'connection',
  }) {
    return PreviewDiagnostic(
      stage: stage,
      message: message.trim().isEmpty ? 'Unable to load the preview.' : message,
    );
  }

  String get location {
    if (file == null) return '';
    final suffix = line == null
        ? ''
        : ':$line${column == null ? '' : ':$column'}';
    return '$file$suffix';
  }

  String get stageLabel {
    switch (stage) {
      case 'hot_reload':
        return 'Hot reload';
      case 'startup':
        return 'Startup';
      case 'runtime':
        return 'Runtime';
      case 'connection':
        return 'Connection';
      default:
        return stage.replaceAll('_', ' ');
    }
  }

  String get details {
    final buffer = StringBuffer()
      ..writeln('Preview failed')
      ..writeln('Stage: $stageLabel')
      ..writeln('Message: $message');
    if (location.isNotEmpty) buffer.writeln('Location: $location');
    if (codeFrame != null && codeFrame!.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln(codeFrame);
    }
    return buffer.toString().trimRight();
  }

  static String? _string(Object? value) {
    if (value is! String) return null;
    final result = value.trim();
    return result.isEmpty ? null : result;
  }

  static String? _nonEmptyString(Object? value) => _string(value);

  static int? _positiveInt(Object? value) {
    final parsed = value is int ? value : int.tryParse('$value');
    return parsed != null && parsed > 0 ? parsed : null;
  }
}
