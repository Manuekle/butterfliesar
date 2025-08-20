import 'package:flutter/foundation.dart';
import '../models/butterfly.dart';
import '../models/butterfly_loader.dart';

class ButterflyProvider with ChangeNotifier {
  List<Butterfly> _butterflies = [];
  bool _isLoading = false;
  String? _error;

  List<Butterfly> get butterflies => _butterflies;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Notify listeners when data changes
  void _notify() => notifyListeners();

  Future<void> loadButterflies() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    _notify();

    try {
      _butterflies = await loadButterfliesFromAssets();
    } catch (e) {
      _error = 'Failed to load butterflies: $e';
      if (kDebugMode) {
        print(_error);
      }
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  Butterfly? getButterflyById(String id) {
    try {
      return _butterflies.firstWhere((b) => b.id == id);
    } catch (e) {
      return null;
    }
  }
}
