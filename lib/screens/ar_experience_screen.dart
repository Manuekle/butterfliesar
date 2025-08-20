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
  double _modelRotation = 0.0;
  bool _isARMode = true;

  // Variables for gesture control
  bool _isModelSelected = false;
  vector_math64.Vector3 _initialPosition = vector_math64.Vector3(0, -0.2, -0.8);
  double _initialScale = 0.1;
  double _scale = 0.1;
  double _initialScaleFactor = 1.0;

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

    // Eliminar nodo si existe
    if (butterflyNode != null && arObjectManager != null) {
      arObjectManager?.removeNode(butterflyNode!);
    }

    arObjectManager = null;
    arSessionManager = null;
    super.dispose();
  }

  // Handle tap to select/deselect the model
  void _handleTap() {
    if (butterflyNode == null) return;

    setState(() {
      _isModelSelected = !_isModelSelected;
    });
  }

  // Handle scale with pinch gesture
  void _handleScaleStart(ScaleStartDetails details) {
    if (butterflyNode == null || !_isModelSelected) return;
    _initialScaleFactor = _scale;
    _initialPosition = vector_math64.Vector3.copy(butterflyNode!.position);
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (butterflyNode == null || !_isModelSelected) return;

    // Handle scaling
    if (details.scale != 1.0) {
      _scale = (_initialScaleFactor * details.scale).clamp(0.05, 0.5);
    }

    // Handle panning (translation)
    final newX = _initialPosition.x - (details.focalPointDelta.dx * 0.001);
    final newY = _initialPosition.y + (details.focalPointDelta.dy * 0.001);

    final newPosition = vector_math64.Vector3(
      newX.clamp(-1.0, 1.0), // Limit movement within reasonable bounds
      newY.clamp(-1.0, 1.0),
      _initialPosition.z,
    );

    final newTransform = vector_math64.Matrix4.identity()
      ..setTranslation(newPosition)
      ..scale(_scale)
      ..rotateY(_modelRotation);

    butterflyNode!.transform = newTransform;
  }

  Future<void> _loadModel() async {
    if (!mounted) return;

    try {
      final modelPath = selectedButterfly.modelAsset;
      if (modelPath == null) {
        debugPrint('❌ No hay modelo 3D disponible para esta mariposa');
        return;
      }

      debugPrint(
        '🔄 1. Iniciando carga del modelo 3D desde assets: $modelPath',
      );

      // Remover nodo previo
      if (butterflyNode != null && arObjectManager != null) {
        debugPrint('🗑️ 2. Eliminando nodo existente');
        await arObjectManager?.removeNode(butterflyNode!);
        setState(() => butterflyNode = null);
      }

      debugPrint('🎨 3. Creando nuevo nodo 3D');

      final newNode = ARNode(
        type: NodeType.localGLTF2, // ✅ usamos assets locales
        uri: modelPath, // Ejemplo: "assets/models/butterfly.glb"
        scale: vector_math64.Vector3(
          _initialScale,
          _initialScale,
          _initialScale,
        ),
        position: _initialPosition,
      );

      debugPrint('🔄 4. Añadiendo nodo a la escena...');

      await arObjectManager?.addNode(newNode);

      if (!mounted) return;

      setState(() {
        butterflyNode = newNode;
      });

      debugPrint('✅ 5. Modelo 3D cargado exitosamente');
      _startAutoRotation();
    } catch (e) {
      debugPrint('❌ Error al cargar el modelo 3D: $e');
      if (mounted) {
        _showErrorSnackbar();
      }
    }
  }

  void _startAutoRotation() {
    _rotationTimer?.cancel();

    if (!_isModelSelected) {
      _rotationTimer = Timer.periodic(const Duration(milliseconds: 32), (
        timer,
      ) {
        if (butterflyNode != null && mounted && !_isModelSelected) {
          setState(() {
            _modelRotation += 0.01;
            if (_modelRotation > 2 * math.pi) {
              _modelRotation = 0;
            }

            final position = butterflyNode!.position;
            final newTransform = vector_math64.Matrix4.identity()
              ..setTranslation(position)
              ..setRotationY(_modelRotation);

            butterflyNode!.transform = newTransform;
          });
        }
      });
    }
  }

  Future<void> onARViewCreated(
    ARSessionManager sessionManager,
    ARObjectManager objectManager,
    ARAnchorManager anchorManager,
    ARLocationManager locationManager,
  ) async {
    if (!mounted) return;

    try {
      debugPrint(' Inicializando sesión AR...');

      arSessionManager = sessionManager;
      arObjectManager = objectManager;

      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;

      debugPrint(' Sesión AR inicializada exitosamente');

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await _loadModel();
      });
    } catch (e) {
      debugPrint(' Error crítico al inicializar AR: $e');
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      onScaleStart: _handleScaleStart,
      onScaleUpdate: _handleScaleUpdate,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Experiencia RA - ${selectedButterfly.name}'),
          centerTitle: true,
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
        ARView(onARViewCreated: onARViewCreated),
        Center(
          child: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt_outlined,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Busca un espacio para ver la mariposa en RA.',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 32,
          left: 0,
          right: 0,
          child: FadeTransition(
            opacity: _controlsFade,
            child: Center(
              child: ARControls(
                onInfo: () {},
                onGrab: () {},
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
          image: AssetImage(selectedButterfly.imageAsset),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.4),
            BlendMode.darken,
          ),
        ),
      ),
      child: Center(
        child: Text(
          selectedButterfly.name,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.5),
                offset: const Offset(2, 2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
