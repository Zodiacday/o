import 'package:flutter_test/flutter_test.dart';
import 'package:previewport/models/preview_connection.dart';

void main() {
  test('compact connection preserves preview, name and diagnostics', () {
    final result = PreviewConnection.tryParse(
      'PP1|192.168.0.25|8084|54321|abcdefghijklmnop|Daily-Tasks');
    expect(result?.url, 'http://192.168.0.25:8084');
    expect(result?.projectName, 'Daily-Tasks');
    expect(result?.controlUrl,
      'ws://192.168.0.25:54321/events?token=abcdefghijklmnop');
    expect(PreviewConnection.tryParse('PP1|host|99999|2|token|app'), isNull);
    expect(PreviewConnection.tryParse('PP1|host|80|2|token|%ZZ'), isNull);
  });
}
