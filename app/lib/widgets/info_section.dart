import 'package:flutter/material.dart';

import '../models/disease.dart';

/// Tarjeta con título e ícono y una lista de viñetas.
class BulletSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> items;
  final Color? color;

  const BulletSection({super.key, required this.title, required this.icon, required this.items, this.color});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: c),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold, color: c),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 7, right: 8),
                      child: Icon(Icons.circle, size: 6, color: c),
                    ),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Guía de tratamiento dividida en control cultural, biológico y químico.
class TreatmentGuide extends StatelessWidget {
  final Treatment treatment;
  const TreatmentGuide({super.key, required this.treatment});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BulletSection(
          title: 'Control cultural',
          icon: Icons.agriculture,
          items: treatment.cultural,
          color: Colors.green.shade800,
        ),
        BulletSection(
          title: 'Control biológico',
          icon: Icons.eco,
          items: treatment.biologico,
          color: Colors.teal.shade700,
        ),
        BulletSection(
          title: 'Control químico',
          icon: Icons.science,
          items: treatment.quimico,
          color: Colors.deepOrange.shade700,
        ),
        Text(
          'Las recomendaciones son orientativas. Consulte a un agrónomo o al servicio de '
          'extensión de su zona y siga siempre la etiqueta de los productos.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
        ),
      ],
    );
  }
}
