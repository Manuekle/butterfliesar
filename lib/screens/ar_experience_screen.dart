import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:io' show Platform;
import 'package:url_launcher/url_launcher.dart';

import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math_64.dart' as vector_math64;

import 'package:butterfliesar/models/butterfly.dart';

class ARExperienceScreen extends StatefulWidget {
  final Butterfly butterfly;
  const ARExperienceScreen({required this.butterfly, super.key});

  @override
  State<ARExperienceScreen> createState() => _ARExperienceScreenState();
}

class _ARExperienceScreenState extends State<ARExperienceScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  AudioPlayer? _audioPlayer;

  late AnimationController _slideController;
  late Animation<Offset> _slide;

  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;

  bool _hasCameraPermission = false;
  bool _hasARSupport = true; // Will be updated in initState

  ARNode? butterflyNode;
  Timer? _rotationTimer;
  Timer? _floatingTimer;
  double _modelRotation = 0.0;
  double _floatingOffset = 0.0;
  bool _isARMode = true;
  bool _isDayBackground = true; // Toggle between day and night backgrounds

  // Variables para control de gestos mejorado
  bool _isModelSelected = false;
  vector_math64.Vector3 _currentPosition = vector_math64.Vector3(0, 0, -0.5);
  double _currentScale = 0.05; // Más pequeño por defecto
  double _initialScaleFactor = 1.0;
  vector_math64.Vector3 _dragStartPosition = vector_math64.Vector3.zero();

  // Variables para información
  bool _showingInfo = false;

  late final Butterfly selectedButterfly = widget.butterfly;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutQuart),
        );

    _slideController.forward();
    _checkARSupport();
    _checkCameraPermission();
    _loadModel();
    _startAutoAnimations();
    _playAmbientSound();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _playAmbientSound();
  }

  Future<void> _playAmbientSound() async {
    try {
      final soundPath = selectedButterfly.ambientSound;
      if (soundPath?.isNotEmpty ?? false) {
        final assetPath = soundPath!.startsWith('assets/')
            ? soundPath.substring(7)
            : soundPath;

        debugPrint('Loading sound from: $assetPath');
        _audioPlayer ??= AudioPlayer();
        await _audioPlayer?.setReleaseMode(ReleaseMode.loop);
        await _audioPlayer?.setVolume(0.3); // Volumen más bajo
        await _audioPlayer?.play(AssetSource(assetPath));
      }
    } catch (e) {
      if (mounted) {
        debugPrint('Error playing ambient sound: $e');
      }
    }
  }

  @override
  void dispose() {
    _stopAutoAnimations();
    _audioPlayer?.stop();
    _audioPlayer?.dispose();
    _rotationTimer?.cancel();
    _floatingTimer?.cancel();
    _slideController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Manejar toque para seleccionar/deseleccionar el modelo
  void _handleTap() {
    if (butterflyNode == null) return;

    setState(() {
      _isModelSelected = !_isModelSelected;
    });

    // Haptic feedback
    HapticFeedback.lightImpact();

    if (_isModelSelected) {
      _stopAutoAnimations();
      _showSelectionFeedback();
    } else {
      _startAutoAnimations();
    }
  }

  void _showSelectionFeedback() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Mariposa seleccionada - Usa gestos para mover y escalar',
          style: TextStyle(color: Colors.white),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // Manejar inicio del gesto de escala/arrastrado
  void _handleScaleStart(ScaleStartDetails details) {
    if (butterflyNode == null || !_isModelSelected) return;
    _initialScaleFactor = _currentScale;
    _dragStartPosition = vector_math64.Vector3.copy(_currentPosition);
  }

  // Manejar actualización del gesto
  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (butterflyNode == null || !_isModelSelected) return;

    // Manejar escalado con pellizco
    if (details.scale != 1.0) {
      _currentScale = (_initialScaleFactor * details.scale).clamp(0.02, 0.2);
    }

    // Manejar arrastrado (traslación) - más sensible
    final sensitivity = 0.002;
    final newX =
        _dragStartPosition.x - (details.focalPointDelta.dx * sensitivity);
    final newY =
        _dragStartPosition.y + (details.focalPointDelta.dy * sensitivity);
    final newZ = _dragStartPosition.z;

    _currentPosition = vector_math64.Vector3(
      newX.clamp(-2.0, 2.0),
      newY.clamp(-2.0, 2.0),
      newZ.clamp(-2.0, -0.2),
    );

    _updateButterflyTransform();
  }

  void _updateButterflyTransform() {
    if (butterflyNode == null) return;

    final transform = vector_math64.Matrix4.identity()
      ..setTranslation(_currentPosition)
      ..scale(_currentScale)
      ..rotateY(_modelRotation);

    butterflyNode!.transform = transform;
  }

  Future<void> _loadModel() async {
    if (!mounted) return;

    try {
      final modelPath = selectedButterfly.modelAsset;
      if (modelPath == null) {
        debugPrint('❌ No hay modelo 3D disponible para esta mariposa');
        return;
      }

      debugPrint('🔄 Iniciando carga del modelo 3D: $modelPath');

      // Remover nodo previo
      if (butterflyNode != null && arObjectManager != null) {
        await arObjectManager?.removeNode(butterflyNode!);
        setState(() => butterflyNode = null);
      }

      // Crear nuevo nodo con escala inicial pequeña
      final newNode = ARNode(
        type: NodeType.localGLTF2,
        uri: modelPath,
        scale: vector_math64.Vector3.all(_currentScale),
        position: _currentPosition,
      );

      await arObjectManager?.addNode(newNode);

      if (!mounted) return;

      setState(() {
        butterflyNode = newNode;
      });

      debugPrint('✅ Modelo 3D cargado exitosamente');
      _startAutoAnimations();
    } catch (e) {
      debugPrint('❌ Error al cargar el modelo 3D: $e');
      if (mounted) {
        _showErrorSnackbar();
      }
    }
  }

  void _startAutoAnimations() {
    _startAutoRotation();
    _startFloatingAnimation();
  }

  void _stopAutoAnimations() {
    _rotationTimer?.cancel();
    _floatingTimer?.cancel();
  }

  void _startAutoRotation() {
    _rotationTimer?.cancel();

    _rotationTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (butterflyNode != null && mounted && !_isModelSelected) {
        _modelRotation += 0.02;
        if (_modelRotation > 2 * math.pi) {
          _modelRotation = 0;
        }
        _updateButterflyTransform();
      }
    });
  }

  void _startFloatingAnimation() {
    _floatingTimer?.cancel();

    _floatingTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (butterflyNode != null && mounted && !_isModelSelected) {
        _floatingOffset += 0.05;
        final baseY = _currentPosition.y;
        final floatingY = baseY + (math.sin(_floatingOffset) * 0.05);

        final floatingPosition = vector_math64.Vector3(
          _currentPosition.x,
          floatingY,
          _currentPosition.z,
        );

        final transform = vector_math64.Matrix4.identity()
          ..setTranslation(floatingPosition)
          ..scale(_currentScale)
          ..rotateY(_modelRotation);

        butterflyNode!.transform = transform;
      }
    });
  }

  Future<void> onARViewCreated(
    ARSessionManager sessionManager,
    ARObjectManager objectManager,
    ARAnchorManager anchorManager,
    ARLocationManager locationManager,
  ) async {
    if (!mounted) return;

    try {
      debugPrint('🔄 Inicializando sesión AR...');

      arSessionManager = sessionManager;
      arObjectManager = objectManager;

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      debugPrint('✅ Sesión AR inicializada exitosamente');

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await _loadModel();
      });
    } catch (e) {
      debugPrint('❌ Error crítico al inicializar AR: $e');
      if (mounted) {
        _showErrorSnackbar();
      }
    }
  }

  void _showErrorSnackbar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Error al cargar el modelo 3D'),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Reintentar',
          textColor: Theme.of(context).colorScheme.onError,
          onPressed: () {
            if (mounted) {
              _loadModel();
            }
          },
        ),
      ),
    );
  }

  void _showInfo() {
    setState(() {
      _showingInfo = true;
    });

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF1E2936) : Colors.white;
    final textColor = isDark ? Colors.white : theme.colorScheme.onSurface;
    final secondaryColor = isDark ? Colors.white70 : Colors.black54;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white24
                      : const Color.fromARGB(66, 70, 20, 20),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Butterfly image
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: isDark ? Colors.white10 : Colors.grey[100],
                            image: DecorationImage(
                              image: AssetImage(selectedButterfly.imageAsset),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Name and scientific name
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedButterfly.name,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                selectedButterfly.scientificName,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      fontStyle: FontStyle.italic,
                                      color: secondaryColor,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Description section
                    Text(
                      'Descripción',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      selectedButterfly.description,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: secondaryColor,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Info tip
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            LucideIcons.hand,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Toca la mariposa para seleccionarla y usa gestos para moverla',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: textColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).then((_) {
      setState(() {
        _showingInfo = false;
      });
    });
  }

  Future<void> _captureScreen() async {
    try {
      HapticFeedback.lightImpact();

      // Mostrar mensaje de captura
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(LucideIcons.camera, color: Colors.white),
              SizedBox(width: 8),
              Text('¡Captura simulada! Función en desarrollo'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('Error al capturar pantalla: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al capturar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Check if device supports AR
  Future<void> _checkARSupport() async {
    try {
      bool isSupported = false;

      // For mobile platforms, we'll assume AR is supported if the platform is Android or iOS
      // and the AR plugin is available
      if (Platform.isAndroid || Platform.isIOS) {
        // On mobile, we'll assume AR is available if we can import the plugin
        // A more robust check would require platform channels
        isSupported = true;
      }

      if (mounted) {
        setState(() {
          _hasARSupport = isSupported;
          // If AR is not supported, force static view
          if (!_hasARSupport) {
            _isARMode = false;
            debugPrint('AR is not supported on this device, using static view');
          } else {
            debugPrint('AR is supported on this device');
          }
        });
      }
    } catch (e) {
      debugPrint('Error checking AR support: $e');
      if (mounted) {
        setState(() {
          _hasARSupport = false;
          _isARMode = false;
          debugPrint('Error checking AR support, defaulting to static view');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      onScaleStart: _handleScaleStart,
      onScaleUpdate: _handleScaleUpdate,
      child: Scaffold(
        extendBodyBehindAppBar: false,
        body: Stack(
          children: [
            // Main content
            SafeArea(
              child: _hasARSupport && _isARMode
                  ? _buildARView()
                  : _buildStaticView(),
            ),

            // Navigation Controls
            Positioned(
              top: 16,
              left: 8,
              child: _buildBackButton(
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Atrás',
              ),
            ),
            // Only show AR toggle if device supports AR
            if (_hasARSupport)
              Positioned(
                top: 16,
                right: 8,
                child: _buildFloatingButton(
                  icon: _isARMode ? LucideIcons.image : LucideIcons.box,
                  onPressed: () {
                    setState(() {
                      _isARMode = !_isARMode;
                    });
                    HapticFeedback.selectionClick();
                  },
                  tooltip: _isARMode ? 'Vista previa' : 'Vista AR',
                ),
              ),

            // AR Controls - Floating action buttons
            if (_hasARSupport && _isARMode)
              Positioned(
                bottom: 24,
                right: 24,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Info Button
                    _buildFloatingButton(
                      icon: LucideIcons.info,
                      onPressed: _showInfo,
                      tooltip: 'Información',
                    ),
                    const SizedBox(height: 16),
                    // Capture Button
                    _buildFloatingButton(
                      icon: LucideIcons.camera,
                      onPressed: _captureScreen,
                      tooltip: 'Tomar foto',
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton({
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: const Icon(
          LucideIcons.chevronLeft,
          size: 22,
          color: Colors.white,
        ),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildFloatingButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.black87, size: 22),
        ),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _recheckCameraPermission();
    }
  }

  Future<void> _checkCameraPermission() async {
    final status = await Permission.camera.status;
    setState(() {
      _hasCameraPermission = status.isGranted;
    });
  }

  Future<void> _recheckCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted != _hasCameraPermission) {
      setState(() {
        _hasCameraPermission = status.isGranted;
      });
    }
  }

  Widget _buildNoPermissionView() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.camera, size: 48, color: Colors.white),
            const SizedBox(height: 20),
            const Text(
              'Permiso de cámara requerido',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'La aplicación necesita acceso a la cámara para mostrar la experiencia de realidad aumentada.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final status = await Permission.camera.request();
                if (status.isGranted) {
                  setState(() {
                    _hasCameraPermission = true;
                  });
                } else if (status.isPermanentlyDenied) {
                  await openAppSettings();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Conceder permiso',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildARView() {
    return Stack(
      children: [
        // Vista AR
        if (_hasCameraPermission)
          ARView(onARViewCreated: onARViewCreated)
        else
          _buildNoPermissionView(),

        // Indicador de modelo seleccionado
        if (_isModelSelected)
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.hand, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Mariposa seleccionada - Usa gestos',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

        // Instrucciones iniciales
        if (butterflyNode == null)
          Center(
            child: SlideTransition(
              position: _slide,
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: Theme.of(context).dividerColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.camera,
                        size: 40,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Busca una superficie plana',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Mueve tu dispositivo lentamente para detectar el plano donde aparecerá la mariposa',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.8),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 4,
                      width: 60,
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStaticView() {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(
            _isDayBackground
                ? 'assets/backgrounds/day.png'
                : 'assets/backgrounds/night.png',
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          // Mensaje informativo
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.phone_android, size: 64, color: Colors.white),
                const SizedBox(height: 16),
                const Text(
                  'Vista previa 3D',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Text(
                    'Ejecuta la aplicación en un dispositivo móvil o en la web para ver el modelo 3D',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 24),
              ],
            ),
          ),

          // 3D Model Controls
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Pellizca para hacer zoom',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ),

          // AR Mode Button with Day/Night Toggle
          Positioned(
            bottom: 24,
            right: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFloatingButton(
                  icon: LucideIcons.info,
                  onPressed: _showInfo,
                  tooltip: 'Información',
                ),
                const SizedBox(height: 16),
                _buildFloatingButton(
                  icon: _isDayBackground ? LucideIcons.sun : LucideIcons.moon,
                  onPressed: () {
                    setState(() {
                      _isDayBackground = !_isDayBackground;
                    });
                    HapticFeedback.lightImpact();
                  },
                  tooltip: _isDayBackground ? 'Modo día' : 'Modo noche',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
