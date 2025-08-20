import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/onboarding_screen.dart';
import 'screens/hub_screen.dart';
import 'screens/species_selection_screen.dart';
import 'screens/preparation_screen.dart';
import 'screens/ar_experience_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/qr_scan_screen.dart';
import 'theme/theme_provider.dart';
import 'providers/butterfly_provider.dart';

void main() {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (context) => ButterflyProvider()..loadButterflies(),
        ),
      ],
      child: const MariposarioApp(),
    ),
  );
}

class MariposarioApp extends StatelessWidget {
  const MariposarioApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'Mariposario RA',
      theme: ThemeData.light().copyWith(
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontFamily: 'Geist',
            fontWeight: FontWeight.w700,
          ),
          displayMedium: TextStyle(
            fontFamily: 'Geist',
            fontWeight: FontWeight.w600,
          ),
          displaySmall: TextStyle(
            fontFamily: 'Geist',
            fontWeight: FontWeight.w600,
          ),
          headlineMedium: TextStyle(
            fontFamily: 'Geist',
            fontWeight: FontWeight.w600,
          ),
          headlineSmall: TextStyle(
            fontFamily: 'Geist',
            fontWeight: FontWeight.w600,
          ),
          titleLarge: TextStyle(
            fontFamily: 'Geist',
            fontWeight: FontWeight.w600,
          ),
          titleMedium: TextStyle(
            fontFamily: 'Geist',
            fontWeight: FontWeight.w500,
          ),
          titleSmall: TextStyle(
            fontFamily: 'Geist',
            fontWeight: FontWeight.w500,
          ),
          bodyLarge: TextStyle(
            fontFamily: 'Geist',
            fontWeight: FontWeight.w400,
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Geist',
            fontWeight: FontWeight.w400,
          ),
          bodySmall: TextStyle(
            fontFamily: 'Geist',
            fontWeight: FontWeight.w400,
          ),
          labelLarge: TextStyle(
            fontFamily: 'Geist',
            fontWeight: FontWeight.w500,
          ),
          labelMedium: TextStyle(
            fontFamily: 'Geist',
            fontWeight: FontWeight.w500,
          ),
          labelSmall: TextStyle(
            fontFamily: 'Geist',
            fontWeight: FontWeight.w400,
          ),
        ),
        appBarTheme: const AppBarTheme(
          titleTextStyle: TextStyle(
            fontFamily: 'Geist',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontFamily: 'Geist',
            fontWeight: FontWeight.w700,
          ),
          displayMedium: TextStyle(
            fontFamily: 'Geist',
            fontWeight: FontWeight.w600,
          ),
          displaySmall: TextStyle(
            fontFamily: 'Geist',
            fontWeight: FontWeight.w600,
          ),
          headlineMedium: TextStyle(
            fontFamily: 'Geist',
            fontWeight: FontWeight.w600,
          ),
          headlineSmall: TextStyle(
            fontFamily: 'Geist',
            fontWeight: FontWeight.w600,
          ),
          titleLarge: TextStyle(
            fontFamily: 'Geist',
            fontWeight: FontWeight.w600,
          ),
          titleMedium: TextStyle(
            fontFamily: 'Geist',
            fontWeight: FontWeight.w500,
          ),
          titleSmall: TextStyle(
            fontFamily: 'Geist',
            fontWeight: FontWeight.w500,
          ),
          bodyLarge: TextStyle(
            fontFamily: 'Geist',
            fontWeight: FontWeight.w400,
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Geist',
            fontWeight: FontWeight.w400,
          ),
          bodySmall: TextStyle(
            fontFamily: 'Geist',
            fontWeight: FontWeight.w400,
          ),
          labelLarge: TextStyle(
            fontFamily: 'Geist',
            fontWeight: FontWeight.w500,
          ),
          labelMedium: TextStyle(
            fontFamily: 'Geist',
            fontWeight: FontWeight.w500,
          ),
          labelSmall: TextStyle(
            fontFamily: 'Geist',
            fontWeight: FontWeight.w400,
          ),
        ),
        appBarTheme: const AppBarTheme(
          titleTextStyle: TextStyle(
            fontFamily: 'Geist',
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      themeMode: themeProvider.themeMode,
      initialRoute: '/',
      routes: {
        '/': (context) => OnboardingScreen(),
        '/hub': (context) => HubScreen(),
        '/species': (context) => const SpeciesSelectionScreen(),
        '/preparation': (context) => const PreparationScreen(),
        '/ar': (context) {
          final butterflyProvider = Provider.of<ButterflyProvider>(
            context,
            listen: false,
          );
          if (butterflyProvider.butterflies.isEmpty) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return ARExperienceScreen(
            butterfly: butterflyProvider.butterflies.first,
          );
        },
        '/species-selection': (context) => const SpeciesSelectionScreen(),
        '/settings': (context) => SettingsScreen(),
        '/qr': (context) => const QRScanScreen(),
      },
    );
  }
}
