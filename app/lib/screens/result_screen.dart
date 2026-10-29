import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/disease.dart';
import '../models/prediction.dart';
import '../services/api_service.dart';
import '../services/disease_repository.dart';
import '../widgets/info_section.dart';
import 'disease_detail_screen.dart';

class ResultScreen extends StatefulWidget {
  final Uint8List imageBytes;
  const ResultScreen({super.key, required this.imageBytes});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late Future<(Prediction, Disease?)> _future;

  @override
  void initState() {
    super.initState();
    _future = _analyze();
  }

  Future<(Prediction, Disease?)> _analyze() async {
    final p = await ApiService.instance.predict(widget.imageBytes);
    final d = p.sana ? null : await DiseaseRepository.instance.byId(p.clase);
    return (p, d);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diagnóstico')),
      body: FutureBuilder<(Prediction, Disease?)>(
        future: _future,
        builder: (context, snap) {
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Image.memory(widget.imageBytes, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 12),
              if (snap.connectionState != ConnectionState.done)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Enviando muestra al servidor y analizando...'),
                    ],
                  ),
                )
              else if (snap.hasError)
                _ErrorCard(
                  message: snap.error.toString(),
                  onRetry: () => setState(() => _future = _analyze()),
                )
              else
                ..._buildResult(snap.data!.$1, snap.data!.$2),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildResult(Prediction p, Disease? d) {
    return [
      _ResultCard(prediction: p, disease: d),
      if (!p.concluyente)
        const BulletSection(
          title: 'Resultado poco seguro',
          icon: Icons.help_outline,
          color: Colors.blueGrey,
          items: [
            'Tome la foto más cerca, con una sola hoja ocupando el marco.',
            'Use luz natural difusa; evite sombras fuertes o contraluz.',
            'Asegúrese de que la imagen esté enfocada.',
            'Si la duda persiste, compare los síntomas con la guía de enfermedades.',
          ],
        ),
      _ProbabilityCard(prediction: p),
      if (p.sana)
        const BulletSection(
          title: 'Recomendaciones para mantenerla sana',
          icon: Icons.spa,
          items: [
            'Continúe con un plan de fertilización basado en análisis de suelo.',
            'Mantenga una sombra regulada (30-45 %) y buena ventilación con podas.',
            'Revise el cafetal cada 15-30 días, sobre todo en época de lluvias.',
            'Controle malezas y conserve coberturas que protejan el suelo.',
            'Recoja frutos caídos y sobremaduros para prevenir la broca.',
          ],
        ),
      if (d != null) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
          child: Text(
            'Guía de tratamiento',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        BulletSection(
          title: 'Síntomas a confirmar',
          icon: Icons.visibility,
          items: d.sintomas,
          color: d.color,
        ),
        TreatmentGuide(treatment: d.tratamiento),
        const SizedBox(height: 12),
        BulletSection(title: 'Prevención', icon: Icons.shield, items: d.prevencion, color: d.color),
        FilledButton.icon(
          onPressed: () =>
              Navigator.push(context, MaterialPageRoute(builder: (_) => DiseaseDetailScreen(disease: d))),
          icon: const Icon(Icons.menu_book),
          label: const Text('Ver ficha completa de la enfermedad'),
        ),
      ],
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.camera_alt),
        label: const Text('Analizar otra muestra'),
      ),
      const SizedBox(height: 24),
    ];
  }
}

class _ResultCard extends StatelessWidget {
  final Prediction prediction;
  final Disease? disease;
  const _ResultCard({required this.prediction, this.disease});

  @override
  Widget build(BuildContext context) {
    final p = prediction;
    final color = p.sana ? Colors.green.shade700 : (disease?.color ?? Colors.orange.shade800);
    return Card(
      color: color,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(p.sana ? Icons.check_circle : Icons.coronavirus, color: Colors.white, size: 48),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.sana ? 'La hoja parece sana' : 'Posible enfermedad detectada',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  Text(
                    p.nombre,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  if (disease != null)
                    Text(
                      disease!.nombreCientifico,
                      style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    'Confianza: ${(p.confianza * 100).toStringAsFixed(1)} %',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProbabilityCard extends StatelessWidget {
  final Prediction prediction;
  const _ProbabilityCard({required this.prediction});

  @override
  Widget build(BuildContext context) {
    final top = prediction.probabilidades.take(4);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Probabilidades', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final c in top) ...[
              Row(
                children: [
                  Expanded(child: Text(c.nombre)),
                  Text('${(c.probabilidad * 100).toStringAsFixed(1)} %'),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: c.probabilidad,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 10),
            ],
            Text(
              'Procesado en el servidor en ${prediction.tiempoMs.toStringAsFixed(0)} ms',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.cloud_off, size: 40),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
