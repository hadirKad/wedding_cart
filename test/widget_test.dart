import 'package:flutter_test/flutter_test.dart';

import 'package:wedding_cart/main.dart';
import 'package:wedding_cart/opening/door_half.dart';

void main() {
  testWidgets('Tapping the cover opens the doors and removes them',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('TAP TO OPEN'), findsOneWidget);
    expect(find.byType(DoorHalf), findsNWidgets(2));

    await tester.tap(find.text('TAP TO OPEN'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));

    expect(find.text('TAP TO OPEN'), findsNothing);
    expect(find.byType(DoorHalf), findsNothing);
    expect(find.text('Bride Name'), findsOneWidget);
  });
}
