import 'package:flutter/material.dart';

import 'guide_screen.dart';
import 'scan_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('CV Café'),
        actions: [
          IconButton(
            tooltip: 'Ajustes del servidor',
            icon: const Icon(Icons.settings),
            onPressed: () =>
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Salud de tu cafetal',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Aprende sobre las enfermedades o fotografía una hoja para diagnosticarla.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _SectionCard(
                  icon: Icons.menu_book_rounded,
                  title: 'Guía de enfermedades',
                  subtitle: 'Síntomas, tratamientos, frecuencia y prevención de cada enfermedad.',
                  color: theme.colorScheme.secondary,
                  onTap: () =>
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const GuideScreen())),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _SectionCard(
                  icon: Icons.center_focus_strong_rounded,
                  title: 'Identificar enfermedad',
                  subtitle: 'Usa la cámara para analizar una hoja en tiempo real con IA.',
                  color: theme.colorScheme.primary,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanScreen())),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        child: LayoutBuilder(
          builder: (context, box) => Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: box.maxHeight < 220 ? 40 : 72, color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
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
