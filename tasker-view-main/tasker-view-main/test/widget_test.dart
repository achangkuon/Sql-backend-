import 'package:flutter_test/flutter_test.dart';

import 'package:tasker_view/main.dart';

void main() {
  testWidgets('App initialization smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ServiTaskApp());

    // Verify that our app initializes with correct text.
    expect(find.text('ServiTask - App Initialization'), findsOneWidget);
  });
}
