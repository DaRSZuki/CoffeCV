import 'package:flutter/material.dart';

import '../models/disease.dart';
import '../widgets/frequency_meter.dart';
import '../widgets/info_section.dart';

class DiseaseDetailScreen extends StatelessWidget {
  final Disease disease;
  const DiseaseDetailScreen({super.key, required this.disease});

  @override
  Widget build(BuildContext context) {
    final d = disease;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(d.nombre),
          backgroundColor: d.color,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Información'),
              Tab(text: 'Tratamiento'),
              Tab(text: 'Prevención'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ListView(
              padding: const EdgeInsets.all(12),
              children: [
                DiseaseHeader(disease: d),
                BulletSection(title: 'Síntomas', icon: Icons.visibility, items: d.sintomas, color: d.color),
                BulletSection(
                  title: 'Condiciones que la favorecen',
                  icon: Icons.thermostat,
                  items: d.condiciones,
                  color: d.color,
                ),
                BulletSection(
                  title: 'Datos curiosos',
                  icon: Icons.lightbulb,
                  items: d.datosCuriosos,
                  color: d.color,
                ),
              ],
            ),
            ListView(
              padding: const EdgeInsets.all(12),
              children: [TreatmentGuide(treatment: d.tratamiento)],
            ),
            ListView(
              padding: const EdgeInsets.all(12),
              children: [
                BulletSection(
                  title: 'Medidas de prevención',
                  icon: Icons.shield,
                  items: d.prevencion,
                  color: d.color,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Resumen con nombre científico, tipo, frecuencia, severidad e impacto.
class DiseaseHeader extends StatelessWidget {
  final Disease disease;
  const DiseaseHeader({super.key, required this.disease});

  @override
  Widget build(BuildContext context) {
    final d = disease;
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              d.nombreCientifico,
              style: theme.textTheme.titleMedium?.copyWith(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(avatar: const Icon(Icons.category, size: 18), label: Text(d.tipo)),
                Chip(
                  avatar: const Icon(Icons.warning_amber, size: 18),
                  label: Text('Severidad: ${d.severidad}'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Qué tan común es', style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            FrequencyMeter(level: d.frecuenciaNivel, label: d.frecuencia),
            const SizedBox(height: 12),
            Text(d.descripcion),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.trending_down, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(child: Text('Impacto: ${d.impacto}')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
