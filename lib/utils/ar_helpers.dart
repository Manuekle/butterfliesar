// Utilidades y helpers para lógica AR

import 'dart:io';
import 'package:flutter/foundation.dart';

/// Verifica si el dispositivo puede ejecutar AR basado en la plataforma
///
/// Devuelve true si el dispositivo es compatible con AR (Android o iOS),
/// false en caso contrario.
///
/// Nota: Esta es una verificación básica de plataforma. Para una verificación
/// más precisa, se debería implementar la inicialización del plugin AR
/// en la pantalla principal y manejar los errores de forma adecuada.
Future<bool> isARSupported() async {
  // No hay soporte para web
  if (kIsWeb) return false;

  // Verificar plataforma
  if (!Platform.isAndroid && !Platform.isIOS) {
    return false; // Solo soportamos Android e iOS
  }

  // Para una implementación más robusta, podrías querer:
  // 1. Inicializar el plugin AR en el inicio de la app
  // 2. Almacenar el estado de compatibilidad
  // 3. Usar ese estado aquí

  // Por ahora, asumimos que si es Android o iOS, tiene soporte básico de AR
  return true;
}
