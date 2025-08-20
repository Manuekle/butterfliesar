// qr_scan_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
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
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
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
    WidgetsBinding.instance.addObserver(this);
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
    _initAnimation();
    _checkCameraPermission();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Cuando la app regresa del foreground, re-verificar permisos
    if (state == AppLifecycleState.resumed && !_isCheckingPermission) {
      _recheckCameraPermission();
    }
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

  // Reemplazar la función _checkCameraPermission() en qr_scan_screen.dart

  Future<void> _checkCameraPermission() async {
    // Primero verificar el estado actual
    PermissionStatus status = await Permission.camera.status;
    print('Estado inicial del permiso: $status');

    if (status.isGranted) {
      // Ya tenemos permiso
      if (mounted) {
        setState(() {
          _hasCameraPermission = true;
          _isCheckingPermission = false;
        });
      }
      return;
    }

    if (status.isDenied) {
      // Permiso denegado pero podemos volver a pedir
      print('Permiso denegado, solicitando...');
      final result = await Permission.camera.request();
      print('Resultado de la solicitud: $result');

      if (mounted) {
        setState(() {
          _hasCameraPermission = result.isGranted;
          _isCheckingPermission = false;
        });

        if (result.isGranted) {
          print('✅ Permiso concedido');
        } else if (result.isPermanentlyDenied) {
          print('❌ Permiso permanentemente denegado');
          _showPermissionDeniedDialog();
        } else {
          print('❌ Permiso denegado por el usuario');
          _showPermissionDeniedDialog();
        }
      }
      return;
    }

    if (status.isPermanentlyDenied) {
      // El usuario seleccionó "No volver a preguntar" o está bloqueado
      print('Permiso permanentemente denegado');
      if (mounted) {
        setState(() {
          _hasCameraPermission = false;
          _isCheckingPermission = false;
        });
        _showPermissionDeniedDialog();
      }
      return;
    }

    if (status.isRestricted) {
      // Restringido por políticas del dispositivo (controles parentales, etc.)
      print('Permiso restringido por el sistema');
      if (mounted) {
        setState(() {
          _hasCameraPermission = false;
          _isCheckingPermission = false;
        });
        _showRestrictedDialog();
      }
      return;
    }

    // Estado desconocido, intentar solicitar de todos modos
    print('Estado desconocido del permiso, intentando solicitar...');
    final result = await Permission.camera.request();
    if (mounted) {
      setState(() {
        _hasCameraPermission = result.isGranted;
        _isCheckingPermission = false;
      });

      if (!result.isGranted) {
        _showPermissionDeniedDialog();
      }
    }
  }

  // Agregar también este método para casos de restricción
  void _showRestrictedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Acceso a cámara restringido'),
        content: const Text(
          'El acceso a la cámara está restringido en este dispositivo. '
          'Esto puede deberse a controles parentales u otras restricciones del sistema.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Future<void> _recheckCameraPermission() async {
    final status = await Permission.camera.status;
    debugPrint('Rechecking camera permission: $status');

    if (status.isGranted && !_hasCameraPermission) {
      setState(() {
        _hasCameraPermission = true;
      });
    } else if (!status.isGranted && _hasCameraPermission) {
      setState(() {
        _hasCameraPermission = false;
      });
    }
  }

  void _showPermissionDeniedDialog() {
    if (Platform.isIOS) {
      _showCupertinoPermissionDialog();
    } else {
      _showMaterialPermissionDialog();
    }
  }

  void _showCupertinoPermissionDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Permiso de cámara requerido'),
        content: const Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: Text(
            'Para escanear códigos QR, necesitamos acceso a la cámara. Por favor, activa los permisos de cámara en Configuración.',
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Configuración'),
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
          ),
        ],
      ),
    );
  }

  void _showMaterialPermissionDialog() {
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
              Navigator.pop(context);
              openAppSettings();
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
    if (Platform.isIOS) {
      _showCupertinoNotFoundDialog(code);
    } else {
      _showMaterialNotFoundDialog(code);
    }
  }

  void _showCupertinoNotFoundDialog(String code) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('No encontrado'),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            'No se encontró ninguna mariposa con el código:\n"$code"',
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Volver'),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Escanear otro'),
            onPressed: () {
              Navigator.pop(context);
              _resetScanner();
            },
          ),
        ],
      ),
    );
  }

  void _showMaterialNotFoundDialog(String code) {
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
              Navigator.pop(context);
            },
            child: const Text('Volver'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetScanner();
            },
            child: const Text('Escanear otro'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    if (Platform.isIOS) {
      _showCupertinoErrorDialog(error);
    } else {
      _showMaterialErrorDialog(error);
    }
  }

  void _showCupertinoErrorDialog(String error) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text('Ocurrió un error al buscar la mariposa:\n$error'),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Volver'),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Reintentar'),
            onPressed: () {
              Navigator.pop(context);
              _resetScanner();
            },
          ),
        ],
      ),
    );
  }

  void _showMaterialErrorDialog(String error) {
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
              Navigator.pop(context);
            },
            child: const Text('Volver'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetScanner();
            },
            child: const Text('Reintentar'),
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
    WidgetsBinding.instance.removeObserver(this);
    _scannerController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingPermission) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (Platform.isIOS)
                const CupertinoActivityIndicator(
                  color: Colors.white,
                  radius: 20,
                )
              else
                const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 16),
              const Text(
                'Verificando permisos...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    if (!_hasCameraPermission) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Permiso requerido',
            style: TextStyle(color: Colors.white),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.camera_alt, size: 64, color: Colors.white54),
                const SizedBox(height: 24),
                const Text(
                  'Se requiere permiso de cámara',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Para escanear códigos QR, necesitamos acceso a la cámara.',
                  style: TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (Platform.isIOS) ...[
                  CupertinoButton.filled(
                    onPressed: _checkCameraPermission,
                    child: const Text('Reintentar'),
                  ),
                  const SizedBox(height: 12),
                  CupertinoButton(
                    onPressed: openAppSettings,
                    child: const Text('Abrir Configuración'),
                  ),
                ] else ...[
                  ElevatedButton(
                    onPressed: _checkCameraPermission,
                    child: const Text('Reintentar'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: openAppSettings,
                    child: const Text('Abrir configuración'),
                  ),
                ],
              ],
            ),
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
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (Platform.isIOS)
              const CupertinoActivityIndicator(color: Colors.white, radius: 20)
            else
              const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            const SizedBox(height: 16),
            const Text(
              'Buscando mariposa...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
