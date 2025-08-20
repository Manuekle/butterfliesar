import 'package:flutter/material.dart';
import 'ar_experience_screen.dart';
import 'butterfly_static_screen.dart';
import '../models/butterfly.dart';
import '../utils/ar_helpers.dart';
import 'package:vibration/vibration.dart';
import '../widgets/animated_toast.dart';

/// Widget que alterna suavemente entre AR y modo estático con fade+slide.
class AnimatedButterflyView extends StatefulWidget {
  final Butterfly butterfly;
  final bool initialAR;

  const AnimatedButterflyView({
    required this.butterfly,
    Key? key,
    this.initialAR = true,
  }) : super(key: key);

  @override
  State<AnimatedButterflyView> createState() => _AnimatedButterflyViewState();
}

class _AnimatedButterflyViewState extends State<AnimatedButterflyView> {
  bool _showAR = true;
  bool _arSupported = true;
  bool _checkedAR = false;
  String? _toast;

  @override
  void initState() {
    super.initState();
    _showAR = widget.initialAR;
    _checkARSupport();
  }

  Future<void> _checkARSupport() async {
    final supported = await isARSupported();
    setState(() {
      _arSupported = supported;
      _checkedAR = true;
      if (!supported) _showAR = false;
    });
  }

  Future<void> _toggleMode() async {
    setState(() => _showAR = !_showAR);
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(duration: 30, amplitude: 60);
    }
    setState(() {
      _toast = _showAR ? '¡Modo AR activado!' : 'Vista fondo activada';
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _toast = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_checkedAR) {
      return const Center(child: CircularProgressIndicator());
    }
    return Stack(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          transitionBuilder: (child, animation) {
            final offset = Tween<Offset>(
              begin: _showAR ? const Offset(0.08, 0) : const Offset(-0.08, 0),
              end: Offset.zero,
            ).animate(animation);
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(position: offset, child: child),
            );
          },
          child: _showAR
              ? ARExperienceScreen(
                  butterfly: widget.butterfly,
                  onSwitchToStatic: _arSupported ? _toggleMode : null,
                )
              : ButterflyStaticScreen(
                  butterfly: widget.butterfly,
                  canSwitchToAR: _arSupported,
                  onSwitchToAR: _arSupported ? _toggleMode : null,
                ),
        ),
        if (_toast != null) AnimatedToast(message: _toast!),
      ],
    );
  }
}
