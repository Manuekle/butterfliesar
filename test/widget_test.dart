import 'package:flutter_test/flutter_test.dart';
import 'package:butterfliesar/main.dart';
import 'package:butterfliesar/providers/butterfly_provider.dart';
import 'package:butterfliesar/screens/onboarding_screen.dart';
import 'package:butterfliesar/theme/theme_provider.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('App should show home screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => ButterflyProvider()),
        ],
        child: const MariposarioApp(),
      ),
    );

    // Wait for the app to finish building
    await tester.pumpAndSettle();

    // Verify that the OnboardingScreen is shown
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });
}
