import 'package:flutter/material.dart';

import '../services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _ctrl = TextEditingController(text: ApiService.instance.baseUrl);
  bool? _ok;
  bool _testing = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _test() async {
    setState(() {
      _testing = true;
      _ok = null;
    });
    final ok = await ApiService.instance.ping(url: _ctrl.text.trim().replaceAll(RegExp(r'/+$'), ''));
    if (mounted) {
      setState(() {
        _testing = false;
        _ok = ok;
      });
    }
  }

  Future<void> _save() async {
    await ApiService.instance.setBaseUrl(_ctrl.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dirección guardada')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Servidor de análisis')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _ctrl,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Dirección del servidor',
              hintText: 'http://192.168.1.50:8000',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _testing ? null : _test,
                icon: _testing
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.wifi_tethering),
                label: const Text('Probar conexión'),
              ),
              const SizedBox(width: 12),
              if (_ok != null)
                Icon(_ok! ? Icons.check_circle : Icons.error, color: _ok! ? Colors.green : Colors.red),
              if (_ok != null) Text(_ok! ? ' Conectado' : ' Sin conexión'),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: _save, child: const Text('Guardar')),
          const SizedBox(height: 24),
          const Text(
            'Cómo conectarse:\n'
            '• Emulador de Android: http://10.0.2.2:8000\n'
            '• Teléfono real: conecte el teléfono a la misma red Wi-Fi que la PC y use la IP '
            'local de la PC (ejecute "ipconfig" en Windows), por ejemplo http://192.168.1.50:8000\n'
            '• Cuando el servidor esté en la nube, escriba aquí su dirección pública.',
          ),
        ],
      ),
    );
  }
}
