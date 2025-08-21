import 'dart:async';
import 'dart:math' as math;

import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math_64.dart' as vector_math64;

import 'package:butterfliesar/models/butterfly.dart';
import 'package:butterfliesar/widgets/ar_controls.dart';

class ARExperienceScreen extends StatefulWidget {
  final Butterfly butterfly;
  const ARExperienceScreen({required this.butterfly, super.key});

  @override
  State<ARExperienceScreen> createState() => _ARExperienceScreenState();
}

class _ARExperienceScreenState extends State<ARExperienceScreen>
    with SingleTickerProviderStateMixin {
  AudioPlayer? _audioPlayer;

  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  late Animation<double> _controlsFade;

  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;

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
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controlsFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
    );
    Timer(const Duration(milliseconds: 80), () => _controller.forward());
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
    _controller.dispose();
    _audioPlayer?.stop();
    _audioPlayer?.dispose();
    _rotationTimer?.cancel();
    _floatingTimer?.cancel();

    // Eliminar nodo si existe
    if (butterflyNode != null && arObjectManager != null) {
      arObjectManager?.removeNode(butterflyNode!);
    }

    arObjectManager = null;
    arSessionManager = null;
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
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black87,
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Contenido
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            selectedButterfly.imageAsset,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedButterfly.name,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                selectedButterfly.scientificName,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey[600],
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Descripción',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Esta hermosa mariposa es parte de la rica biodiversidad de nuestro ecosistema. Observa sus colores únicos y patrones distintivos mientras flota delicadamente en el aire.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 20),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.white),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Toca la mariposa para seleccionarla y usa gestos para moverla',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
              Icon(Icons.camera_alt, color: Colors.white),
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      onScaleStart: _handleScaleStart,
      onScaleUpdate: _handleScaleUpdate,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.black.withOpacity(0.3),
          elevation: 0,
          title: Text(
            'RA - ${selectedButterfly.name}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: Icon(
                _isARMode ? Icons.image_outlined : Icons.camera_alt_outlined,
              ),
              tooltip: _isARMode
                  ? 'Ver fondo temático'
                  : 'Ver en Realidad Aumentada',
              onPressed: () {
                setState(() {
                  _isARMode = !_isARMode;
                });
                HapticFeedback.selectionClick();
              },
            ),
          ],
        ),
        body: SafeArea(child: _isARMode ? _buildARView() : _buildStaticView()),
      ),
    );
  }

  Widget _buildARView() {
    return Stack(
      children: [
        // Vista AR
        ARView(onARViewCreated: onARViewCreated),

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
                  Icon(Icons.touch_app, color: Colors.white, size: 18),
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
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: Container(
                  margin: const EdgeInsets.all(32),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.camera_alt_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Busca una superficie plana',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Mueve tu dispositivo lentamente para detectar el plano donde aparecerá la mariposa',
                        style: TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // Controles AR
        Positioned(
          bottom: 32,
          left: 0,
          right: 0,
          child: FadeTransition(
            opacity: _controlsFade,
            child: Center(
              child: ARControls(
                onInfo: _showInfo,
                onGrab: _captureScreen,
                onMenu: () => Navigator.pop(context),
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
          // Elementos decorativos de fondo
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Contenido principal
          Positioned(
            top: 16,
            right: 16,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isDayBackground = !_isDayBackground;
                });
                HapticFeedback.lightImpact();
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isDayBackground ? Icons.wb_sunny : Icons.nights_stay,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isDayBackground ? 'Día' : 'Noche',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Imagen de la mariposa con efecto 3D
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, -6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      selectedButterfly.imageAsset,
                      width: 200,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Información de la mariposa
                Text(
                  selectedButterfly.name,
                  style: const TextStyle(
                    fontSize: 28,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                Text(
                  selectedButterfly.scientificName,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontStyle: FontStyle.italic,
                    shadows: [Shadow(blurRadius: 6, color: Colors.black38)],
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // Indicadores de características
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      if (selectedButterfly.ambientSound != null) ...[
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.music_note,
                              color: Colors.white70,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Sonido ambiente activo',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.threed_rotation,
                            color: Colors.white70,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Modelo 3D disponible',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Botón para cambiar a AR
          Positioned(
            bottom: 32,
            right: 32,
            child: FloatingActionButton(
              onPressed: () {
                setState(() {
                  _isARMode = true;
                });
                HapticFeedback.selectionClick();
              },
              backgroundColor: Colors.white.withOpacity(0.9),
              child: const Icon(
                Icons.camera_alt_outlined,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
