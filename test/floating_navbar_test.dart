import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:previewport/widgets/floating_navbar.dart';

void main() {
  testWidgets('navbar routes each item through the selected callback', (
    tester,
  ) async {
    int? selectedIndex;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FloatingNavBar(
            currentIndex: 0,
            onTabSelected: (index) => selectedIndex = index,
          ),
        ),
      ),
    );

    for (var index = 0; index < FloatingNavBar.navItems.length; index++) {
      final label = FloatingNavBar.navItems[index].label.toLowerCase();
      await tester.tap(find.byKey(ValueKey('navbar-$label')));
      await tester.pump();
      expect(selectedIndex, index);
    }
  });
}
