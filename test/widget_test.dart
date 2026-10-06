import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wedding_cart/main.dart';
import 'package:wedding_cart/opening/card_audio.dart';
import 'package:wedding_cart/opening/celebration.dart';
import 'package:wedding_cart/opening/door_half.dart';

void main() {
  // There is no audio plugin under `flutter test`.
  setUp(() => CardAudio.instance = const SilentCardAudio());

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

  testWidgets('Start plays the default doors opening', (
    WidgetTester tester,
  ) async {
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

  testWidgets('Every choice can be picked and opened', (
    WidgetTester tester,
  ) async {
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

  testWidgets('Gatefold swaps the options and opens', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Gatefold'));
    await tester.pump();
    expect(find.text('Background'), findsNothing);
    expect(find.text('Paper colour'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Ivory paper'));
    await tester.tap(find.bySemanticsLabel('Burgundy seal'));
    await tester.pump();
    expect(find.byType(DoorHalf), findsNothing);
    await openCard(tester);

    await tester.tap(find.byTooltip('Back to design'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Zoom'));
    await tester.pump();
    await openCard(tester);
  });

  testWidgets('Envelope and scroll have their own opening', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Envelope'));
    await tester.pump();
    expect(find.text('Envelope colour'), findsOneWidget);
    expect(find.text('Opening animation'), findsNothing);
    await tester.tap(find.bySemanticsLabel('Champagne paper'));
    await tester.tap(find.bySemanticsLabel('Silver seal'));
    await tester.pump();
    await openCard(tester);

    await tester.tap(find.byTooltip('Back to design'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Scroll'));
    await tester.pump();
    expect(find.text('Ribbon colour'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Blush ribbon'));
    await tester.pump();
    await openCard(tester);
  });

  testWidgets('Arabic and Islamic styles open', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 3400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Arabic'));
    await tester.pump();
    expect(find.text('Wall colour'), findsOneWidget);
    expect(find.text('Ornament colour'), findsOneWidget);
    expect(find.text('Opening animation'), findsNothing);
    await tester.tap(find.bySemanticsLabel('Emerald paper'));
    await tester.pump();
    await openCard(tester);

    await tester.tap(find.byTooltip('Back to design'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Islamic'));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Midnight paper'));
    await tester.tap(find.bySemanticsLabel('Silver ornament'));
    await tester.pump();
    await openCard(tester);
  });

  testWidgets('Initials reach the card and the celebration plays', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 3600);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Envelope'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'A & S');
    await tester.tap(find.text('Music'));
    await tester.pump();
    await openCard(tester);

    expect(find.text('A & S'), findsOneWidget);
    expect(find.byType(Celebration), findsOneWidget);

    await tester.tap(find.byTooltip('Mute'));
    await tester.pump();
    expect(find.byTooltip('Unmute'), findsOneWidget);

    await tester.tap(find.byTooltip('Replay'));
    await tester.pump();
    expect(find.byType(Celebration), findsNothing);
    expect(find.text('TAP TO OPEN'), findsOneWidget);
  });
}
