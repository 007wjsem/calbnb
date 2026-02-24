import 'package:flutter_test/flutter_test.dart';
import 'package:calbnb/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('App initializes correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    // The app should redirect to login initially.
    expect(find.text('Calbnb Login'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
  });
}
