import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

class HubScreen extends StatelessWidget {
  const HubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Color palette
    final primaryColor = const Color(0xFF5E35B1);
    final backgroundColor = const Color(0xFFF8F5FF);
    final textColor = const Color(0xFF2D3748);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Background circles decoration
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -100,
            child: Transform.rotate(
              angle: -math.pi / 4,
              child: Container(
                width: 300,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  color: primaryColor.withOpacity(0.05),
                ),
              ),
            ),
          ),

          // Main content
          Column(
            children: [
              // App Bar
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: Text(
                  'MariposAR',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    letterSpacing: 0.5,
                  ),
                ),
                centerTitle: true,
                actions: [
                  // Settings button
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      icon: Icon(
                        Icons.settings_outlined,
                        color: textColor.withOpacity(0.7),
                        size: 24,
                      ),
                      tooltip: 'Configuración',
                      onPressed: () =>
                          Navigator.pushNamed(context, '/settings'),
                    ),
                  ),
                ],
              ),

              // Main content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¡Bienvenido!',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Explora el maravilloso mundo de las mariposas con realidad aumentada. Escanea un código QR o selecciona una especie para comenzar.',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: textColor.withOpacity(0.8),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Features grid
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        children: [
                          _buildFeatureCard(
                            context,
                            title: 'Explorar',
                            icon: Icons.explore_outlined,
                            color: const Color(0xFF6C5CE7),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            onTap: () =>
                                _showComingSoonSnackBar(context, 'Explorar'),
                          ),
                          _buildFeatureCard(
                            context,
                            title: 'Galería',
                            icon: Icons.photo_library_outlined,
                            color: const Color(0xFF00B894),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00B894), Color(0xFF55EFC4)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            onTap: () =>
                                _showComingSoonSnackBar(context, 'Galería'),
                          ),
                          _buildFeatureCard(
                            context,
                            title: 'Aprender',
                            icon: Icons.menu_book_outlined,
                            color: const Color(0xFFFD79A8),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFD79A8), Color(0xFFFF9FF3)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            onTap: () =>
                                _showComingSoonSnackBar(context, 'Aprender'),
                          ),
                          _buildFeatureCard(
                            context,
                            title: 'Jugar',
                            icon: Icons.videogame_asset_outlined,
                            color: const Color(0xFFFDCB6E),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFDCB6E), Color(0xFFFFEAA7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            onTap: () =>
                                _showComingSoonSnackBar(context, 'Jugar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    Gradient? gradient,
    required VoidCallback onTap,
  }) {
    final isGradient = gradient != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E5EA), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isGradient
                          ? gradient.colors.first.withOpacity(0.1)
                          : color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 26,
                      color: isGradient ? gradient.colors.first : color,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF2D3748),
                      letterSpacing: 0.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showComingSoonSnackBar(BuildContext context, String feature) {
    final primaryColor = Theme.of(context).primaryColor;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$feature estará disponible pronto',
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: primaryColor,
        elevation: 0,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    );
  }
}
