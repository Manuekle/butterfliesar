import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/butterfly.dart';
import '../providers/butterfly_provider.dart';

class PreparationScreen extends StatefulWidget {
  const PreparationScreen({Key? key}) : super(key: key);

  @override
  State<PreparationScreen> createState() => _PreparationScreenState();
}

class _PreparationScreenState extends State<PreparationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  late final Butterfly selectedButterfly;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final butterflyProvider = Provider.of<ButterflyProvider>(context);
    final args = ModalRoute.of(context)?.settings.arguments;
    
    if (args is Butterfly) {
      selectedButterfly = args;
    } else if (butterflyProvider.butterflies.isNotEmpty) {
      selectedButterfly = butterflyProvider.butterflies.first;
    } else {
      // Fallback to a default butterfly if none are available
      final defaultButterfly = Butterfly(
        id: 'default',
        name: 'Mariposa',
        scientificName: 'Lepidoptera',
        description: 'Una hermosa mariposa',
        imageAsset: 'assets/images/placeholder.png',
        modelAsset: 'assets/models/placeholder.glb',
      );
      
      // If we have butterflies, use the first one, otherwise use the default
      selectedButterfly = butterflyProvider.butterflies.isNotEmpty 
          ? butterflyProvider.butterflies.first 
          : defaultButterfly;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preparando AR'), centerTitle: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),
                  CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Detectando superficie...\nColoca el dispositivo sobre una mesa o piso bien iluminado.',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  AnimatedScale(
                    scale: _fade.value,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutBack,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: () => Navigator.pushReplacementNamed(
                        context,
                        '/ar',
                        arguments: selectedButterfly,
                      ),
                      label: const Text('Continuar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
