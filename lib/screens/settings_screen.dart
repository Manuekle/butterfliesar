import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tema', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.light_mode),
                const SizedBox(width: 8),
                const Text('Claro'),
                Switch(
                  value: isDark,
                  onChanged: (value) {
                    themeProvider.toggleTheme(value);
                  },
                ),
                const Text('Oscuro'),
                const SizedBox(width: 8),
                const Icon(Icons.dark_mode),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
