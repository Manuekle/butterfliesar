// lib/screens/ar_experience_screen.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart' as vector;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Imports condicionales para AR
import 'package:arkit_plugin/arkit_plugin.dart'
    if (dart.library.html) 'package:flutter/foundation.dart';
import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart'
    if (dart.library.html) 'package:flutter/foundation.dart';
import 'package:butterfliesar/models/butterfly.dart';
import 'package:butterfliesar/utils/ar_helpers.dart';

class ARExperienceScreen extends StatefulWidget {
  final Butterfly butterfly;
  const ARExperienceScreen({required this.butterfly, super.key});

  @override
  State<ARExperienceScreen> createState() => _ARExperienceScreenState();
}

class _ARExperienceScreenState extends State<ARExperienceScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  // Audio y animaciones
  AudioPlayer? _audioPlayer;
  late AnimationController _slideController;
  late Animation<Offset> _slide;

  // Controllers AR por plataforma
  ARKitController? _arkitController;
  ArCoreController? _arcoreController;

  // Estados de la aplicación
  ARPlatformSupport _arSupport = ARPlatformSupport.none;
  bool _hasCameraPermission = false;
  bool _isARMode = true;
  bool _isDayBackground = true;
  bool _isModelSelected = false;
  bool _showingInfo = false;
  bool _isModelLoaded = false;
  bool _isLoadingModel = true;

  // Variables para animaciones y control del modelo
  Timer? _rotationTimer;
  Timer? _floatingTimer;
  double _modelRotation = 0.0;
  double _floatingOffset = 0.0;

  // Referencias a nodos AR
  String? _currentARNodeName;

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
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    ARLogger.log('Inicializando aplicación AR...');

    await _detectARSupport();
    await _checkCameraPermission();
    _playAmbientSound();

    // Si tiene soporte AR y permisos, preparar para cargar modelo
    if (_arSupport != ARPlatformSupport.none && _hasCameraPermission) {
      ARLogger.success('Dispositivo listo para AR');
    } else {
      ARLogger.log('Usando modo vista previa 3D');
      setState(() => _isARMode = false);
    }
  }

  Future<void> _detectARSupport() async {
    try {
      final support = await SimpleARSupport.detectARSupport();
      setState(() => _arSupport = support);
      ARLogger.log(
        'Soporte AR detectado: ${await SimpleARSupport.getARSupportInfo()}',
      );
    } catch (e) {
      ARLogger.error('Error detectando soporte AR', e);
      setState(() => _arSupport = ARPlatformSupport.none);
    }
  }

  Future<void> _checkCameraPermission() async {
    final status = await Permission.camera.status;
    setState(() => _hasCameraPermission = status.isGranted);
    ARLogger.log(
      'Permisos de cámara: ${status.isGranted ? 'concedidos' : 'denegados'}',
    );
  }

  Future<void> _playAmbientSound() async {
    try {
      final soundPath = selectedButterfly.ambientSound;
      if (soundPath?.isNotEmpty ?? false) {
        _audioPlayer ??= AudioPlayer();
        await _audioPlayer?.setReleaseMode(ReleaseMode.loop);
        await _audioPlayer?.setVolume(0.3);

        final assetPath = soundPath!.startsWith('assets/')
            ? soundPath.substring(7)
            : soundPath;

        await _audioPlayer?.play(AssetSource(assetPath));
        ARLogger.log('Sonido ambiental iniciado');
      }
    } catch (e) {
      ARLogger.error('Error reproduciendo sonido ambiental', e);
    }
  }

  // ==================== AR MODEL LOADING ====================

  Future<void> _loadARModel() async {
    if (!mounted || _isModelLoaded) return;

    final modelPath = selectedButterfly.modelAsset;
    if (modelPath == null) {
      ARLogger.error('No hay modelo 3D disponible para esta mariposa');
      return;
    }

    ARLogger.log('Iniciando carga del modelo: $modelPath');

    try {
      switch (_arSupport) {
        case ARPlatformSupport.arkit:
          await _loadARKitModel(modelPath);
          break;
        case ARPlatformSupport.arcore:
          await _loadARCoreModel(modelPath);
          break;
        case ARPlatformSupport.webAR:
        case ARPlatformSupport.none:
          ARLogger.log('Cargando modelo en modo preview 3D');
          break;
      }

      setState(() => _isModelLoaded = true);
      _startAutoAnimations();
      ARLogger.success('Modelo cargado exitosamente');
    } catch (e) {
      ARLogger.error('Error cargando modelo AR', e);
      _showErrorSnackbar();
    }
  }

  Future<void> _loadARKitModel(String modelPath) async {
    if (_arkitController == null) return;

    try {
      final config = ARModelConfig.butterfly;
      final nodeName = 'butterfly_${DateTime.now().millisecondsSinceEpoch}';

      // Crear nodo usando la API básica de ARKit
      final node = ARKitReferenceNode(
        url: modelPath,
        scale: vector.Vector3.all(config.scale),
        position: vector.Vector3(
          config.position[0].toDouble(),
          config.position[1].toDouble(),
          config.position[2].toDouble(),
        ),
      );

      _arkitController?.add(node);
      _currentARNodeName = nodeName;
      ARLogger.success('Modelo ARKit cargado: $nodeName');
    } catch (e) {
      ARLogger.error('Error cargando modelo ARKit', e);
    }
  }

  Future<void> _loadARCoreModel(String modelPath) async {
    if (_arcoreController == null) return;

    try {
      final config = ARModelConfig.butterfly;
      final nodeName = 'butterfly_${DateTime.now().millisecondsSinceEpoch}';

      final node = ArCoreReferenceNode(
        name: nodeName,
        objectUrl: modelPath,
        scale: vector.Vector3.all(config.scale),
        position: vector.Vector3(
          config.position[0].toDouble(),
          config.position[1].toDouble(),
          config.position[2].toDouble(),
        ),
      );

      await _arcoreController?.addArCoreNode(node);
      _currentARNodeName = nodeName;
      ARLogger.success('Modelo ARCore cargado: $nodeName');
    } catch (e) {
      ARLogger.error('Error cargando modelo ARCore', e);
    }
  }

  // ==================== ANIMATIONS ====================

  void _startAutoAnimations() {
    _stopAutoAnimations();

    _rotationTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (mounted && !_isModelSelected) {
        setState(() {
          _modelRotation += 0.02;
          if (_modelRotation > 2 * math.pi) _modelRotation = 0;
        });
        _updateModelRotation();
      }
    });

    _floatingTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (mounted && !_isModelSelected) {
        setState(() => _floatingOffset += 0.05);
        _updateModelFloating();
      }
    });
  }

  void _stopAutoAnimations() {
    _rotationTimer?.cancel();
    _floatingTimer?.cancel();
  }

  void _updateModelRotation() {
    // Solo actualizar si tenemos un nodo AR cargado
    if (_currentARNodeName == null) return;

    try {
      switch (_arSupport) {
        case ARPlatformSupport.arkit:
          // ARKit maneja rotación de forma diferente
          break;
        case ARPlatformSupport.arcore:
          // ARCore permite actualizar rotación
          break;
        default:
          break;
      }
    } catch (e) {
      ARLogger.error('Error actualizando rotación del modelo', e);
    }
  }

  void _updateModelFloating() {
    // Implementar animación de flotación según la plataforma
    if (_currentARNodeName == null) return;

    final floatingY = math.sin(_floatingOffset) * 0.05;
    // Actualizar posición Y del modelo según plataforma
  }

  // ==================== USER INTERACTIONS ====================

  void _handleTap() {
    setState(() => _isModelSelected = !_isModelSelected);
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
          'Mariposa seleccionada - Usa gestos para interactuar',
          style: TextStyle(color: Colors.white),
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _captureScreen() async {
    try {
      HapticFeedback.lightImpact();

      // Aquí podrías implementar captura real según la plataforma
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(LucideIcons.camera, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Captura ${_arSupport != ARPlatformSupport.none ? 'AR' : '3D'} simulada',
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ARLogger.error('Error capturando pantalla', e);
    }
  }

  void _showErrorSnackbar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Error cargando modelo 3D'),
        backgroundColor: Colors.red,
        action: SnackBarAction(label: 'Reintentar', onPressed: _loadARModel),
      ),
    );
  }

  // ==================== AR VIEW BUILDERS ====================

  Widget _buildARView() {
    if (!_hasCameraPermission) {
      return _buildNoPermissionView();
    }

    switch (_arSupport) {
      case ARPlatformSupport.arkit:
        return _buildARKitView();
      case ARPlatformSupport.arcore:
        return _buildARCoreView();
      case ARPlatformSupport.webAR:
      case ARPlatformSupport.none:
        return _buildStaticView();
    }
  }

  Widget _buildARKitView() {
    return ARKitSceneView(
      onARKitViewCreated: (controller) {
        _arkitController = controller;
        ARLogger.success('Vista ARKit creada');
        _loadARModel();
      },
      showFeaturePoints: true,
      showWorldOrigin: false,
      enableTapRecognizer: true,
    );
  }

  Widget _buildARCoreView() {
    return ArCoreView(
      onArCoreViewCreated: (controller) {
        _arcoreController = controller;
        ARLogger.success('Vista ARCore creada');
        _loadARModel();
      },
      enableTapRecognizer: true,
      enablePlaneRenderer: true,
      enableUpdateListener: true,
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
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Mostrar modelo 3D si está disponible
                if (selectedButterfly.modelAsset != null)
                  Container(
                    height: 300,
                    width: 300,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Stack(
                      children: [
                        // ModelViewer para la web
                        if (kIsWeb)
                          ModelViewer(
                            backgroundColor: Colors.transparent,
                            src: selectedButterfly.modelAsset!,
                            alt: "Modelo 3D de ${selectedButterfly.name}",
                            ar: false,
                            autoRotate: true,
                            cameraControls: true,
                            autoPlay: true,
                          )
                        // ModelViewer para dispositivos móviles
                        else
                          ModelViewer(
                            backgroundColor: Colors.transparent,
                            src: selectedButterfly.modelAsset!,
                            alt: "Modelo 3D de ${selectedButterfly.name}",
                            ar: false,
                            autoRotate: true,
                            cameraControls: true,
                            autoPlay: true,
                            cameraOrbit: "0deg 75deg 2m",
                            shadowIntensity: 1,
                            shadowSoftness: 1,
                            loading: Loading.eager,
                            disableZoom: false,
                            disablePan: false,
                            autoRotateDelay: 0,
                            arModes: const [],
                          ),
                        // Indicador de carga
                        if (_isLoadingModel)
                          const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _arSupport == ARPlatformSupport.none
                              ? Icons.phone_android
                              : LucideIcons.box,
                          size: 64,
                          color: Colors.white,
                        ),
                        SizedBox(height: 16),
                        Text(
                          _arSupport == ARPlatformSupport.none
                              ? 'Vista previa 3D no disponible'
                              : 'Modelo 3D no disponible',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          _arSupport != ARPlatformSupport.none
                              ? 'El modelo 3D no está disponible para esta mariposa.'
                              : 'Este dispositivo no soporta realidad aumentada.',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          _buildStaticViewControls(),
        ],
      ),
    );
  }

  Widget _buildStaticViewControls() {
    return Positioned(
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
          SizedBox(height: 16),
          _buildFloatingButton(
            icon: _isDayBackground ? LucideIcons.sun : LucideIcons.moon,
            onPressed: () {
              setState(() => _isDayBackground = !_isDayBackground);
              HapticFeedback.lightImpact();
            },
            tooltip: _isDayBackground ? 'Modo noche' : 'Modo día',
          ),
        ],
      ),
    );
  }

  Widget _buildNoPermissionView() {
    return Center(
      child: Container(
        margin: EdgeInsets.all(24),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.camera, size: 48, color: Colors.white),
            SizedBox(height: 20),
            Text(
              'Permiso de cámara requerido',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              'Se necesita acceso a la cámara para la experiencia AR.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final status = await Permission.camera.request();
                if (status.isGranted) {
                  setState(() => _hasCameraPermission = true);
                  _loadARModel();
                } else if (status.isPermanentlyDenied) {
                  await openAppSettings();
                }
              },
              child: Text('Conceder permiso'),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== UI COMPONENTS ====================

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
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.black87, size: 22),
        ),
      ),
    );
  }

  void _showInfo() {
    setState(() => _showingInfo = true);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildInfoSheet(),
    ).then((_) => setState(() => _showingInfo = false));
  }

  Widget _buildInfoSheet() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1E2936) : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con imagen y nombres
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: AssetImage(selectedButterfly.imageAsset),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedButterfly.name,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              selectedButterfly.scientificName,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),

                  // Descripción
                  Text(
                    'Descripción',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    selectedButterfly.description,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                  ),
                  SizedBox(height: 24),

                  // Info técnica AR
                  FutureBuilder<String>(
                    future: SimpleARSupport.getARSupportInfo(),
                    builder: (context, snapshot) {
                      return Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.primary.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _arSupport != ARPlatformSupport.none
                                      ? LucideIcons.smartphone
                                      : LucideIcons.box,
                                  color: theme.colorScheme.primary,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Estado AR',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              snapshot.data ?? 'Verificando...',
                              style: theme.textTheme.bodyMedium,
                            ),
                            if (_arSupport != ARPlatformSupport.none) ...[
                              SizedBox(height: 8),
                              Text(
                                'Toca la mariposa para seleccionarla y usar gestos',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== MAIN BUILD ====================

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Scaffold(
        extendBodyBehindAppBar: false,
        body: Stack(
          children: [
            // Main AR/3D Content
            SafeArea(
              child: _arSupport != ARPlatformSupport.none && _isARMode
                  ? _buildARView()
                  : _buildStaticView(),
            ),

            // Top Navigation Controls
            Positioned(
              top: 16,
              left: 8,
              child: IconButton(
                icon: Icon(
                  LucideIcons.chevronLeft,
                  color: Colors.white,
                  size: 22,
                ),
                onPressed: () => Navigator.pop(context),
                tooltip: 'Atrás',
              ),
            ),

            // AR Mode Toggle (only if AR is supported)
            if (_arSupport != ARPlatformSupport.none)
              Positioned(
                top: 16,
                right: 8,
                child: _buildFloatingButton(
                  icon: _isARMode ? LucideIcons.image : LucideIcons.box,
                  onPressed: () {
                    setState(() => _isARMode = !_isARMode);
                    HapticFeedback.selectionClick();
                    ARLogger.log(
                      'Cambiado a modo: ${_isARMode ? 'AR' : '3D Preview'}',
                    );
                  },
                  tooltip: _isARMode ? 'Vista previa' : 'Vista AR',
                ),
              ),

            // AR Controls (floating buttons)
            if (_arSupport != ARPlatformSupport.none && _isARMode)
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
                    SizedBox(height: 16),
                    _buildFloatingButton(
                      icon: LucideIcons.camera,
                      onPressed: _captureScreen,
                      tooltip: 'Capturar',
                    ),
                  ],
                ),
              ),

            // Loading Indicator for AR
            if (_arSupport != ARPlatformSupport.none &&
                _isARMode &&
                !_isModelLoaded)
              Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: Center(
                  child: SlideTransition(
                    position: _slide,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      margin: EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surface.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _arSupport == ARPlatformSupport.arkit
                                  ? LucideIcons.smartphone
                                  : LucideIcons.scan,
                              size: 24,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Busca una superficie plana',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Mueve tu dispositivo lentamente',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 12),
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Model Selection Indicator
            if (_isModelSelected &&
                _arSupport != ARPlatformSupport.none &&
                _isARMode)
              Positioned(
                top: 80,
                left: 16,
                right: 16,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.hand, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Mariposa seleccionada - Interactúa con gestos',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ==================== LIFECYCLE ====================

  @override
  void dispose() {
    ARLogger.log('Cerrando experiencia AR');

    _stopAutoAnimations();
    _audioPlayer?.stop();
    _audioPlayer?.dispose();
    _slideController.dispose();

    // Cleanup AR controllers
    _arkitController?.dispose();
    _arcoreController?.dispose();

    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        ARLogger.log('App resumed - rechecking permissions');
        _checkCameraPermission();
        break;
      case AppLifecycleState.paused:
        ARLogger.log('App paused - stopping animations');
        _stopAutoAnimations();
        _audioPlayer?.pause();
        break;
      case AppLifecycleState.detached:
        ARLogger.log('App detached - cleanup');
        _audioPlayer?.stop();
        break;
      default:
        break;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reiniciar audio si es necesario cuando cambian las dependencias
    if (_audioPlayer?.state != PlayerState.playing) {
      _playAmbientSound();
    }
  }
}
