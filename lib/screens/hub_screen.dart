import 'package:flutter/material.dart';

class HubScreen extends StatelessWidget {
  const HubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Mariposario RA',
                style: const TextStyle(
                  fontFamily: 'Geist',
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontSize: 20,
                  shadows: [
                    Shadow(
                      color: Colors.black38,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [Colors.indigo.shade800, Colors.purple.shade900]
                        : [Colors.blue.shade500, Colors.purple.shade500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                tooltip: 'Configuración',
                onPressed: () => Navigator.pushNamed(context, '/settings'),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              delegate: SliverChildListDelegate([
                _buildFeatureCard(
                  context: context,
                  icon: Icons.qr_code_scanner,
                  title: 'Escanear QR',
                  color: Colors.blue,
                  onTap: () => Navigator.pushNamed(context, '/qr'),
                ),
                _buildFeatureCard(
                  context: context,
                  icon: Icons.explore,
                  title: 'Explorar RA',
                  color: Colors.green,
                  onTap: () => Navigator.pushNamed(context, '/species'),
                ),
                _buildFeatureCard(
                  context: context,
                  icon: Icons.info_outline,
                  title: 'Información',
                  color: Colors.orange,
                  onTap: () => _showComingSoon(context),
                ),
                _buildFeatureCard(
                  context: context,
                  icon: Icons.photo_library,
                  title: 'Galería',
                  color: Colors.purple,
                  onTap: () => _showComingSoon(context),
                ),
              ]),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¡Bienvenido!',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Explora el maravilloso mundo de las mariposas con realidad aumentada. Escanea un código QR o selecciona una especie para comenzar.',
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.7), color],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '¡Próximamente! Esta característica estará disponible pronto.',
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
