import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:job_swipe/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    // Load env variables for testing
    await dotenv.load(fileName: ".env");

    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that MyApp exists.
    expect(find.byType(MyApp), findsOneWidget);
  });
}

