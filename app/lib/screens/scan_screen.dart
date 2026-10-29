import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/prediction.dart';
import '../services/api_service.dart';
import 'result_screen.dart';

/// Cámara con dos modos:
///  * Tiempo real: envía un fotograma al servidor de forma continua y muestra el resultado encima.
///  * Captura: toma una foto y abre el diagnóstico completo con guía de tratamiento.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  String? _cameraError;
  bool _live = false;
  bool _busy = false; // hay una foto/petición en curso
  bool _flash = false;
  Prediction? _livePrediction;
  String? _liveError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    _live = false;
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      setState(() => _live = false);
      c.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      final cams = await availableCameras();
      if (cams.isEmpty) {
        setState(() => _cameraError = 'No se encontró ninguna cámara en este dispositivo.');
        return;
      }
      final back = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cams.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      await controller.setFlashMode(FlashMode.off);
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _cameraError = null;
      });
    } on CameraException catch (e) {
      setState(
        () => _cameraError = e.code == 'CameraAccessDenied'
            ? 'Permiso de cámara denegado. Actívelo en los ajustes del teléfono.'
            : 'No se pudo iniciar la cámara (${e.description ?? e.code}).',
      );
    }
  }

  Future<Uint8List?> _snap() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized || c.value.isTakingPicture) return null;
    final file = await c.takePicture();
    return file.readAsBytes();
  }

  void _toggleLive(bool value) {
    setState(() {
      _live = value;
      _livePrediction = null;
      _liveError = null;
    });
    if (value) _liveLoop();
  }

  Future<void> _liveLoop() async {
    while (mounted && _live) {
      if (!_busy) {
        _busy = true;
        try {
          final bytes = await _snap();
          if (bytes != null) {
            final p = await ApiService.instance.predict(bytes, timeout: const Duration(seconds: 8));
            if (mounted && _live) {
              setState(() {
                _livePrediction = p;
                _liveError = null;
              });
            }
          }
        } catch (e) {
          if (mounted && _live) setState(() => _liveError = e.toString());
        } finally {
          _busy = false;
        }
      }
      await Future.delayed(const Duration(milliseconds: 600));
    }
  }

  Future<void> _capture() async {
    if (_busy) return;
    setState(() => _live = false);
    _busy = true;
    try {
      final bytes = await _snap();
      if (bytes != null && mounted) _openResult(bytes);
    } on CameraException catch (e) {
      _showSnack('Error al tomar la foto: ${e.description ?? e.code}');
    } finally {
      _busy = false;
    }
  }

  Future<void> _pickFromGallery() async {
    setState(() => _live = false);
    final img = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600);
    if (img == null || !mounted) return;
    _openResult(await img.readAsBytes());
  }

  void _openResult(Uint8List bytes) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ResultScreen(imageBytes: bytes)));
  }

  Future<void> _toggleFlash() async {
    final c = _controller;
    if (c == null) return;
    _flash = !_flash;
    await c.setFlashMode(_flash ? FlashMode.torch : FlashMode.off);
    setState(() {});
  }

  void _showSnack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Identificar enfermedad'),
        actions: [
          if (_controller != null)
            IconButton(
              tooltip: 'Linterna',
              icon: Icon(_flash ? Icons.flash_on : Icons.flash_off),
              onPressed: _toggleFlash,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildPreview()),
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    if (_cameraError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.no_photography, color: Colors.white54, size: 64),
              const SizedBox(height: 12),
              Text(
                _cameraError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),
              const Text(
                'Puede analizar una foto desde la galería.',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }
    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        Center(child: CameraPreview(c)),
        // Marco guía para encuadrar la hoja
        IgnorePointer(
          child: Center(
            child: FractionallySizedBox(
              widthFactor: 0.78,
              child: AspectRatio(
                aspectRatio: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white70, width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 12,
          right: 12,
          top: 12,
          child: _live ? _LiveBanner(prediction: _livePrediction, error: _liveError) : const _Hint(),
        ),
      ],
    );
  }

  Widget _buildControls() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_controller != null)
              SwitchListTile(
                value: _live,
                onChanged: _toggleLive,
                title: const Text('Análisis en tiempo real', style: TextStyle(color: Colors.white)),
                subtitle: const Text(
                  'Analiza continuamente lo que ve la cámara',
                  style: TextStyle(color: Colors.white60),
                ),
                activeThumbColor: Colors.greenAccent,
                contentPadding: EdgeInsets.zero,
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton.filledTonal(
                  iconSize: 28,
                  tooltip: 'Galería',
                  onPressed: _pickFromGallery,
                  icon: const Icon(Icons.photo_library),
                ),
                GestureDetector(
                  onTap: _controller == null ? null : _capture,
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _controller == null ? Colors.white24 : Colors.white,
                      border: Border.all(color: Colors.greenAccent, width: 4),
                    ),
                    child: const Icon(Icons.eco, color: Colors.green, size: 34),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Toque el botón para capturar y ver el diagnóstico completo',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
      child: const Text(
        'Encuadre una sola hoja dentro del marco, con buena luz y enfocada.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}

class _LiveBanner extends StatelessWidget {
  final Prediction? prediction;
  final String? error;
  const _LiveBanner({this.prediction, this.error});

  @override
  Widget build(BuildContext context) {
    final p = prediction;
    Color bg;
    Widget child;
    if (error != null) {
      bg = Colors.red.shade700;
      child = Text(error!, style: const TextStyle(color: Colors.white), maxLines: 3);
    } else if (p == null) {
      bg = Colors.black54;
      child = const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          ),
          SizedBox(width: 10),
          Text('Analizando...', style: TextStyle(color: Colors.white)),
        ],
      );
    } else {
      bg = !p.concluyente
          ? Colors.grey.shade800
          : p.sana
          ? Colors.green.shade700
          : Colors.orange.shade800;
      child = Row(
        children: [
          Icon(p.sana ? Icons.check_circle : Icons.warning_rounded, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              p.concluyente ? p.nombre : 'No concluyente (¿${p.nombre}?)',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Text(
            '${(p.confianza * 100).toStringAsFixed(0)} %',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      );
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: child,
    );
  }
}
