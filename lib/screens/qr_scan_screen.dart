import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:butterfliesar/models/butterfly_loader.dart';
import 'package:butterfliesar/models/butterfly.dart';
import 'package:butterfliesar/screens/animated_butterfly_view.dart';

class QRScanScreen extends StatefulWidget {
  const QRScanScreen({super.key});

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen>
    with SingleTickerProviderStateMixin {
  late MobileScannerController _scannerController;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  bool _isScanning = true;
  bool _hasDetected = false;
  String? _lastScannedCode;

  @override
  void initState() {
    super.initState();

    _scannerController = MobileScannerController();

    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _onBarcodeDetect(BarcodeCapture capture) async {
    if (_hasDetected || !_isScanning) return;

    final barcode = capture.barcodes.firstOrNull;
    final code = barcode?.rawValue;

    if (code == null || code.isEmpty) return;

    // Evitar múltiples detecciones del mismo código
    if (_lastScannedCode == code) return;

    setState(() {
      _hasDetected = true;
      _isScanning = false;
      _lastScannedCode = code;
    });

    // Vibración de feedback
    _showScanFeedback();

    try {
      final butterflies = await loadButterfliesFromAssets();
      final butterfly = _findButterflyByCode(butterflies, code);

      if (butterfly != null && mounted) {
        // Navegar a la vista de la mariposa
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                AnimatedButterflyView(butterfly: butterfly),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOut,
                        ),
                      ),
                      child: child,
                    ),
                  );
                },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      } else {
        _showNotFoundDialog(code);
      }
    } catch (error) {
      _showErrorDialog(error.toString());
    }
  }

  Butterfly? _findButterflyByCode(List<Butterfly> butterflies, String code) {
    // Buscar por ID exacto
    try {
      return butterflies.firstWhere(
        (b) => b.id.toLowerCase() == code.toLowerCase(),
      );
    } catch (e) {
      // No encontrado por ID
    }

    // Buscar por nombre común
    try {
      return butterflies.firstWhere(
        (b) =>
            b.name.toLowerCase().replaceAll(' ', '') ==
            code.toLowerCase().replaceAll(' ', ''),
      );
    } catch (e) {
      // No encontrado por nombre
    }

    // Buscar por nombre científico
    try {
      return butterflies.firstWhere(
        (b) =>
            b.scientificName.toLowerCase().replaceAll(' ', '') ==
            code.toLowerCase().replaceAll(' ', ''),
      );
    } catch (e) {
      // No encontrado
    }

    return null;
  }

  void _showScanFeedback() {
    // Aquí podrías agregar vibración si tienes el paquete vibration
    // Vibration.vibrate(duration: 100);
  }

  void _showNotFoundDialog(String code) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.search_off, color: theme.colorScheme.error),
            const SizedBox(width: 8),
            const Text('No encontrado'),
          ],
        ),
        content: Text(
          'No se encontró ninguna mariposa con el código:\n"$code"',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetScanner();
            },
            child: const Text('Escanear otro'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Volver'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error),
            const SizedBox(width: 8),
            const Text('Error'),
          ],
        ),
        content: Text('Ocurrió un error al buscar la mariposa:\n$error'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetScanner();
            },
            child: const Text('Reintentar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Volver'),
          ),
        ],
      ),
    );
  }

  void _resetScanner() {
    setState(() {
      _hasDetected = false;
      _isScanning = true;
      _lastScannedCode = null;
    });
  }

  void _toggleFlash() {
    _scannerController.toggleTorch();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Escanear QR', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _toggleFlash,
            icon: const Icon(Icons.flash_on),
            tooltip: 'Alternar flash',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Escáner
          MobileScanner(
            controller: _scannerController,
            onDetect: _onBarcodeDetect,
            fit: BoxFit.cover,
          ),

          // Overlay de escaneo
          _buildScanOverlay(),

          // Instrucciones
          _buildInstructions(theme),

          // Estado de carga
          if (_hasDetected) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildScanOverlay() {
    return Center(
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  // Esquinas
                  ...List.generate(4, (index) => _buildCorner(index)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCorner(int index) {
    const size = 20.0;
    const thickness = 4.0;

    late final Alignment alignment;
    late final Widget child;

    switch (index) {
      case 0: // Top-left
        alignment = Alignment.topLeft;
        child = Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.white, width: thickness),
              left: BorderSide(color: Colors.white, width: thickness),
            ),
          ),
        );
        break;
      case 1: // Top-right
        alignment = Alignment.topRight;
        child = Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.white, width: thickness),
              right: BorderSide(color: Colors.white, width: thickness),
            ),
          ),
        );
        break;
      case 2: // Bottom-left
        alignment = Alignment.bottomLeft;
        child = Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.white, width: thickness),
              left: BorderSide(color: Colors.white, width: thickness),
            ),
          ),
        );
        break;
      case 3: // Bottom-right
        alignment = Alignment.bottomRight;
        child = Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.white, width: thickness),
              right: BorderSide(color: Colors.white, width: thickness),
            ),
          ),
        );
        break;
    }

    return Positioned.fill(
      child: Align(alignment: alignment, child: child),
    );
  }

  Widget _buildInstructions(ThemeData theme) {
    return Positioned(
      bottom: 120,
      left: 0,
      right: 0,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.qr_code_scanner, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(
              _isScanning
                  ? 'Enfoca el código QR dentro del marco'
                  : 'Procesando...',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Asegúrate de tener buena iluminación',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            SizedBox(height: 16),
            Text(
              'Buscando mariposa...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
