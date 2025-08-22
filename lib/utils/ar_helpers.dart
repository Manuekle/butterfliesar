// Utilidades y helpers para lógica AR

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';

/// Retorna true si el dispositivo soporta AR (ARCore/ARKit)
Future<bool> isARSupported() async {
  if (kIsWeb) return false;
  
  try {
    // Usar el método del plugin para verificar soporte de AR
    final arPlugin = ARFlutterPlugin();
    final isSupported = await arPlugin.checkIfARSupported();
    return isSupported;
  } catch (e) {
    // Si hay un error, usar un chequeo básico
    if (Platform.isAndroid || Platform.isIOS) {
      return true; // Asumir soporte básico para Android/iOS
    }
    return false;
  }
}
