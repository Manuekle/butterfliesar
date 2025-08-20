import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:butterfliesar/models/butterfly.dart';
import 'package:butterfliesar/providers/butterfly_provider.dart';

class PreparationScreen extends StatefulWidget {
  const PreparationScreen({super.key});

  @override
  State<PreparationScreen> createState() => _PreparationScreenState();
}

class _PreparationScreenState extends State<PreparationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  Butterfly? selectedButterfly;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isInitialized) {
      _initializeButterfly();
      _isInitialized = true;
    }
  }

  void _initializeButterfly() {
    final args = ModalRoute.of(context)?.settings.arguments;
    final butterflyProvider = Provider.of<ButterflyProvider>(
      context,
      listen: false,
    );

    if (args is Butterfly) {
      selectedButterfly = args;
    } else if (butterflyProvider.butterflies.isNotEmpty) {
      selectedButterfly = butterflyProvider.butterflies.first;
    }

    // Iniciar animaciones después de un breve delay
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _animationController.forward();
      }
    });

    // Navegar automáticamente después de 3 segundos
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && selectedButterfly != null) {
        _navigateToAR();
      }
    });
  }

  void _navigateToAR() {
    if (selectedButterfly != null) {
      Navigator.pushReplacementNamed(
        context,
        '/ar',
        arguments: {'butterflyId': selectedButterfly!.id},
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        title: const Text('Preparando AR'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Imagen de la mariposa (si está disponible)
                if (selectedButterfly?.imageAsset.isNotEmpty == true)
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 120,
                      height: 120,
                      margin: const EdgeInsets.only(bottom: 32),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          selectedButterfly!.imageAsset,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: isDark
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.black.withOpacity(0.05),
                              child: Icon(
                                Icons.flutter_dash_outlined,
                                size: 60,
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                // Indicador de carga
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),

                const SizedBox(height: 32),

                // Título principal
                Text(
                  selectedButterfly?.name ?? 'Preparando experiencia AR',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                // Subtítulo
                if (selectedButterfly?.scientificName.isNotEmpty == true)
                  Text(
                    selectedButterfly!.scientificName,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),

                const SizedBox(height: 24),

                // Instrucciones
                Text(
                  'Detectando superficie...\nColoca el dispositivo sobre una mesa o piso bien iluminado.',
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // Botón para continuar manualmente
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: selectedButterfly != null
                          ? _navigateToAR
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Continuar',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: isDark ? Colors.black : Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward,
                            color: isDark ? Colors.black : Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
