import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'butterfly.dart';

/// Carga todas las mariposas desde el directorio de assets
Future<List<Butterfly>> loadButterfliesFromAssets() async {
  try {
    // Cargar el manifiesto de assets
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);

    // Filtrar los archivos metadata.json
    final metadataFiles = manifestMap.keys
        .where(
            (key) => key.contains('species/') && key.endsWith('metadata.json'))
        .toList();

    final butterflies = <Butterfly>[];

    for (final metadataPath in metadataFiles) {
      try {
        final jsonStr = await rootBundle.loadString(metadataPath);
        final data = json.decode(jsonStr);

        // Obtener el directorio base del metadata.json
        final dirPath = path.dirname(metadataPath);

        butterflies.add(Butterfly(
          id: path.basename(dirPath),
          name: data['name']?.toString() ?? 'Unknown',
          scientificName: data['scientificName']?.toString() ?? '',
          imageAsset: data['imageAsset']?.toString() ?? '',
          modelAsset: data['modelAsset']?.toString(),
          ambientSound: data['ambientSound']?.toString(),
        ));
      } catch (e) {
        print('Error loading butterfly from $metadataPath: $e');
      }
    }

    return butterflies;
  } catch (e) {
    print('Error loading butterflies: $e');
    rethrow;
  }
}

/// Función de compatibilidad para código existente
@Deprecated('Use loadButterfliesFromAssets instead')
Future<List<Butterfly>> loadButterflies() async {
  return loadButterfliesFromAssets();
}
