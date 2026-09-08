import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:previewport/widgets/bug_annotator_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('BugAnnotatorModal renders tools and allows sending', (tester) async {
    // 1x1 transparent png
    final dummyPng = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
    );

    var sent = false;
    String? sentImage;

    await tester.pumpWidget(
      MaterialApp(
        home: BugAnnotatorModal(
          screenshotBytes: dummyPng,
          onSend: (base64, notes) {
            sent = true;
            sentImage = base64;
          },
        ),
      ),
    );

    expect(find.text('Annotate Bug'), findsOneWidget);
    expect(find.text('Arrow'), findsOneWidget);
    expect(find.text('Box'), findsOneWidget);
    expect(find.text('Pen'), findsOneWidget);
    expect(find.text('Send to PC'), findsOneWidget);

    await tester.tap(find.text('Send to PC'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(sent, isTrue);
    expect(sentImage, isNotEmpty);
  });
}
