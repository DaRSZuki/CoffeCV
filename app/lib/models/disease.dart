import 'package:flutter/material.dart';

class Treatment {
  final List<String> cultural;
  final List<String> biologico;
  final List<String> quimico;

  const Treatment({required this.cultural, required this.biologico, required this.quimico});

  factory Treatment.fromJson(Map<String, dynamic> j) => Treatment(
    cultural: List<String>.from(j['cultural'] ?? const []),
    biologico: List<String>.from(j['biologico'] ?? const []),
    quimico: List<String>.from(j['quimico'] ?? const []),
  );
}

class Disease {
  final String id;
  final String nombre;
  final String nombreCientifico;
  final String tipo;
  final String frecuencia;
  final int frecuenciaNivel;
  final String severidad;
  final Color color;
  final String resumen;
  final String descripcion;
  final List<String> sintomas;
  final List<String> condiciones;
  final String impacto;
  final Treatment tratamiento;
  final List<String> prevencion;
  final List<String> datosCuriosos;

  const Disease({
    required this.id,
    required this.nombre,
    required this.nombreCientifico,
    required this.tipo,
    required this.frecuencia,
    required this.frecuenciaNivel,
    required this.severidad,
    required this.color,
    required this.resumen,
    required this.descripcion,
    required this.sintomas,
    required this.condiciones,
    required this.impacto,
    required this.tratamiento,
    required this.prevencion,
    required this.datosCuriosos,
  });

  factory Disease.fromJson(Map<String, dynamic> j) => Disease(
    id: j['id'],
    nombre: j['nombre'],
    nombreCientifico: j['nombre_cientifico'],
    tipo: j['tipo'],
    frecuencia: j['frecuencia'],
    frecuenciaNivel: j['frecuencia_nivel'],
    severidad: j['severidad'],
    color: _parseColor(j['color']),
    resumen: j['resumen'],
    descripcion: j['descripcion'],
    sintomas: List<String>.from(j['sintomas']),
    condiciones: List<String>.from(j['condiciones_favorables']),
    impacto: j['impacto'],
    tratamiento: Treatment.fromJson(j['tratamiento']),
    prevencion: List<String>.from(j['prevencion']),
    datosCuriosos: List<String>.from(j['datos_curiosos'] ?? const []),
  );

  static Color _parseColor(String hex) => Color(int.parse(hex.replaceFirst('#', 'FF'), radix: 16));
}
