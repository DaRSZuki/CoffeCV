import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/api_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.instance.load();
  runApp(const CvCafeApp());
}

class CvCafeApp extends StatelessWidget {
  const CvCafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2E7D32),
      secondary: const Color(0xFF6D4C41),
    );
    return MaterialApp(
      title: 'CV Café',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: scheme,
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          centerTitle: false,
        ),
        cardTheme: const CardThemeData(clipBehavior: Clip.antiAlias),
      ),
      home: const HomeScreen(),
    );
  }
}
