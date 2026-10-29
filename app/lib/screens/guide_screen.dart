import 'package:flutter/material.dart';

import '../models/disease.dart';
import '../services/disease_repository.dart';
import '../widgets/frequency_meter.dart';
import 'disease_detail_screen.dart';

class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Guía de enfermedades')),
      body: FutureBuilder<List<Disease>>(
        future: DiseaseRepository.instance.all(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final items = snap.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _DiseaseTile(disease: items[i]),
          );
        },
      ),
    );
  }
}

class _DiseaseTile extends StatelessWidget {
  final Disease disease;
  const _DiseaseTile({required this.disease});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => DiseaseDetailScreen(disease: disease))),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: disease.color,
                child: Icon(
                  disease.tipo.contains('plaga') ? Icons.bug_report : Icons.coronavirus,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      disease.nombre,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      disease.nombreCientifico,
                      style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 6),
                    Text(disease.resumen, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    FrequencyMeter(level: disease.frecuenciaNivel, label: disease.frecuencia),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
