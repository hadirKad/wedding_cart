import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wedding_cart/main.dart';
import 'package:wedding_cart/opening/door_half.dart';

void main() {
  Future<void> openCard(WidgetTester tester) async {
    await tester.tap(find.text('Start'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('TAP TO OPEN'), findsOneWidget);
    await tester.tap(find.text('TAP TO OPEN'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));

    expect(find.text('TAP TO OPEN'), findsNothing);
    expect(find.text('Bride Name'), findsOneWidget);
  }

  testWidgets('Start plays the default doors opening',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Design your card'), findsOneWidget);

    await tester.tap(find.text('Start'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(DoorHalf), findsNWidgets(2));

    await tester.tap(find.text('TAP TO OPEN'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    expect(find.byType(DoorHalf), findsNothing);
    expect(find.text('Bride Name'), findsOneWidget);

    // Back returns to the design screen.
    await tester.tap(find.byTooltip('Back to design'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Design your card'), findsOneWidget);
  });

  testWidgets('Every choice can be picked and opened',
      (WidgetTester tester) async {
    // Tall enough that every option is on screen, not behind the Start bar.
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.bySemanticsLabel('Background 3'));
    await tester.tap(find.bySemanticsLabel('Burgundy bow'));
    await tester.tap(find.bySemanticsLabel('Cascade bow style'));
    await tester.tap(find.text('Zoom'));
    await tester.pump();
    await openCard(tester);

    await tester.tap(find.byTooltip('Back to design'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.bySemanticsLabel('Double bow style'));
    await tester.tap(find.text('Slide'));
    await tester.pump();
    await openCard(tester);
  });
}
