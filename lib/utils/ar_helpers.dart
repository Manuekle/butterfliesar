// Utilidades y helpers para lógica AR

import 'dart:io';
import 'package:flutter/foundation.dart';

/// Retorna true si el dispositivo probablemente soporta AR (ARCore/ARKit)
Future<bool> isARSupported() async {
  // Puedes mejorar este chequeo usando ar_flutter_plugin.isARSupported() si el plugin lo soporta
  if (kIsWeb) return false;
  if (Platform.isAndroid || Platform.isIOS) {
    // Aquí podrías agregar lógica más avanzada (checar versión, modelo, etc)
    return true;
  }
  return false;
}
