import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/butterfly_provider.dart';
import '../widgets/butterfly_card.dart';

class SpeciesSelectionScreen extends StatefulWidget {
  const SpeciesSelectionScreen({super.key});

  @override
  State<SpeciesSelectionScreen> createState() => _SpeciesSelectionScreenState();
}

class _SpeciesSelectionScreenState extends State<SpeciesSelectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final butterflyProvider = Provider.of<ButterflyProvider>(context);

    if (butterflyProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (butterflyProvider.error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Error al cargar las especies: ${butterflyProvider.error}',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final butterflies = butterflyProvider.butterflies;

    if (butterflies.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('No hay especies')),
        body:
            const Center(child: Text('No se encontraron especies disponibles')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Selecciona una especie')),
      body: FadeTransition(
        opacity: _fade,
        child: ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: butterflies.length,
          separatorBuilder: (_, __) =>
              Divider(height: 32, color: Theme.of(context).dividerColor),
          itemBuilder: (context, i) {
            final butterfly = butterflies[i];
            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                await Future.delayed(const Duration(milliseconds: 80));
                Navigator.pushNamed(
                  context,
                  '/preparation',
                  arguments: butterfly,
                );
              },
              splashColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.08),
              highlightColor: Colors.transparent,
              child: ButterflyCard(
                name: butterfly.name,
                scientificName: butterfly.scientificName,
                imageAsset: butterfly.imageAsset,
              ),
            );
          },
        ),
      ),
    );
  }
}
