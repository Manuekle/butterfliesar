import 'dart:async';

import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:butterfliesar/models/butterfly.dart';
import 'package:vector_math/vector_math_64.dart';

import '../widgets/ar_controls.dart';
import 'package:audioplayers/audioplayers.dart';

class ARExperienceScreen extends StatefulWidget {
  final Butterfly butterfly;
  final VoidCallback? onSwitchToStatic;
  const ARExperienceScreen(
      {required this.butterfly, Key? key, this.onSwitchToStatic})
      : super(key: key);
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

  // AR session manager handles the AR session lifecycle
  ARSessionManager? arSessionManager;

  // Object manager handles 3D objects in the AR scene
  ARObjectManager? arObjectManager;

  // Node representing the butterfly model in the AR scene
  ARNode? butterflyNode;

  late final Butterfly selectedButterfly = widget.butterfly;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controlsFade = CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn));
    Timer(const Duration(milliseconds: 80), () => _controller.forward());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Play ambient sound when dependencies change
    _playAmbientSound();
  }

  Future<void> _playAmbientSound() async {
    try {
      if (selectedButterfly.ambientSound?.isNotEmpty ?? false) {
        _audioPlayer ??= AudioPlayer();
        await _audioPlayer?.setReleaseMode(ReleaseMode.loop);
        await _audioPlayer?.play(AssetSource(selectedButterfly.ambientSound!));
      }
    } catch (e) {
      if (mounted) {
        debugPrint('Error playing ambient sound: $e');
      }
    }
  }

  @override
  void dispose() {
    // Clean up animation controller
    _controller.dispose();

    // Clean up audio
    _audioPlayer?.stop();
    _audioPlayer?.dispose();

    // Dispose AR resources
    arObjectManager = null;
    arSessionManager = null;

    super.dispose();
  }

  /// Called when the AR view is created and ready
  ///
  /// [sessionManager] Manages the AR session
  /// [objectManager] Manages 3D objects in the scene
  /// [anchorManager] Manages AR anchors
  /// [locationManager] Manages AR location services
  Future<void> onARViewCreated(
    ARSessionManager sessionManager,
    ARObjectManager objectManager,
    ARAnchorManager anchorManager,
    ARLocationManager locationManager,
  ) async {
    if (!mounted) return;

    try {
      arSessionManager = sessionManager;
      arObjectManager = objectManager;

      debugPrint('Initializing AR session...');
      // No need to explicitly initialize session and object managers in this version
      // They are initialized automatically when the ARView is created
      debugPrint('AR session initialized successfully');

      // Load the selected butterfly model
      final modelPath = selectedButterfly.modelAsset;
      if (modelPath?.isNotEmpty ?? false) {
        debugPrint('Loading 3D model from: $modelPath');

        try {
          butterflyNode = ARNode(
            type: NodeType.localGLTF2,
            uri: modelPath!,
            scale: Vector3(0.5, 0.5, 0.5),
            position: Vector3(0.0, 0.0, -1.0),
            rotation: Vector4.zero(),
          );

          if (mounted && butterflyNode != null) {
            debugPrint('Adding 3D model to AR scene...');
            await arObjectManager?.addNode(butterflyNode!);
            debugPrint('3D model added successfully');
          }
        } catch (e, stackTrace) {
          debugPrint('❌ Error loading 3D model: $e');
          debugPrint('Stack trace: $stackTrace');
          rethrow;
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error initializing AR: $e');
      debugPrint('Stack trace: $stackTrace');

      if (mounted) {
        // Show error to user
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
                  onARViewCreated(
                    sessionManager,
                    objectManager,
                    anchorManager,
                    locationManager,
                  );
                }
              },
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Experiencia RA - ${selectedButterfly.name}'),
        centerTitle: true,
        actions: [
          if (widget.onSwitchToStatic != null)
            IconButton(
              icon: const Icon(Icons.image_outlined),
              tooltip: 'Ver fondo temático',
              onPressed: widget.onSwitchToStatic,
            ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // ARView integrado
            ARView(
              onARViewCreated: onARViewCreated,
              planeDetectionConfig: PlaneDetectionConfig.horizontal,
            ),
            // Overlay de instrucciones y animaciones
            Center(
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_outlined,
                          size: 80,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(height: 24),
                      Text(
                        'Apunta la cámara a una superficie plana para ver la mariposa en RA.',
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
        ),
      ),
    );
  }
}
