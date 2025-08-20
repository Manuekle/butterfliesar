// qr_scan_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
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
  bool _hasCameraPermission = false;
  bool _isCheckingPermission = true;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController();
    _initAnimation();
    _checkCameraPermission();
  }

  void _initAnimation() {
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  Future<void> _checkCameraPermission() async {
    final status = await Permission.camera.status;

    if (!status.isGranted) {
      // Only request if we haven't permanently denied the permission
      if (status.isPermanentlyDenied) {
        // On iOS, this means the user selected "Don't Ask Again"
        if (mounted) {
          setState(() {
            _hasCameraPermission = false;
            _isCheckingPermission = false;
          });
          _showPermissionDeniedDialog();
        }
        return;
      }

      // Request permission if not permanently denied
      final result = await Permission.camera.request();
      if (mounted) {
        setState(() {
          _hasCameraPermission = result.isGranted;
          _isCheckingPermission = false;
        });

        if (!result.isGranted && !result.isPermanentlyDenied) {
          // Show dialog if user denied but didn't select "Don't Ask Again"
          _showPermissionDeniedDialog();
        } else if (result.isPermanentlyDenied) {
          // Show dialog if user selected "Don't Ask Again"
          _showPermissionDeniedDialog();
        }
      }
    } else {
      // Permission already granted
      if (mounted) {
        setState(() {
          _hasCameraPermission = true;
          _isCheckingPermission = false;
        });
      }
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permiso de cámara requerido'),
        content: const Text(
          'Para escanear códigos QR, necesitamos acceso a la cámara. '
          'Por favor, activa los permisos de cámara en la configuración de la aplicación.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
            child: const Text('Abrir configuración'),
          ),
        ],
      ),
    );
  }

  Future<void> _onBarcodeDetect(BarcodeCapture capture) async {
    if (_hasDetected || !_isScanning) return;

    final barcode = capture.barcodes.firstOrNull;
    final code = barcode?.rawValue;

    if (code == null || code.isEmpty) return;

    if (_lastScannedCode == code) return;

    setState(() {
      _hasDetected = true;
      _isScanning = false;
      _lastScannedCode = code;
    });

    try {
      final butterflies = await loadButterfliesFromAssets();
      final butterfly = _findButterflyByCode(butterflies, code);

      if (butterfly != null && mounted) {
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
    try {
      return butterflies.firstWhere(
        (b) => b.id.toLowerCase() == code.toLowerCase(),
      );
    } catch (_) {}
    try {
      return butterflies.firstWhere(
        (b) =>
            b.name.toLowerCase().replaceAll(' ', '') ==
            code.toLowerCase().replaceAll(' ', ''),
      );
    } catch (_) {}
    try {
      return butterflies.firstWhere(
        (b) =>
            b.scientificName.toLowerCase().replaceAll(' ', '') ==
            code.toLowerCase().replaceAll(' ', ''),
      );
    } catch (_) {}
    return null;
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
  void dispose() {
    _scannerController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingPermission) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_hasCameraPermission) {
      return Scaffold(
        appBar: AppBar(title: const Text('Permiso requerido')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Se requiere permiso de cámara',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _checkCameraPermission,
                child: const Text('Reintentar'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: openAppSettings,
                child: const Text('Abrir configuración'),
              ),
            ],
          ),
        ),
      );
    }

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
          MobileScanner(
            controller: _scannerController,
            onDetect: _onBarcodeDetect,
            fit: BoxFit.cover,
          ),
          _buildScanOverlay(),
          _buildInstructions(Theme.of(context)),
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
                children: List.generate(4, (index) => _buildCorner(index)),
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
      case 0:
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
      case 1:
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
      case 2:
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
      case 3:
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
